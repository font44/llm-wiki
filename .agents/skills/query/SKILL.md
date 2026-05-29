---
name: query
description: Answer a question from the local wiki. Use when the user asks something the wiki might know — "what did I read about X?", "do I have notes on Y?", "what did I say about Z?", "summarize what we have on …". Searches qmd, fetches matching sources, synthesizes a cited answer. Do NOT use for web research (use the web-research skill) or for ingesting new sources (use ingest).
allowed-tools: Bash(qmd:*), Bash(rg:*), mcp__qmd__*
---

# Query

Answer from the local wiki, citing sources.

## Workflow

1. **Search** for candidates:
   - `qmd search "<terms>"` — BM25 lexical
   - `qmd query "<question>"` — hybrid semantic
   - For harder cases, structured queries with `intent:`, `lex:`, `vec:`, `hyde:` fields.

2. **Retrieve** the full sources — snippets are leads, not answers:
   - `qmd get <docid>` for one doc
   - `qmd multi-get '<pattern>'` or `qmd multi-get "#id1,#id2" --md` for several

3. **Synthesize** from retrieved text. Cite inline with path-based wikilinks (`[[ai-workspace/sources/<YYYY-MM-DD>/<slug>]]`). Mention the underlying `wiki/raw/` path when it helps the user trace back to the artifact.

## Don't

- Don't answer from snippets alone when the user needs facts, decisions, quotes, or nuance.
- Don't paste whole documents — a compact note + citations is enough.
- Don't go to the web before searching the wiki.
