---
name: web-research
description: Web research workflow. Use ONLY when the user explicitly asks to research, look up, find out, or investigate something online, or directly invokes this skill. Drives an already-running Chrome via agent-browser, opens search results, and synthesizes cited answers.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(defuddle:*), Bash(npx defuddle:*)
---

# Web research

Drive web research on the user's already-running Chrome and return a cited answer in chat.

## Workflow

1. **Connect.** Run `agent-browser` to attach to the user's Chrome — the wrapper handles CDP. Reuses logins/cookies; the user can watch. If the wrapper exits non-zero, tell the user once and stop. (See AGENTS.md §5.)

2. **Search.** Open `https://search.brave.com/` and run a query derived from the user's question. Refine if results look weak.

3. **Read deeply.** Fetch and read full page content from **≥10 distinct domains** before synthesizing. Search snippets, SERP text, and AI summaries do NOT count — only the actual fetched page body counts. Prefer cheaper extraction (e.g. `defuddle parse <url> --md`); fall back to driving the browser when extraction fails (auth walls, JS-only, dynamic apps). Keep going past 10 if sources are vague, conflicting, or only partial.

4. **Source-quality gate.** Count toward the 10 only: official docs, peer-reviewed or specialist outlets, hobby forums and communities with traceable expertise, primary reporting from established publications. Reject and do NOT count: SEO listicles, AI-generated content farms, Pinterest/Quora-tier roundups, syndicated rewrites of other sources. *Conflicted sources* — anyone who sells the product, is paid to promote it, or runs an affiliate program around it (manufacturer/vendor sites, seller-run blogs and review pages, retailer "best of" lists) — may be cited for objective facts (specs, dimensions, official price, release date) but NOT for evaluative claims (quality, "best for X", comparisons, recommendations), and they do not count toward the 10. When in doubt, treat as conflicted.

5. **Recency check.** If the answer depends on current state (prices, versions, releases, regulations, availability), at least one source must be dated within the last 12 months. Note its date inline next to the citation.

6. **Refute pass.** After drafting the answer, run at least one query designed to contradict it — e.g. `<claim> wrong`, `<claim> myth`, `<claim> debunked`, `<claim> 2026 update`. If results dispute the draft, revise; if they don't, you've stress-tested it.

7. **Handle disagreement honestly.** Note conflicts in the answer; characterize *why* sources differ (date, scope, reliability) before picking a side or leaving it open.

8. **Pre-synthesis self-audit.** Before writing the answer, confirm out loud: ≥10 qualifying domains read in full, refute pass run, recency satisfied where relevant, conflicts noted, and every non-trivial evaluative claim has ≥2 independent non-conflicted backers (different ownership, not syndicating each other) — flag any single-source claim inline (e.g. "single-source: [3]"). If any box is unchecked, go back.

9. **Synthesize.** Write a concise answer in the user's voice, not a list of per-source summaries. Cite inline with `[1]`, `[2]`; every non-trivial claim gets a citation. End with a `**Sources:**` numbered list of URLs, marking conflicted sources with `(conflicted)` so the reader knows their role.
