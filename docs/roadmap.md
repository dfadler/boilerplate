# Roadmap: beyond JS/TS

This boilerplate starts JS/TS-only (pnpm workspaces + Turborepo) because that's the
immediate need, but it's expected to eventually host non-JS packages too — most
plausibly as submodules (a Go service, a Python tool, etc.), since those are exactly
the kind of package likely to want its own independently-maintained repo in the
first place.

## What plain Turborepo doesn't give you for non-JS packages

Turborepo's package *discovery* is tied to npm/pnpm/yarn/bun workspace conventions
(a `package.json` matched by the workspace glob). A non-JS package can still
participate — give it a minimal `package.json` whose scripts shell out to the real
toolchain (`"build": "go build ./..."`, `"test": "pytest"`, etc.) — but that's a
workaround, not first-class polyglot support. Turborepo's task graph and caching
still work fine once that thin `package.json` exists.

## Trigger condition to revisit the runner choice

Don't switch runners speculatively. Revisit once there's an **actual** non-JS
package to add, and only if the `package.json`-shim workaround above turns out to be
more friction than it's worth in practice (e.g. losing native caching for that
toolchain, or needing dependency-graph awareness Turborepo can't infer from a shim
script). At that point the live options are:

- **[Moonrepo](https://moonrepo.dev)** or **[Nx](https://nx.dev)** — both do
  dependency-graph-aware task orchestration without being tied to a single
  language's workspace format, so a Go or Python package can be first-class rather
  than shimmed.
- Keep Turborepo for the JS/TS packages and layer a thin top-level `Makefile`/`Just`
  file that fans out to `turbo` for JS and to each non-JS package's native tooling
  directly — cheaper to introduce than a runner migration, worth trying first.

Either way, the opt-in-submodule-per-package convention in
[`submodules.md`](./submodules.md) doesn't change — this is purely about how tasks
get *run*, not how packages get *attached*.
