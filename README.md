# Knowledge Base

A personal AI-managed knowledge base. Talk to the AI in natural language. When you explicitly ask it to log something, it writes to `wiki/ai-workspace/<date>/`. The whole `wiki/` tree is an Obsidian vault.

The agent's operating manual is [`AGENTS.md`](./AGENTS.md).

## Layout

```
wiki/                 Obsidian vault root
  ai-workspace/         AI's only write scope
    <date>/               one md page per session, append-only stream
  <whatever>/           user-curated read-only context (AI may read, never modifies)
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

# 1. devShell — pulls agent-browser, defuddle, node
direnv allow              # or: nix develop

# 2. Restore the bundled skills from skills-lock.json (committed)
#    Files land in .agents/skills/<name>/
npx -y skills experimental_install

# 3. (Claude Code only) symlink skills into .claude/ so Claude Code discovers them
ln -s ../.agents/skills .claude/skills
```

## Usage

Drive everything in natural language. The AI recognizes:

- **Web research** — "look up X", "research Y" — drives your running Chrome, returns a cited answer in chat
- **Log** — "log this", "save this" — appends the current thread to today's session under `wiki/ai-workspace/<date>/`. The AI never writes to the wiki on its own — you ask, it writes.
