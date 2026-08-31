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
   that don't apply yet) — `turbo.json`'s task graph expects every package to define
   what it can.
3. `pnpm install` from the repo root to link it into the workspace.
4. `pnpm build` (or `turbo run build --filter=<package-name>`) to confirm it's wired
   up correctly.

A submodule with no `package.json` at all (config/tooling, not a buildable
package) doesn't go under `packages/*` — see [`tooling/`](../tooling/README.md).

**Updating one afterward:** submodule packages are pins, not edit targets — changes
flow one way, from each submodule's own upstream repo into this one, never the other
direction. See [`submodules.md`](./submodules.md#change-direction-submodules-are-pins-not-edit-targets)
for why and the actual workflow.

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
find . -maxdepth 4 -name node_modules -not -path '*/tooling/*' -exec rm -rf {} +
pnpm install
```
