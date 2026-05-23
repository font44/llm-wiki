---
name: query
description: Answer a question from the local wiki. Use when the user asks something the wiki might know — "what did I read about X?", "do I have notes on Y?", "what did I say about Z?", "summarize what we have on …". Searches qmd, fetches matching sources, synthesizes a cited answer. Do NOT use for web research (use the research skill) or for ingesting new sources (use ingest).
allowed-tools: Bash(qmd:*), Bash(rg:*), mcp__qmd__*
---

# Query

Answer from the local wiki, citing sources.

## When to fire

Anything the wiki might already know — direct questions about past notes, books, projects, people, decisions, preferences, or ingested sources. If the user asks something that clearly isn't in the wiki ("what's the latest news on X"), route to the research skill instead.

## Workflow

1. **Search** for candidates:
   - `qmd search "<terms>"` — BM25 lexical
   - `qmd query "<question>"` — hybrid semantic
   - For harder searches use structured queries with `intent:`, `lex:`, `vec:`, `hyde:` fields.

2. **Retrieve** the full sources — search snippets are leads, not answers:
   - `qmd get <docid>` for a single doc
   - `qmd multi-get '<pattern>'` or `qmd multi-get "#id1,#id2" --md` for several

3. **Synthesize** the answer from retrieved text. Cite inline as `[[sources/<type>/<slug>]]` or `[[<other-path>]]`. When relevant, mention the underlying `raw/` path so the user can trace back to the artifact.

## Don't

- Don't answer from snippets alone when the user needs facts, decisions, quotes, or nuance.
- Don't paste whole documents into the response — a compact note + citations is enough.
- Don't go to the web for an answer that might be in the wiki without searching first.
