# Knowledge Base

A personal AI-managed knowledge base. You drop sources (PDFs, images, web pages, audio, ad-hoc facts) into `raw/`; Claude reads them, files distilled markdown into `wiki/`, maintains cross-references, and answers questions across the wiki via [qmd](https://github.com/tobi/qmd) hybrid search.

The full operating manual for the agent is in [`CLAUDE.md`](./CLAUDE.md).

## Layout

```
raw/        immutable source artifacts (PDFs, images, web, audio)
wiki/       LLM-managed markdown
  index.md      what's in the vault
  daily/        YYYY-MM-DD.md one-off jottings (bidirectional)
  living/       kept-current topical notes (preferences, rotations, etc.)
  entities/     canonical page per recurring real thing
  concepts/     ideas, how-tos, decisions
  sources/      one md page per ingested raw artifact
.claude/    Claude Code config (qmd MCP wiring; skills installed locally)
flake.nix   devShell pinning all tools
```

## Bootstrap (fresh machine)

```sh
cd /path/to/this/repo

# 1. devShell — pulls claude-code, qmd, agent-browser, openskills, markitdown
direnv allow              # or: nix develop

# 2. Install upstream skills into .claude/skills/ (gitignored)
npx openskills install https://github.com/kepano/obsidian-skills/tree/main/skills/obsidian-markdown
npx openskills install https://github.com/kepano/obsidian-skills/tree/main/skills/obsidian-cli
npx openskills install https://github.com/kepano/obsidian-skills/tree/main/skills/defuddle
npx openskills install https://github.com/vercel-labs/agent-browser

# 3. qmd index (no-op on empty wiki, sets up .qmd/)
qmd index wiki/

# 4. Open Claude in the vault
claude
```

To refresh skills later: `npx openskills update`.

## Usage

There are no slash commands — drive everything in natural language. `CLAUDE.md` teaches Claude to recognize:

- **Ingest** — "ingest this PDF", "process foo.pdf", "I dropped a paper in raw/"
- **Query** — "what did I read about X?", "do I have notes on Y?"
- **Lint** — "check the wiki", "any inconsistencies?"
- **Daily entry** — share casual info ("met Jane today"), Claude appends to today's daily note
- **Living note** — "remember I prefer X", "update my grocery list"

Claude touches many files in one pass — updating an entity page also updates its backlinks, the index, and any concept pages that mention it.

## Obsidian

The vault is plain markdown — open this directory as an Obsidian vault for visual editing and graph view. Path-based wikilinks (`[[entities/services/foo]]`) work in both Obsidian and `rg`.
