# Monorepo architecture

## Stack

- **Package manager:** pnpm workspaces (`pnpm-workspace.yaml`), pinned via the root
  `package.json`'s `packageManager` field so `corepack` resolves the same version
  everywhere.
- **Task runner:** [Turborepo](https://turborepo.dev) (`turbo.json`). It walks the
  workspace's `package.json` dependency graph and runs the declared task (`build`,
  `lint`, `test`, `typecheck`, ...) in the right order, in parallel where possible,
  with local caching.
- **Language:** TypeScript, React, CSS, HTML. Lint via `oxlint` (root
  `.oxlintrc.json`), bundle via `esbuild` where a package needs one.

This repo doesn't vendor other, independently-maintained projects as workspace
packages — see the root [`README.md`](../README.md) for what this repo actually is
(a template + a source of shared config other repos reference) and how another repo
is meant to consume it.

## Adding a package

1. Create `packages/<name>/`.
2. Give it a `package.json` with a `build`/`lint`/`test`/`typecheck` script (stub any
   that don't apply yet) — `turbo.json`'s task graph expects every package to define
   what it can.
3. `pnpm install` from the repo root to link it into the workspace.
4. `pnpm build` (or `turbo run build --filter=<package-name>`) to confirm it's wired
   up correctly.

## pnpm build-script approval

pnpm 11 blocks a dependency's install/postinstall scripts by default
(`ERR_PNPM_IGNORED_BUILDS`) unless explicitly allowed. If a package you add depends
on something that needs a native build step at install time (e.g. `esbuild`,
which replaces its own JS shim with a platform-specific binary on install), approve
it declaratively in [`pnpm-workspace.yaml`](../pnpm-workspace.yaml)'s `allowBuilds`
map rather than running the interactive `pnpm approve-builds` — the declarative form
is reviewable in a diff and works the same in CI. Note: `onlyBuiltDependencies` in
`package.json`'s `pnpm` field is pnpm ≤10 syntax; pnpm 11 only reads `allowBuilds`
from `pnpm-workspace.yaml`.

If a dependency's postinstall script isn't safe to run twice (esbuild's is a known
example — a second run corrupts the platform binary it already swapped in), a
build-approval change can require a clean `node_modules` reinstall rather than a
second `pnpm install` on top of a half-run one:

```bash
rm -rf node_modules packages/*/node_modules
pnpm install
```
