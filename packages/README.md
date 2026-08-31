# packages/

Every directory here is a pnpm workspace package matched by `packages/*` in
[`pnpm-workspace.yaml`](../pnpm-workspace.yaml). Turborepo (via `turbo.json`) discovers
and orders tasks across them using each package's `package.json` — it does not care
whether a package directory is:

- a **plain directory** checked directly into this repo (the default), or
- a **git submodule** checkout pointing at its own independent repo (opt-in, per
  package — see [`docs/submodules.md`](../docs/submodules.md))

Add a package as a submodule only when it genuinely needs to be its own
independently-versioned, independently-shared, or independently-maintained repo.
Otherwise keep it as a plain directory — that's simpler to work with and has no
extra caveats.

Every package here must have a `package.json` with `build`/`lint`/`test`/`typecheck`
scripts (stub any that don't apply) — that's what makes it a valid Turborepo package.
A submodule with no `package.json` (config, tooling, non-JS) doesn't belong under
`packages/*` at all — see [`tooling/`](../tooling/) instead.

## Current packages

- **[`issue-bot`](issue-bot)** — submodule, [github.com/dfadler/issue-bot](https://github.com/dfadler/issue-bot)
- **[`payload-plugin-mermaid`](payload-plugin-mermaid)** — submodule, [github.com/dfadler/payload-plugin-mermaid](https://github.com/dfadler/payload-plugin-mermaid)
