---
name: web-research
description: Web research workflow. Use ONLY when the user explicitly asks to research, look up, find out, or investigate something online, or directly invokes this skill. Drives an already-running Chrome via agent-browser auto-connect, opens search results, extracts clean markdown with defuddle, and synthesizes a cited answer in chat. Does NOT auto-persist — the user invokes the log skill explicitly if they want the answer saved. Do NOT use for questions answerable from the local wiki (use the query skill instead) or for ingesting a specific URL the user already named (use the ingest skill).
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(defuddle:*), Bash(npx defuddle:*), Bash(qmd:*), Bash(mkdir:*), Bash(date:*)
---

# Web research

Drive web research on the user's already-running Chrome and return a cited answer in chat.

## Workflow

1. **Connect.** Run `agent-browser` to attach to the user's Chrome — the wrapper handles CDP. Reuses logins/cookies; the user can watch. If the wrapper exits non-zero, tell the user once and stop. (See AGENTS.md §5.)

2. **Search.** Open a search engine (Google by default) and run a query derived from the user's question. Refine if results look weak. Ignore the search engine's AI answers.

3. **Read adaptively until evidence is sufficient.** For each URL: prefer `defuddle parse <url> --md` (cheaper tokens than driving the browser); fall back to agent-browser when defuddle fails (auth walls, JS-only, dynamic apps). Stop when 3-5 reputable sources agree and the question is answered; keep going when sources are vague, conflicting, or only partial.

4. **Handle disagreement honestly.** Note conflicts in the answer; characterize *why* sources differ (date, scope, reliability) before picking a side or leaving it open.

5. **Synthesize.** Write a concise answer in the user's voice, not a list of per-source summaries. Cite inline with `[1]`, `[2]`; every non-trivial claim gets a citation. End with a `**Sources:**` numbered list of URLs.
