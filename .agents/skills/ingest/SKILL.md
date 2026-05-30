---
name: ingest
description: Ingest a source artifact (PDF, image, web page, or URL) into the wiki. Use when the user says "ingest this", "process foo.pdf", drops a file in wiki/raw/, points you at a path elsewhere on disk, attaches a file in chat, pastes a URL with implied "look at this", or directly invokes this skill. Lands the artifact under wiki/raw/ and writes a faithful markdown rendering to wiki/ai-workspace/sources/. Do NOT use this skill for casual mentions of a URL or file in conversation — only when ingest intent is explicit.
---

# Ingest

Bring a source artifact into the wiki as a citable, indexed page. The page captures the extracted content plus a `source:` pointer the user can follow back to the original. `wiki/ai-workspace/sources/` is sharded by date.

## Workflow

1. **Determine the `source:` pointer** before extracting. Use the most durable locator the user gave you:
   - Web page, Slack message etc. → the URL.
   - SharePoint / Quip / Drive doc → the document URL.
   - Local file → its absolute path on disk (e.g. `/Users/vijayvar/Downloads/foo.pdf`).

   If the user has no durable location for the artifact, leave `source` empty.

2. **Extract** the content from the original location (no copying, except for images — see below):
   - PDFs, Office docs (docx/pptx/xlsx) → `markitdown <path>`
   - Images → move the file into `wiki/ai-workspace/sources/<YYYY-MM-DD>/<slug>.<ext>` first, then run `markitdown` on the moved path (gives OCR text plus a vision description). (Images are small enough to keep adjacent to their rendering.)
   - Audio (mp3, m4a, wav) and video (mp4, mov) → `.agents/skills/ingest/transcribe.py <path> [out-stem]`. Outputs `<out>.md`. Pass `INITIAL_PROMPT="..."` with comma-separated jargon (product names, acronyms) for the meeting's domain; defaults are AWS/SageMaker.
   - Web pages → `defuddle parse <url> --md`; fall back to `agent-browser` for dynamic / auth-walled pages.
   - Zoom recordings / signed CloudFront URLs (curl 403s) → `.agents/skills/ingest/zoom-download.sh <share-url> [filename.mp4]`. File lands in `~/Downloads`. Signed URL expires in a few hours — reopen the page if returning later. Grab chat panel + chapter markers via `agent-browser snapshot` first; they flag silent stretches and link companion docs.

3. **Write the source page** at `wiki/ai-workspace/sources/<YYYY-MM-DD>/<slug>.md`:
   ```yaml
   ---
   title: "..."
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [...]
   source: https://example.com/article            # URL (web, Slack, SharePoint, etc.)
   # source: /Users/vijayvar/Downloads/foo.pdf    # or absolute local path
   # source: ai-workspace/sources/2026-05-29/foo.png  # for images, point at the moved file (relative to wiki/)
   ---
   ```
   Body: the faithful markdown rendering. Keep it the artifact's voice, not yours — no commentary, reactions, or takeaways inline. The extracted markdown is the durable record; the pointer may rot, and that's accepted.

4. **Capture the user's perspective** if the ingest carries any (a paper they're reacting to, a meeting they sat in, a doc they're reviewing). Route this to the **log** skill, with a wikilink back to the source page.

## Edge cases

- **Collision:** if the source page path exists, stop and ask — don't clobber unless the user says "force" or "overwrite".
- **Extraction failure:** if `markitdown` errors, capture the error in the page's `notes:` frontmatter and tell the user. Don't silently land an empty page.
- **No promotion mid-ingest.** Clustering and promotion happen during lint.
