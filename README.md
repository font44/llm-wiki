# Knowledge Base

A personal AI-managed knowledge base. Drop sources (PDFs, Office docs, images, audio, web pages) into `wiki/raw/` and talk to the AI in natural language. The AI files cleaned markdown into `wiki/ai-workspace/`, appends casual notes to `wiki/ai-workspace/log/<date>/`, and — during periodic lint passes — clusters recurring log topics into dedicated pages (projects, books, people, etc.). The whole `wiki/` tree is an Obsidian vault; retrieval is via [qmd](https://github.com/tobi/qmd) hybrid search.

The agent's operating manual is [`AGENTS.md`](./AGENTS.md).

## Layout

```
wiki/                 Obsidian vault root
  ai-workspace/         AI's only write scope
    sources/<date>/       one md page per ingested raw artifact
    log/<date>/           one md page per session, append-only stream
    living/               kept-current personal notes (about-me, preferences, etc.)
    <other>/              created by the AI during lint promotions (projects, books, people, …)
  raw/<date>/           immutable source artifacts
  <whatever>/           user-curated read-only context (AI may query, never modifies)
flake.nix             devShell pinning all tools
```

You don't pre-make folders under `ai-workspace/`; the AI creates them.

## Wiki vault

`wiki/` is a **separate git repo**, deliberately decoupled from this project. This lets you reuse the project against multiple vaults and version your notes on their own cadence.

Clone the vault on a fresh machine:

```sh
git clone ssh://URI wiki
```

## Bootstrap (fresh machine)

```sh
cd /path/to/this/repo

# 1. devShell — pulls qmd, agent-browser, defuddle, node
direnv allow              # or: nix develop

# 2. Restore the bundled skills from skills-lock.json (committed)
#    Files land in .agents/skills/<name>/
npx -y skills experimental_install

# 3. (Claude Code only) symlink skills into .claude/ so Claude Code discovers them
ln -s ../.agents/skills .claude/skills

# 4. Initialize the qmd index (one-time per machine)
qmd init
qmd collection add wiki
qmd embed                 # downloads models on first run (~600 MB)

# 5. Download the Whisper turbo model for audio ingest (~1.5 GiB)
mkdir -p .models
bash <(curl -sL https://raw.githubusercontent.com/ggml-org/whisper.cpp/refs/heads/master/models/download-ggml-model.sh) large-v3-turbo .models
```

## Usage

Drive everything in natural language. The AI recognizes:

- **Ingest** — "ingest this PDF", "process foo.pdf", "I dropped a paper in wiki/raw/"
- **Query** — "what did I read about X?", "do I have notes on Y?"
- **Web research** — "look up X", "research Y" — drives your running Chrome, persists the answer to the log
- **Lint** — "check the wiki", "any patterns?" — runs structural checks and clusters recurring log topics into proposed promotions; you approve per item
- **Default** — anything else gets appended to today's log session under `wiki/ai-workspace/log/<date>/`
