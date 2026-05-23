# Knowledge Base

A personal AI-managed knowledge base. You drop sources (PDFs, images, web pages) into `raw/` and talk to the AI in natural language. The AI files cleaned markdown into `wiki/`, appends casual notes to `wiki/log.md`, and — during periodic lint passes — clusters recurring topics from the log into dedicated pages (projects, books, people, etc.). Retrieval is via [qmd](https://github.com/tobi/qmd) hybrid search.

The full operating manual for the agent is in [`AGENTS.md`](./AGENTS.md).

## Layout

```
raw/        immutable source artifacts (PDFs, images, web)
wiki/       LLM-managed markdown
  log.md       append-only stream of everything you say
  living/      kept-current personal notes (about-me, preferences, etc.)
  sources/     one md page per ingested raw artifact
  <other>/     created by the AI during lint promotions (projects, books, people, …)
.codex/     Codex config (project-local CODEX_HOME — config.toml + runtime state)
flake.nix   devShell pinning all tools
```

You don't create folders or stub files. The AI does.

## Bootstrap (fresh machine)

```sh
cd /path/to/this/repo

# 1. devShell — pulls codex, qmd, agent-browser, defuddle, node
direnv allow              # or: nix develop
                          # .envrc points CODEX_HOME at $PWD/.codex

# 2. Restore the bundled skills from skills-lock.json (committed)
#    Files land in .agents/skills/<name>/, which Codex auto-discovers
npx -y skills experimental_install

# 3. Initialize the qmd index (one-time per machine)
qmd init
qmd collection add wiki
qmd embed                 # downloads models on first run (~600 MB)

# 4. Open Codex in the vault (uses local LM Studio via .codex/config.toml)
codex
```

LM Studio must be running with `qwen/qwen3.6-35b-a3b` loaded at `http://localhost:1234`.

## Usage

Drive everything in natural language. The AI recognizes four intents:

- **Ingest** — "ingest this PDF", "process foo.pdf", "I dropped a paper in raw/"
- **Query** — "what did I read about X?", "do I have notes on Y?"
- **Lint** — "check the wiki", "any patterns?" — runs structural checks AND clusters recurring `log.md` topics into proposed promotions; you approve per item
- **Default** — anything else you say is appended to `log.md` as a timestamped entry
