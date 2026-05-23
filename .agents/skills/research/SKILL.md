---
name: research
description: Web research workflow. Use ONLY when the user explicitly asks to research, look up, find out, or investigate something online, or directly invokes this skill. Drives an already-running Chrome via agent-browser auto-connect, opens search results, extracts clean markdown with defuddle, synthesizes a cited answer, and appends the result to wiki/log.md. Do NOT use for questions answerable from the local wiki (use the query skill instead) or for ingesting a specific URL the user already named (use the ingest skill).
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(defuddle:*), Bash(npx defuddle:*), Bash(qmd:*)
---

# Research

Drive web research on the user's already-running Chrome and persist the answer to the wiki.

## When to fire

Triggers: "research X", "look up X", "find out about X", "investigate X", "search the web for X", "what's the latest on X", or direct invocation of this skill. If intent is ambiguous between research and query (the wiki may already know), check the wiki first via `qmd search` — only proceed to web research if local results are thin.

## Workflow

1. **Connect.** Use `agent-browser --auto-connect` to attach to the user's running Chrome over CDP. Reuses logins/cookies; the user can watch. Do NOT spin up a fresh headless session — that loses auth and trips captchas. If no Chrome is running, tell the user once and stop.

2. **Search.** Open a search engine (Google by default) and run a query derived from the user's question. Refine the query if results look weak.

3. **Read adaptively until evidence is sufficient.** Open results one at a time. For each URL:
   - Prefer `defuddle parse <url> --md` for clean markdown — cheaper tokens than driving the browser to read the page.
   - Fall back to agent-browser only when defuddle fails (auth walls, JS-only content, dynamic apps).

   Stop opening new sources when 2–3 reputable sources agree on the key facts and the user's question is clearly answered. Keep going — open more, refine the query, try a different angle — when sources are vague, low-quality, conflicting, or only partially cover the question.

4. **Handle disagreement honestly.** If sources conflict, note the disagreement in the answer rather than papering over it. Try to characterize *why* they differ (date, scope, source reliability) before picking a side or leaving it open.

5. **Synthesize.** Write a concise answer in the user's voice — not a list of summaries-per-source. Cite inline with `[1]`, `[2]` markers; end with a `**Sources:**` numbered list of URLs. Every non-trivial claim gets a citation.

6. **Persist to log.md.** Append a single entry to `wiki/log.md` per the standard log format (newest at top):

   ```
   ## [YYYY-MM-DD HH:MM] research: <short question>

   <synthesized answer with [1]/[2] inline markers>

   **Sources:**
   [1] https://...
   [2] https://...
   ```

7. **Print the answer in chat too**, so the user sees it without opening the file. End with a one-line "logged to wiki/log.md" pointer.

## Notes

- Ignore the search engine's AI answers. Do your own research.
- Date in the log heading uses today's local date in `YYYY-MM-DD HH:MM` 24-hour format.
- Do NOT promote research entries into their own pages mid-flight. If a topic recurs, the lint skill clusters and promotes during a lint pass — same rule as any other log entry.
- If the user's question is local (e.g. "what did I write about X"), this is the wrong skill — use the query skill instead.
