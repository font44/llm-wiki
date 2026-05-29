# Knowledge Base

A personal AI-managed knowledge base. You drop sources (PDFs, Office docs, images, audio, web pages) into `wiki/raw/` and talk to the AI in natural language. The AI files cleaned markdown into `wiki/ai-workspace/`, appends casual notes under `wiki/ai-workspace/log/<date>/`, and — during periodic lint passes — clusters recurring topics from the log into dedicated pages (projects, books, people, etc.). The whole `wiki/` tree is an Obsidian vault. Retrieval is via [qmd](https://github.com/tobi/qmd) hybrid search.

The full operating manual for the agent is in [`AGENTS.md`](./AGENTS.md).

## Layout

```
wiki/                 Obsidian vault root
  ai-workspace/         AI's only write scope
    sources/<date>/       one md page per ingested raw artifact
    log/<date>/           one md page per session, append-only stream
    living/               kept-current personal notes (about-me, preferences, etc.)
    <other>/              created by the AI during lint promotions (projects, books, people, …)
  raw/<date>/           immutable source artifacts (PDFs, docs, images, audio)
  <whatever>/           user-curated read-only context (AI may query, never modifies)
flake.nix             devShell pinning all tools
```

The AI creates everything under `ai-workspace/` itself; you don't pre-make folders or stubs there.

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

Drive everything in natural language. The AI recognizes four intents:

- **Ingest** — "ingest this PDF", "process foo.pdf", "I dropped a paper in wiki/raw/"
- **Query** — "what did I read about X?", "do I have notes on Y?"
- **Lint** — "check the wiki", "any patterns?" — runs structural checks AND clusters recurring log topics into proposed promotions; you approve per item
- **Default** — anything else you say is appended to today's log session under `wiki/ai-workspace/log/<date>/`
