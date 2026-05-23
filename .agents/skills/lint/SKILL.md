---
name: lint
description: Health-check the wiki. Mechanical checks (broken frontmatter, missing source files, broken wikilinks, stale pages, log format) PLUS LLM-judgment passes (contradictions between pages, claims superseded by newer sources, orphan pages with no inbound links, important concepts mentioned but lacking their own page, missing cross-references, data gaps worth a research run, recurring log topics ready for promotion). Surfaces a punch list of new questions to investigate and findings to act on. Does not auto-fix or auto-promote without user approval. Use when the user says "lint", "check the wiki", "any patterns?", "what's recurring in the log?", "what's stale?", similar, or directly invokes this skill.
allowed-tools: Bash(rg:*), Bash(qmd:*), Bash(find:*), Bash(stat:*)
---

# Lint

Periodic LLM health-check of the wiki. The wiki grows messy on its own — new sources contradict old ones, claims go stale, concepts get name-checked without ever getting a page, log entries pile up around recurring topics. Lint is when you go through the whole vault and surface what needs attention.

This is judgment work, not just a checker. Mechanical checks are the floor; the real value is the LLM-only passes below.

## When to fire

- "lint", "check the wiki", "any patterns?", "what's stale?", "what's recurring?", "what should I look into?"
- Don't run lint unsolicited.

## 1. Mechanical checks (cheap, deterministic)

- Every `wiki/` file has frontmatter with `title`, `created`, `updated`, `tags`.
- Every `wiki/sources/*.md` `source:` path resolves to an existing file in `raw/`.
- Every wikilink `[[...]]` resolves to an existing file under `wiki/`.
- `wiki/living/*.md` with `updated:` older than ~6 months is flagged stale.
- `wiki/log.md` headings parse as `## [YYYY-MM-DD HH:MM] ...` and are in chronological order (newest at top).

## 2. LLM-judgment passes (the important part)

Read enough of the wiki to make these calls. Use `qmd search` / `qmd query` to find candidates rather than scanning everything blindly. Surface findings as a punch list — each with the offending file paths and your reasoning, so the user can sanity-check.

**Contradictions.** Pages that disagree with each other on the same fact. Same source page contradicting itself across edits. New ingested sources contradicting older ones in `living/` or `concepts/`.

**Superseded claims.** Claims in older pages that newer sources have updated, corrected, or made obsolete. Mark the older claim as superseded; cite the newer source.

**Orphans.** Pages under `wiki/` that nothing else links to. Some orphans are fine (top-level living pages); flag the surprising ones — e.g. a `concepts/<X>.md` that no source or project mentions.

**Missing concept pages.** Recurring named concepts mentioned across multiple pages but lacking their own page. e.g. "deliberate practice" comes up in three book notes and a project page, but no `concepts/deliberate-practice.md` exists. Propose creating one.

**Missing cross-references.** Pages that *should* link to each other but don't. Two book notes covering the same idea without `[[]]`s between them. A project page that name-drops a person without linking to `people/<them>.md`.

**Data gaps worth researching.** Open questions, "I should check…" notes, or claims hedged with "not sure if…" that a quick web `research` pass could resolve. Propose specific questions to feed to the research skill.

**Recurring log topics → promotion candidates.** A cluster is roughly ≥3 entries on the same topic, or a clear thread (multi-day book reactions, sustained work on one initiative, repeated person mentions). Propose a destination directory (`projects/`, `books/`, `concepts/`, `ideas/`, etc. — invent new ones as needed).

## Output

Single punch list, grouped by pass. Each item is one or two lines, names the file paths involved, and is independently approvable. Example:

> **Mechanical**
> - Frontmatter: 47/47 files OK.
> - Broken wikilink in `projects/smoky-tractor.md`: `[[concepts/idle-time]]` not found.
> - Stale: `living/about-me.md` last updated 2025-09-11.
>
> **Contradictions**
> - `books/sapolsky-determined.md` and `concepts/free-will.md` disagree on whether libertarian free will is salvageable. Reconcile?
>
> **Missing concept pages**
> - "deliberate practice" appears in 4 pages (3 books + 1 project) but no `concepts/deliberate-practice.md`. Spin one out?
>
> **Data gaps**
> - `projects/smoky-tractor.md` has "TODO: check what RPM the Kubota L3301 actually idles at" — run research?
>
> **Promotion**
> - 7 log entries on Smoky Tractor over 3 weeks → `wiki/projects/smoky-tractor.md`?
> - 5 entries on Sapolsky's *Determined* → `wiki/books/determined.md`?

## Acting on items

The user approves items individually or in bulk. For each:

- **Promotion** — create destination page with frontmatter, move substance from `log.md`, leave a one-line pointer (`## [HH:MM] → [[projects/smoky-tractor]]`), then `qmd update && qmd embed`. (No incoming-backlink rewrites needed; the page didn't exist before.)
- **Missing concept page** — create a stub with what you know, link the mentioning pages to it, then `qmd update && qmd embed`.
- **Missing cross-reference** — add the `[[wikilink]]` in both directions where appropriate.
- **Contradiction / superseded** — update the older page, mark the obsolete claim, cite the newer source. If you can't reconcile without more info, leave a `TODO:` and surface it next lint.
- **Data gap** — kick off the research skill with the specific question.
- **Mechanical fix** — see auto-fixes below.

## Auto-fixes

On explicit "fix it" / "auto-fix":
- Frontmatter normalization (add missing keys with sensible defaults — `created`/`updated` from file mtime, empty `tags: []`, title from H1 or filename).
- Stale `updated:` bumped to file mtime.

Do NOT auto-fix broken wikilinks, missing `source:` paths, contradictions, or promotion candidates — those all need human judgment. Report them and stop.
