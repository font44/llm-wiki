---
name: log
description: Append substantive content the user shares to the dated log. Use when the user states a fact, opinion, decision, reaction, person, source, or any thought worth recalling later that isn't an ingest, a wiki query, a lint, or a `living/` update. One file per session under `wiki/ai-workspace/log/<date>/<HHMM>-<slug>.md` — the live session file is edited in place as the topic evolves; a fresh file is only created for a genuinely new thread. Also used by the web-research skill as the persistence step.
allowed-tools: Bash(mkdir:*), Bash(date:*), Bash(ls:*), Bash(rg:*)
---

# Log

Default sink for substantive content the user shares. Layout:

```
wiki/ai-workspace/log/
  2026-05-26/
    1742-profitec-go-cleaning.md
    1608-home-theater-build.md
  2026-05-25/
    2031-determined-sapolsky-reactions.md
```

- One directory per local date (`YYYY-MM-DD`), created lazily on first write of the day.
- One file per session, `<HHMM>-<slug>.md`. `HHMM` is 24-hour local time when the session *started*; slug is a 2-5 word kebab-case summary.
- Each file is a standalone page.

## Trigger test

Ask yourself: *"is there anything new about the user, their world, or their thinking in this exchange?"* If no, don't log. Conversational filler doesn't get logged. Ingests, queries, research, and `living/` updates each have their own skill; this is the catch-all.

## Continuation rule (the most important rule)

**One entry per session, not per turn.** A research thread, deliberation, or multi-turn exchange is a single file — fragmenting one thread across many files is noise.

To continue:

1. List `wiki/ai-workspace/log/<today>/` sorted by name (newest first).
2. If a file from earlier today is on the *same topic*, edit it in place: refine the title, bump `updated:`, rewrite superseded reasoning, append sub-sections.
3. If the topic is genuinely new, create a new file with the current `HHMM` and a fresh slug.

"Same topic" is judgment work. A follow-up question on the same investigation, person, project, or decision is the same session. A wholly unrelated subject is a new session. When in doubt, continue the current file.

## Frontmatter

```yaml
---
title: "<short, human-readable>"
created: YYYY-MM-DD HH:MM
updated: YYYY-MM-DD HH:MM
tags: [log]
---
```

Bump `updated:` on every edit. Add domain tags freely (`[log, espresso, shopping]`); keep `log` first so `tags:log` filters cleanly.

## Body

Write what was said and decided in clean prose — no fixed structure. Use H2/H3 for subject-matter sections in long multi-turn entries; don't use headings for chronology (the filename and `updated:` already carry that). Research entries follow the web-research body convention (synthesized answer, inline `[1]/[2]`, `**Sources:**` list).

## After writing

One line back to the user: e.g. `logged to wiki/ai-workspace/log/2026-05-26/1742-profitec-go-cleaning.md`.

Don't ask the user to confirm filenames or frontmatter; lint will catch mistakes. Promotion happens in lint, not here.
