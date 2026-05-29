---
name: ingest
description: Ingest a source artifact (PDF, image, web page, or URL) into the wiki. Use when the user says "ingest this", "process foo.pdf", drops a file in wiki/raw/, points you at a path elsewhere on disk, attaches a file in chat, pastes a URL with implied "look at this", or directly invokes this skill. Lands the artifact under wiki/raw/ and writes a faithful markdown rendering to wiki/ai-workspace/sources/. Do NOT use this skill for casual mentions of a URL or file in conversation — only when ingest intent is explicit.
allowed-tools: Bash(defuddle:*), Bash(npx defuddle:*), Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(markitdown:*), Bash(mv:*), Bash(mkdir:*)
---

# Ingest

Bring a source artifact into the wiki as a citable, indexed page. The page captures the extracted content plus a `source:` pointer the user can follow back to the original. `wiki/ai-workspace/sources/` is sharded by date.

## Workflow

1. **Determine the `source:` pointer** before extracting. Use the most durable locator the user gave you:
   - Web page, Slack message etc. → the URL.
   - SharePoint / Quip / Drive doc → the document URL.
   - Local file → its absolute path on disk (e.g. `/Users/vijayvar/Downloads/foo.pdf`).

   If the user has no durable location for the artifact, leave `source` empty.

2. **Extract** the content from the original location (no copying):
   - PDFs, Office docs (docx/pptx/xlsx), images → `markitdown <path>` (images also get a vision description)
   - Audio (mp3, m4a, wav) → convert to 16 kHz mono WAV (whisper-cli only reads WAV), then transcribe:
     ```sh
     ffmpeg -i <path> -ar 16000 -ac 1 -c:a pcm_s16le /tmp/<slug>.wav
     whisper-cli -m .models/ggml-large-v3-turbo.bin -f /tmp/<slug>.wav -otxt -of <out-stem>
     ```
     If `.models/ggml-large-v3-turbo.bin` is missing, download per the README.
   - Web pages → `defuddle parse <url> --md`; fall back to `agent-browser` for dynamic / auth-walled pages.

3. **Write the source page** at `wiki/ai-workspace/sources/<YYYY-MM-DD>/<slug>.md`:
   ```yaml
   ---
   title: "..."
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [...]
   source: https://example.com/article            # URL (web, Slack, SharePoint, etc.)
   # source: /Users/vijayvar/Downloads/foo.pdf    # or absolute local path
   ---
   ```
   Body: the faithful markdown rendering. Keep it the artifact's voice, not yours — no commentary, reactions, or takeaways inline. The extracted markdown is the durable record; the pointer may rot, and that's accepted.

4. **Capture the user's perspective** if the ingest carries any (a paper they're reacting to, a meeting they sat in, a doc they're reviewing). Route this to the **log** skill, with a wikilink back to the source page.

## Edge cases

- **Collision:** if the source page path exists, stop and ask — don't clobber unless the user says "force" or "overwrite".
- **Extraction failure:** if `markitdown` errors, capture the error in the page's `notes:` frontmatter and tell the user. Don't silently land an empty page.
- **No promotion mid-ingest.** Clustering and promotion happen during lint.
