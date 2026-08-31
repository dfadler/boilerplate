# tooling/

Vendored config/tooling repos that aren't buildable JS/TS packages — no
`package.json`, nothing for pnpm or Turborepo to discover. They're attached as git
submodules purely to be version-pinned and reachable from this repo, same mechanics
as [`packages/`](../packages/)'s submodules (see
[`docs/submodules.md`](../docs/submodules.md) for add/clone/update commands), but
deliberately **outside** the `packages/*` workspace glob so they never enter the
pnpm/Turborepo graph.

## Current entries

- **[`agent-config`](agent-config)** — submodule, [github.com/dfadler/agent-config](https://github.com/dfadler/agent-config).
  Shell/Python, not JS/TS — Claude Code agent configuration (global `CLAUDE.md`, the
  `dfadler-agent-config` plugin), installed via its own `setup.sh`/`Makefile`. Vendored
  here for version pinning; not wired into any task pipeline in this repo.
