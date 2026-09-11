# packages/

Every directory here is a pnpm workspace package matched by `packages/*` in
[`pnpm-workspace.yaml`](../pnpm-workspace.yaml); Turborepo (`turbo.json`) discovers
and orders tasks across them via each package's `package.json`.

This is currently empty. Packages here belong to _this_ repo — either something
this template repo maintains and ships as part of itself, or a package you add
locally after scaffolding a new project from this template. This repo does not
vendor other, independently-maintained projects as submodules under `packages/*`
(see the root [`README.md`](../README.md) for what this repo actually is and how
other repos are meant to consume it instead).

Every package here needs a `package.json` with `build`/`lint`/`test`/`typecheck`
scripts (stub any that don't apply) — that's what makes it a valid Turborepo
package.
