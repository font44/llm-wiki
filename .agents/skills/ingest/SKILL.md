---
name: ingest
description: Ingest a source artifact (PDF, image, web page, or URL) into the wiki. Use when the user says "ingest this", "process foo.pdf", drops a file in wiki/raw/, points you at a path elsewhere on disk, attaches a file in chat, pastes a URL with implied "look at this", or directly invokes this skill. Lands the artifact under wiki/raw/ and writes a faithful markdown rendering to wiki/ai-workspace/sources/. Do NOT use this skill for casual mentions of a URL or file in conversation — only when ingest intent is explicit.
allowed-tools: Bash(defuddle:*), Bash(npx defuddle:*), Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(markitdown:*), Bash(mv:*), Bash(mkdir:*)
---

# Ingest

Bring a source artifact into the wiki as a citable, indexed page. `wiki/raw/` and `wiki/ai-workspace/sources/` are both sharded by date.

## Workflow

1. **For file artifacts**, move into `wiki/raw/<YYYY-MM-DD>/` first (create the date dir if missing). Web pages skip this — the URL is the citation.

2. **Extract** the content:
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
   source: ../../../raw/<YYYY-MM-DD>/<...>   # file artifact: relative path into wiki/raw/
   # source: https://example.com/article     # web page: the URL
   ---
   ```
   Body: the faithful markdown rendering. Keep it the artifact's voice, not yours — no commentary, reactions, or takeaways inline.

4. **Capture the user's perspective** if the ingest carries any (a paper they're reacting to, a meeting they sat in, a doc they're reviewing). Route this to the **log** skill, with a wikilink back to the source page.

## Edge cases

- **Collision:** if the source path exists, stop and ask — don't clobber unless the user says "force" or "overwrite".
- **Extraction failure:** if `markitdown` errors, capture the error in the page's `notes:` frontmatter and tell the user. Don't silently land an empty page.
- **No promotion mid-ingest.** Clustering and promotion happen during lint.
