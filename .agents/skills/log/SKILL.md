---
name: log
description: Append substantive content from the current conversation to the dated log. Use ONLY when the user explicitly invokes this skill (e.g., `/log`, "log this", "save this to the log"). Do NOT auto-trigger on substantive content, session end, or as a side-effect of other skills — the user decides what gets logged. One file per session under `wiki/ai-workspace/<date>/<slug>.md`; the live session file is edited in place as the topic evolves, a fresh file is only created for a genuinely new thread.
---

# Log

Sink for substantive content the user asks you to record. Layout:

```
wiki/ai-workspace/
  2026-05-26/
    profitec-go-cleaning.md
    home-theater-build.md
  2026-05-25/
    determined-sapolsky-reactions.md
```

- One directory per local date (`YYYY-MM-DD`), created lazily on first write of the day.
- One file per session, `<slug>.md`. Slug is a 2-5 word kebab-case summary.
- Each file is a standalone page.

## Trigger test

When invoked, log only:

1. Things the user told you that future-you should remember.
2. Things you inferred about the user that future-you should remember.

Never log what you did. The Git diff is the record. If a session did work and surfaced a user fact, log the fact only.

## Continuation rule (the most important rule)

**One entry per session, not per turn.** A research thread, deliberation, or multi-turn exchange is a single file — fragmenting one thread across many files is noise.

To continue:

1. List `wiki/ai-workspace/<today>/` sorted by name (newest first).
2. If a file from earlier today is on the *same topic*, edit it in place: refine the title, bump `updated:`, rewrite superseded reasoning, append sub-sections.
3. If the topic is genuinely new, create a new file with a fresh slug.

"Same topic" is judgment work. A follow-up question on the same investigation, person, project, or decision is the same session. A wholly unrelated subject is a new session. When in doubt, continue the current file.

## Frontmatter

```yaml
---
title: "<short, human-readable>"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [log]
---
```

Bump `updated:` on every edit. Add domain tags freely (`[log, espresso, shopping]`); keep `log` first so `tags:log` filters cleanly.

## Body

Write what was said and decided in clean prose — no fixed structure. Use H2/H3 for subject-matter sections in long multi-turn entries; don't use headings for chronology (the filename and `updated:` already carry that).

## After writing

One line back to the user: e.g. `logged to wiki/ai-workspace/2026-05-26/profitec-go-cleaning.md`.

Don't ask the user to confirm filenames or frontmatter.
