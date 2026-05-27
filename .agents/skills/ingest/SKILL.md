---
name: ingest
description: Ingest a source artifact (PDF, image, web page, or URL) into the wiki. Use when the user says "ingest this", "process foo.pdf", drops a file in raw/, points you at a path elsewhere on disk, attaches a file in chat, pastes a URL with implied "look at this", or directly invokes this skill. Lands the artifact under raw/, writes a faithful markdown rendering to wiki/sources/, and reindexes qmd. Do NOT use this skill for casual mentions of a URL or file in conversation — only when ingest intent is explicit.
allowed-tools: Bash(defuddle:*), Bash(npx defuddle:*), Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(qmd:*), Bash(markitdown:*), Bash(mv:*), Bash(mkdir:*)
---

# Ingest

Bring a source artifact into the wiki as a citable, indexed page.

## When to fire

- User drops a file inside `raw/` and asks you to process it.
- User points at a path elsewhere on disk ("look at ~/Downloads/foo.pdf").
- User attaches a file directly in chat.
- User pastes a URL with implied "ingest this" / "save this for later" intent.

If a URL is mentioned only in passing (no clear "save it" intent), use the `log` skill instead — don't ingest.

## Workflow

Your first job is always to **land the artifact in `raw/`** before anything else. If the file is outside `raw/`, move (don't copy) it to the correct subdir, creating the subdir if missing. If the user attached a file directly and you have its bytes but no source path, write it to `raw/<type>/<filename>`. Only then proceed with the type-specific steps below.

Both `raw/` and `wiki/sources/` are sharded by date — one directory per local date (`YYYY-MM-DD`), like `wiki/log/`.

For every source:

1. **Land** under `raw/<YYYY-MM-DD>/`, preserving the original filename (and extension). Web pages get their own slug subdir: `raw/<YYYY-MM-DD>/<slug>/` containing the cleaned markdown and, when available, the original HTML. Create the date dir on first write of that day; don't pre-create empty ones.
2. **Extract** the content:
   - PDFs → `markitdown <path>`
   - Images → vision for description; `markitdown <path>` for embedded EXIF/OCR metadata
   - Office docs (docx, pptx, xlsx) → `markitdown <path>`
   - Audio (mp3, m4a, wav) → first convert to 16 kHz mono WAV in `/tmp` (whisper-cli only reads WAV): `ffmpeg -i <path> -ar 16000 -ac 1 -c:a pcm_s16le /tmp/<slug>.wav`, then `whisper-cli -m .models/ggml-large-v3-turbo.bin -f /tmp/<slug>.wav -otxt -of <out-stem>` (writes `<out-stem>.txt`). If `.models/ggml-large-v3-turbo.bin` is missing, download as per the README.
   - Web pages → `defuddle parse <url> --md` (or `agent-browser` for dynamic / auth-walled pages)
3. **Write** `wiki/sources/<YYYY-MM-DD>/<slug>.md` with frontmatter pointing at the raw path:
   ```yaml
   ---
   title: "..."
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [...]
   source: ../../../raw/<YYYY-MM-DD>/<...>
   ---
   ```
   Body: a faithful markdown rendering plus your caption / notes.
4. **Reindex:** `qmd update && qmd embed`.

## Collisions

If `wiki/sources/<YYYY-MM-DD>/<slug>.md` already exists, stop and ask — don't clobber unless the user says "force" or "overwrite".

## Format coverage

`markitdown` is on PATH inside the dev shell (provisioned by `flake.nix`), so docx, pptx, xlsx, and audio are all supported alongside PDFs, images, and web pages. If `markitdown` errors out on a specific file, capture the error in the wiki page's frontmatter `notes:` and tell the user — do not silently land an empty page.

## Promotion is separate

Do **not** auto-promote sources on second mention. Ingest is an explicit verb. Clustering and promotion happen during lint, not during ingest.
