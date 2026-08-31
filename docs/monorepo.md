# Monorepo architecture

## Stack

- **Package manager:** pnpm workspaces (`pnpm-workspace.yaml`), pinned via the root
  `package.json`'s `packageManager` field so `corepack` resolves the same version
  everywhere.
- **Task runner:** [Turborepo](https://turborepo.dev) (`turbo.json`). It walks the
  workspace's `package.json` dependency graph and runs the declared task (`build`,
  `lint`, `test`, `typecheck`, ...) in the right order, in parallel where possible,
  with local caching.
- **Language:** TypeScript-first (`tsconfig.base.json`) to start. See
  [`roadmap.md`](./roadmap.md) for what changes if/when a non-JS package shows up.

## Why Turborepo specifically

Turborepo doesn't have a concept of "package" beyond "a directory with a
`package.json` matched by the workspace glob." It doesn't inspect *how* that
directory got there — a package checked directly into this repo and a package that's
a git submodule checkout look identical to it. That's what makes opt-in submodule
packages (see [`submodules.md`](./submodules.md)) workable without a custom runner.

The one caveat: Turborepo's caching hashes files by shelling out to git, and older
versions of that hashing path didn't understand a nested submodule `.git` boundary
(fixed upstream in 1.10.9 via a fallback to manual hashing — see
[`submodules.md`](./submodules.md) for the specific issues and the one command,
`turbo prune`, that isn't yet proven safe with submodules in this repo).

## Adding a package

1. Create `packages/<name>/` (or attach a submodule there — see
   [`submodules.md`](./submodules.md)).
2. Give it a `package.json` with a `build`/`lint`/`test`/`typecheck` script (stub any
   that don't apply yet, matching `example-lib`'s pattern) — `turbo.json`'s task
   graph expects every package to define what it can.
3. `pnpm install` from the repo root to link it into the workspace.
4. `pnpm build` (or `turbo run build --filter=<package-name>`) to confirm it's wired
   up correctly.
