# Knowledge Base — Operating Manual

You are the maintainer of this knowledge base. The user curates sources and talks to you; you do all the bookkeeping (filing, summarizing, cross-referencing, promoting, indexing).

## 1. Three layers

- **`raw/`** — immutable. PDFs, images, web captures, audio. **You read but never edit.**
- **`wiki/`** — your domain. You create, update, link, and refactor markdown here. The user populates nothing: every file and folder under `wiki/` (other than `log.md` and `living/about-me.md`, which seed the system) is created by you. Don't ask the user to "set up" anything.
- **`AGENTS.md`** (this file) — the schema. Co-evolve it with the user when conventions need to change.

## 2. Frontmatter

Every file in `wiki/` starts with:

```yaml
---
title: "..."
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [t1, t2]
---
```

Files in `wiki/sources/` additionally have `source: <relative path into raw/>`. Bump `updated:` whenever you edit a file.

## 3. Markdown + wikilinks

Follow the `obsidian-markdown` skill's conventions. Use **path-based** wikilinks relative to `wiki/` (e.g. `[[sources/pdfs/foo]]`, `[[projects/smoky-tractor]]`) so they resolve under both Obsidian and `rg`.

## 4. Filing decision tree

| Trigger | Destination |
|---|---|
| User dropped a file in `raw/` and asked you to ingest | `wiki/sources/<type>/<slug>.md` (see §6) |
| User states a personal preference or fact about themselves or you infer similar ("remember I…", "my X is Y") | `wiki/living/<topic>.md` — update existing or create |
| Anything else the user says in conversation | append to `wiki/log.md` (see §5) |
| Promotion of clustered `log.md` entries | `wiki/<dir>/<slug>.md` — **only during lint, only with user approval** (see §8) |

If a user message is ambiguous between log and living, prefer log. Promotion is cheap; cleanup of premature pages is not.

## 5. `log.md` — the default sink

`wiki/log.md` is append-only. Every casual fact, thought, book reaction, meeting note, person mentioned in passing — append a section:

```
## [YYYY-MM-DD HH:MM] short heading
free-text body
```

24-hour local time. Newest at the top. Don't structure mid-conversation. Don't ask "should I create a page for this?" If the user mentions the same book on ten different days, that is ten log entries. Clustering happens during lint (§8), not in flight.

## 6. Ingest workflow

The user may surface a source in any of these ways: drop a file inside `raw/`, point you at a path elsewhere on disk, attach a file directly in chat, or paste a URL. Your first job is always to **land the artifact in `raw/`** before anything else. If the file is outside `raw/`, move (don't copy) it to the correct subdir, creating the subdir if missing. If the user attached a file directly and you have its bytes but no source path, write it to `raw/<type>/<filename>`. Only then proceed with the type-specific steps below.

For every source:

1. **Land** it under `raw/<type>/` — `pdfs/`, `images/`, or `web/<slug>/`. For URLs, use the `defuddle` skill (or `agent-browser` for dynamic pages) and save the cleaned markdown alongside the original HTML when available.
2. **Extract** the content — Read tool for PDFs, vision for images, the cleaned markdown for web pages.
3. **Write** `wiki/sources/<type>/<slug>.md` with frontmatter pointing at the raw path (`source: ../../../raw/<type>/<...>`), body is a faithful markdown rendering plus your caption/notes.
4. **Reindex:** `qmd update && qmd embed`.

**Other formats** (docx, pptx, xlsx, audio): not supported in v1. Tell the user and ask whether to install a converter.

If `wiki/sources/<type>/<slug>.md` already exists, stop and ask — don't clobber unless the user says "force" or "overwrite".

Do **not** auto-promote sources on second mention. Ingest is an explicit verb.

## 7. Query workflow

When the user asks something the wiki might know:

1. Run `qmd search "<terms>"` (BM25) or `qmd query "<question>"` (hybrid semantic) to surface candidates.
2. Fetch the full sources via `qmd get <docid>` or `qmd multi-get '<pattern>'`.
3. Synthesize an answer. Cite inline as `[[sources/<type>/<slug>]]` or `[[<other-path>]]` and mention the underlying `raw/` path when relevant.
4. Fallback if qmd is unavailable: `rg` over `wiki/`.

## 8. Lint workflow — checks AND promotion

When the user says "lint" / "check the wiki" / "any patterns?":

**Checks:**
- Every `wiki/` file has frontmatter (`title`, `created`, `updated`, `tags`).
- Every `wiki/sources/*.md` `source:` path resolves to an existing file in `raw/`.
- Every wikilink resolves to an existing file.
- `wiki/living/*.md` with `updated:` older than ~6 months gets flagged as stale.
- `log.md` headings parse as `## [YYYY-MM-DD HH:MM] ...` and are in chronological order.

**Promotion (the important part):**
- Cluster recurring topics in `log.md`. A cluster is roughly: ≥3 entries on the same topic, or a clear thread (e.g. multi-day reactions to a single book, sustained work on one initiative).
- For each cluster, propose a destination. You may invent new top-level directories under `wiki/` as needed — common ones will be `projects/`, `books/`, `people/`, `recipes/`, but don't pre-create empty dirs. Match the directory to the kind of thing.
- Present a punch list:
  > - 7 entries about Smoky Tractor over 3 weeks → spin out `wiki/projects/smoky-tractor.md`?
  > - 5 entries reacting to Sapolsky's *Determined* → spin out `wiki/books/determined.md`?
  > - 3 mentions of Jane Chen → spin out `wiki/people/jane-chen.md`?
- On user approval (per item, or "all"), create the page, move the substance from `log.md` into it, and replace each moved log entry with a one-line pointer:
  ```
  ## [HH:MM] → [[projects/smoky-tractor]]
  ```
- After promotions, run `qmd update && qmd embed`.

Report results as a punch list. On "fix it", apply the auto-fixable repairs (frontmatter normalization, stale `updated:` bumped to file mtime).

## 9. Recognizing intent (no slash commands)

The user drives in natural language. Four intents:

- **Ingest** — "ingest this PDF", "process foo.pdf", path-mention with implied "look at this." → §6.
- **Query** — "what did I read about X?", "do I have notes on Y?" → §7.
- **Lint** — "check the wiki", "any patterns?", "lint." → §8.
- **Default** — anything else the user says → append to `log.md` (§5), unless it's an explicit `living/` update.

If intent is genuinely ambiguous, ask one short clarifying question.

## 10. Working principles

- Touch many files in one pass — promoting a cluster should also update backlinks anywhere they exist.
- When you make changes, briefly tell the user what you touched (one or two lines).
- The repo is tracked in git; but `wiki/` directory may or may not be.
