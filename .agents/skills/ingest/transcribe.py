#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "mlx-whisper",
#   "silero-vad",
#   "av",
#   "numpy",
# ]
# ///
# Transcribe audio/video to <out>.md (plain prose markdown).
# Override INITIAL_PROMPT for non-AWS-jargon.
import os
import sys

import av
import mlx_whisper
import numpy as np
from silero_vad import get_speech_timestamps, load_silero_vad

SAMPLE_RATE = 16000


def collapse_loops(segments):
    out = []
    for s in segments:
        text = s["text"].strip()
        if not text:
            continue
        text = re.sub(r"(\b\w+\b[ ,.]*)(\1){3,}", r"\1", text)
        if out and text == out[-1]:
            continue
        out.append(text)
    return out


def load_audio(path: str) -> np.ndarray:
    container = av.open(path)
    stream = container.streams.audio[0]
    resampler = av.AudioResampler(format="flt", layout="mono", rate=SAMPLE_RATE)
    chunks = []
    for frame in container.decode(stream):
        for r in resampler.resample(frame):
            chunks.append(r.to_ndarray().flatten())
    for r in resampler.resample(None):
        chunks.append(r.to_ndarray().flatten())
    container.close()
    return np.concatenate(chunks)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: transcribe.py <input> [out-stem]")
    src = sys.argv[1]
    out_stem = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(src)[0]
    model = os.environ.get("WHISPER_MODEL", "mlx-community/whisper-large-v3-mlx")
    prompt = os.environ.get(
        "INITIAL_PROMPT",
        "AWS, Amazon, SageMaker, Bedrock, S3, EC2, EBS, Lambda, IAM, "
        "Git, Git repo, GitHub, lineage, dataset.",
    )
    out_path = f"{out_stem}.md"

    audio = load_audio(src)
    print(f"loaded {len(audio) / SAMPLE_RATE:.1f}s of audio", file=sys.stderr)

    speech = get_speech_timestamps(
        audio,
        load_silero_vad(),
        sampling_rate=SAMPLE_RATE,
        min_silence_duration_ms=500,
        speech_pad_ms=200,
    )
    if not speech:
        open(out_path, "w").close()
        print("no speech detected", file=sys.stderr)
        return

    speech_audio = np.concatenate([audio[sp["start"] : sp["end"]] for sp in speech])
    print(
        f"VAD: {len(speech)} speech regions, kept {len(speech_audio) / SAMPLE_RATE:.1f}s "
        f"of {len(audio) / SAMPLE_RATE:.1f}s",
        file=sys.stderr,
    )

    r = mlx_whisper.transcribe(
        speech_audio,
        path_or_hf_repo=model,
        language="en",
        no_speech_threshold=0.6,
        initial_prompt=prompt,
    )

    lines = collapse_loops(r["segments"])
    with open(out_path, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(
        f"wrote {len(lines)} lines (from {len(r['segments'])} segments) to {out_path}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
