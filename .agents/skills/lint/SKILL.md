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

## Scope

Lint operates only on `wiki/ai-workspace/`. It may **read** anywhere under `wiki/` for retrieval and cross-reference, but never edits, deletes, or flags structural issues outside `ai-workspace/`.

## 1. Mechanical checks (cheap, deterministic)

Run these against `wiki/ai-workspace/`:

- Every markdown file has frontmatter with `title`, `created`, `updated`, `tags`.
- Every `ai-workspace/sources/<YYYY-MM-DD>/*.md` lives under a date dir matching `YYYY-MM-DD` and has the standard frontmatter. Its `source:` is either a URL (web pages) or a relative path that resolves to an existing file under `wiki/raw/` (file artifacts).
- Every wikilink `[[...]]` resolves to an existing file under `wiki/`.
- `ai-workspace/living/*.md` with `updated:` older than ~6 months is flagged stale.
- `ai-workspace/log/` layout: every entry lives at `ai-workspace/log/<YYYY-MM-DD>/<HHMM>-<slug>.md`. Date dirs match `YYYY-MM-DD`; filenames start with a 4-digit `HHMM`. Each file has the standard frontmatter (`title`, `created`, `updated`, `tags` including `log`).

## 2. LLM-judgment passes (the important part)

Read enough of the wiki to make these calls. Use `qmd search` / `qmd query` to find candidates rather than scanning everything blindly. Surface findings as a punch list — each with the offending file paths and your reasoning, so the user can sanity-check.

**Contradictions.** Pages that disagree with each other on the same fact. Same source page contradicting itself across edits. New ingested sources contradicting older ones in `living/` or `concepts/`.

**Superseded claims.** Claims in older pages that newer sources have updated, corrected, or made obsolete. Mark the older claim as superseded; cite the newer source.

**Orphans.** In-scope pages that nothing else links to. Some orphans are fine (top-level living pages); flag the surprising ones — e.g. a `concepts/<X>.md` that no source or project mentions.

**Missing concept pages.** Recurring named concepts mentioned across multiple pages but lacking their own page. e.g. "deliberate practice" comes up in three book notes and a project page, but no `concepts/deliberate-practice.md` exists. Propose creating one.

**Missing cross-references.** Pages that *should* link to each other but don't. Two book notes covering the same idea without `[[]]`s between them. A project page that name-drops a person without linking to `people/<them>.md`.

**Data gaps worth researching.** Open questions, "I should check…" notes, or claims hedged with "not sure if…" that a quick web `web-research` pass could resolve. Propose specific questions to feed to the web-research skill.

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
> - 7 log entries on Smoky Tractor over 3 weeks → `wiki/ai-workspace/projects/smoky-tractor.md`?
> - 5 entries on Sapolsky's *Determined* → `wiki/ai-workspace/books/determined.md`?

## Acting on items

The user approves items individually or in bulk. For each:

- **Promotion** — create the destination page under `wiki/ai-workspace/` with frontmatter, move substance out of the source `wiki/ai-workspace/log/<date>/<file>.md` (delete or empty the file once moved — don't leave stubs; the date dir simply has one fewer file), then `qmd update && qmd embed`. (No incoming-backlink rewrites needed; the page didn't exist before.)
- **Missing concept page** — create a stub with what you know, link the mentioning pages to it, then `qmd update && qmd embed`.
- **Missing cross-reference** — add the `[[wikilink]]` in both directions where appropriate.
- **Contradiction / superseded** — update the older page, mark the obsolete claim, cite the newer source. If you can't reconcile without more info, leave a `TODO:` and surface it next lint.
- **Data gap** — kick off the web-research skill with the specific question.
- **Mechanical fix** — see auto-fixes below.

## Auto-fixes

On explicit "fix it" / "auto-fix":
- Frontmatter normalization (add missing keys with sensible defaults — `created`/`updated` from file mtime, empty `tags: []`, title from H1 or filename).
- Stale `updated:` bumped to file mtime.

Do NOT auto-fix broken wikilinks, missing `source:` paths, contradictions, or promotion candidates — those all need human judgment. Report them and stop.
