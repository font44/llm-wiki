---
name: log
description: Append substantive content the user shares to the dated log. Use when the user states a fact, opinion, decision, reaction, person, source, or any thought worth recalling later that isn't an ingest, a wiki query, a lint, or a `living/` update. One file per session under `wiki/log/<date>/<HHMM>-<slug>.md` — the live session file is edited in place as the topic evolves; a fresh file is only created for a genuinely new thread. Also used by the web-research skill as the persistence step.
allowed-tools: Bash(mkdir:*), Bash(date:*), Bash(ls:*), Bash(rg:*)
---

# Log

The dated log is the default sink for substantive content the user shares. Layout:

```
wiki/log/
  2026-05-26/
    1742-profitec-go-cleaning.md
    1608-home-theater-build.md
  2026-05-25/
    2031-determined-sapolsky-reactions.md
```

- **One directory per local date** (`YYYY-MM-DD`).
- **One file per session**, named `<HHMM>-<short-slug>.md`. `HHMM` is 24-hour local time of when the session started; the slug is a 2-5 word kebab-case summary.
- Each file is a standalone markdown page with its own frontmatter — qmd indexes each session as a discrete document.

## When to fire

Append when the user says something worth recalling later: a fact, thought, opinion, decision, reaction, person, source, plan, or reflection. Ask yourself: *"is there anything new about the user, their world, or their thinking in this exchange?"* If no, don't log.

Skip when:

- The user wants to ingest a source (use the `ingest` skill).
- The user is asking the wiki a question (use `query`).
- The user is asking for web research (use `web-research` — it calls back into this skill to persist).
- The user is stating a stable personal preference about themselves (`wiki/living/<topic>.md`).
- The exchange is purely conversational with no durable substance.

If a user message is genuinely ambiguous between log and `living/`, prefer log. Promotion is cheap; cleanup of premature pages is not.

## Continuation rule (the most important rule)

**One entry per session, not per turn.** A research thread, deliberation, shopping task, or any multi-turn exchange is a single log file. Do not create a new file on every new turn — that fragments one coherent thread into noise.

Detecting "same session" — open or create today's date dir, then:

1. List files in `wiki/log/<today>/` sorted by name (newest filename = newest start time).
2. If a file from earlier today is on the *same topic* as the current exchange, **edit that file in place**: refine the title, bump `updated:` to now, rewrite superseded reasoning, append new sub-sections. Do not change `HHMM` — it stays as the session start.
3. If the topic is genuinely new, create a new file with the current `HHMM` and a fresh slug.

"Same topic" is judgment work. A second question that builds on the same investigation, person, project, or decision is the same session. A wholly unrelated subject (espresso research → tax-prep question) is a new session. When in doubt, prefer continuing the current file unless the topic shift is obvious.

## Frontmatter

Every log file:

```yaml
---
title: "<short title — same as the slug, but human-readable>"
created: YYYY-MM-DD HH:MM
updated: YYYY-MM-DD HH:MM
tags: [log]
---
```

Bump `updated:` whenever you edit. Add domain tags freely (e.g. `[log, espresso, shopping]`); keep `log` first so `tags:log` filters cleanly.

## Body

No fixed structure — write what the user said and what was decided in clean prose. For research-type entries, follow the web-research skill's body conventions (synthesized answer, inline `[1]/[2]` markers, `**Sources:**` list).

For longer multi-turn deliberations, use H2/H3 headings to organize sections inside the file. The filename and title carry the date+time context, so headings inside the file should be about subject matter, not chronology.

## After writing

Tell the user one line: which file you wrote/updated. Example: `logged to wiki/log/2026-05-26/1742-profitec-go-cleaning.md`.

## Promotion (handled by lint, not here)

Recurring log entries cluster into projects/books/concepts/ideas pages during a `lint` pass — never mid-flight from this skill. When lint promotes a session, it moves the file out of `wiki/log/<date>/` to its destination and leaves no stub behind (the date dir simply has one fewer file).

## Don't

- Don't add `wiki/log.md` — the monolithic file is gone. Anything that previously appended there now writes to `wiki/log/<date>/<HHMM>-<slug>.md`.
- Don't create empty date directories ahead of time. Create the dir only when you write the first session of that date.
- Don't ask the user to confirm filenames or frontmatter — just write it. They'll fix it during lint if it's wrong.
