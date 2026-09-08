# boilerplate

Personal template and shared-config source for new TypeScript/React projects —
pnpm + Turborepo, `oxlint`, `esbuild`. This repo doesn't vendor or orchestrate
other, independently-maintained projects; it's the thing *other* repos start from
or pull config out of, never the other way around.

- [`docs/monorepo.md`](docs/monorepo.md) — the pnpm + Turborepo architecture and
  how to add a package

## Using this as a template

This repo is a GitHub template — click **Use this template** on
[github.com/dfadler/boilerplate](https://github.com/dfadler/boilerplate) to get a
fresh, disconnected copy to start a new project from (the pnpm/Turborepo scaffold,
`tsconfig.base.json`, `.oxlintrc.json`, and the CI workflow — no ongoing link back
to this repo).

## Consuming shared config from an existing repo

No config here is published to npm. An existing repo picks up `tsconfig.base.json`
and `.oxlintrc.json` by attaching this repo as a submodule and extending from it:

```bash
git submodule add https://github.com/dfadler/boilerplate.git .boilerplate
```

```jsonc
// tsconfig.json
{ "extends": "./.boilerplate/tsconfig.base.json" }
```

```jsonc
// .oxlintrc.json
{ "extends": ["./.boilerplate/.oxlintrc.json"] }
```

For CI, no submodule needed — reference the reusable workflow directly:

```yaml
# .github/workflows/ci.yml
jobs:
  ci:
    uses: dfadler/boilerplate/.github/workflows/reusable-ci.yml@main
```

It assumes a pnpm workspace with `build`/`lint`/`typecheck`/`test` scripts at the
consuming repo's root (stub any that don't apply). This repo's own `ci.yml` calls
the same reusable workflow, so it's exercised on every PR here too.

## Finding dead code in a project built from this template

A fresh template copy already has [`knip`](https://knip.dev) as a dev dependency,
a root `knip.jsonc`, and a `pnpm deadcode` script — run it directly (it's not
routed through Turborepo like `build`/`lint`/etc., since knip needs a whole-workspace
view to trace usage across packages, not a per-package one):

```bash
pnpm deadcode
```

Unlike `tsconfig.base.json`/`.oxlintrc.json`, knip has no `extends` mechanism, so an
existing repo on the submodule path can't inherit `knip.jsonc` directly — copy
`knip.jsonc` from this repo as a starting point instead and adjust it for the
project's own structure (see [`docs/monorepo.md`](docs/monorepo.md#dead-code-detection)
for what to watch out for, e.g. entry-point exports aren't flagged by default).

Once a `deadcode` script exists, opt the CI job in (it's off by default so repos
without the script aren't broken by it):

```yaml
# .github/workflows/ci.yml
jobs:
  ci:
    uses: dfadler/boilerplate/.github/workflows/reusable-ci.yml@main
    with:
      deadcode: true
```

## Developing this repo

```bash
git clone git@github.com:dfadler/boilerplate.git
cd boilerplate
pnpm install
pnpm build
```
