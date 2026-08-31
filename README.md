# boilerplate

Personal boilerplate for new projects: a pnpm + Turborepo monorepo where packages
can either live directly in the repo or be attached as git submodules, opt-in per
package, when a package needs its own independently-maintained repo.

- [`docs/monorepo.md`](docs/monorepo.md) — architecture and how to add a package
- [`docs/submodules.md`](docs/submodules.md) — the submodule workflow, public vs.
  private, and the one Turborepo caveat (`turbo prune`) worth knowing about
- [`docs/roadmap.md`](docs/roadmap.md) — what changes if/when a non-JS package
  needs to be added

## Packages

- [`packages/issue-bot`](https://github.com/dfadler/issue-bot) — GitHub Action, TypeScript
- [`packages/payload-plugin-mermaid`](https://github.com/dfadler/payload-plugin-mermaid) — Payload CMS plugin, TypeScript
- [`tooling/agent-config`](https://github.com/dfadler/agent-config) — Claude Code agent config, Shell/Python (vendored only, not a workspace package — see [`tooling/README.md`](tooling/README.md))

## Quick start

```bash
git clone --recurse-submodules git@github.com:dfadler/boilerplate.git
cd boilerplate
pnpm install
pnpm build
```
