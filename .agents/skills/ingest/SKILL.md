---
name: ingest
description: Ingest a source artifact (PDF, image, web page, or URL) into the wiki. Use when the user says "ingest this", "process foo.pdf", drops a file in wiki/raw/, points you at a path elsewhere on disk, attaches a file in chat, pastes a URL with implied "look at this", or directly invokes this skill. Lands the artifact under wiki/raw/ and writes a faithful markdown rendering to wiki/ai-workspace/sources/. Do NOT use this skill for casual mentions of a URL or file in conversation — only when ingest intent is explicit.
allowed-tools: Bash(defuddle:*), Bash(npx defuddle:*), Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(markitdown:*), Bash(mv:*), Bash(mkdir:*)
---

# Ingest

Bring a source artifact into the wiki as a citable, indexed page.

## When to fire

- User drops a file inside `wiki/raw/` and asks you to process it.
- User points at a path elsewhere on disk ("look at ~/Downloads/foo.pdf").
- User attaches a file directly in chat.
- User pastes a URL with implied "ingest this" / "save this for later" intent.

If a URL is mentioned only in passing (no clear "save it" intent), use the `log` skill instead — don't ingest.

## Workflow

For file artifacts (PDFs, Office docs, images, audio), first move the file into `wiki/raw/<YYYY-MM-DD>/` (creating the date dir if missing), then extract. `wiki/raw/` and `wiki/ai-workspace/sources/` are sharded by date.

1. **Extract** the content:
   - PDFs → `markitdown <path>`
   - Images → vision for description; `markitdown <path>` for embedded EXIF/OCR metadata
   - Office docs (docx, pptx, xlsx) → `markitdown <path>`
   - Audio (mp3, m4a, wav) → first convert to 16 kHz mono WAV in `/tmp` (whisper-cli only reads WAV): `ffmpeg -i <path> -ar 16000 -ac 1 -c:a pcm_s16le /tmp/<slug>.wav`, then `whisper-cli -m .models/ggml-large-v3-turbo.bin -f /tmp/<slug>.wav -otxt -of <out-stem>` (writes `<out-stem>.txt`). If `.models/ggml-large-v3-turbo.bin` is missing, download as per the README.
   - Web pages → `defuddle parse <url> --md` (or `agent-browser` for dynamic / auth-walled pages). The URL is the citation; nothing lands in `wiki/raw/`.
2. **Write** `wiki/ai-workspace/sources/<YYYY-MM-DD>/<slug>.md`:
   ```yaml
   ---
   title: "..."
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [...]
   source: ../../../raw/<YYYY-MM-DD>/<...>   # file artifacts: relative path into wiki/raw/
   # source: https://example.com/article     # web pages: the URL itself
   ---
   ```
   Body: a faithful markdown rendering plus your caption / notes.

## Collisions

If `wiki/ai-workspace/sources/<YYYY-MM-DD>/<slug>.md` already exists, stop and ask — don't clobber unless the user says "force" or "overwrite".

## Format coverage

`markitdown` is on PATH inside the dev shell (provisioned by `flake.nix`), so docx, pptx, xlsx, and audio are all supported alongside PDFs, images, and web pages. If `markitdown` errors out on a specific file, capture the error in the wiki page's frontmatter `notes:` and tell the user — do not silently land an empty page.

## Promotion is separate

Do **not** auto-promote sources on second mention. Ingest is an explicit verb. Clustering and promotion happen during lint, not during ingest.
