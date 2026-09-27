# boilerplate

Personal template and shared-config source for new TypeScript/React projects —
pnpm + Turborepo, `oxlint`, `esbuild`. This repo doesn't vendor or orchestrate
other, independently-maintained projects; it's the thing _other_ repos start from
or pull config out of, never the other way around.

- [`docs/monorepo.md`](docs/monorepo.md) — the pnpm + Turborepo architecture and
  how to add a package
- [`docs/baseline-dependencies.md`](docs/baseline-dependencies.md) — recommended
  dev/build and product dependencies for a new web project started from this
  template
- [`docs/publishing-a-library.md`](docs/publishing-a-library.md) — versioning,
  npm publishing, and CI/tsconfig differences for a package meant to be published
  to npm rather than consumed only within this repo

## Using this as a template

This repo is a GitHub template — click **Use this template** on
[github.com/dfadler/boilerplate](https://github.com/dfadler/boilerplate) to get a
fresh, disconnected copy to start a new project from (the pnpm/Turborepo scaffold,
`tsconfig.base.json`, `.oxlintrc.json`, and the CI workflow — no ongoing link back
to this repo).

## Repo layout: `.github/` vs `github/`

- **`.github/`** — what this repo needs to run itself: its own CI (`ci.yml`,
  `issue-bot.yml`) and the reusable CI workflow other repos call
  (`reusable-ci.yml`) — GitHub requires reusable workflows to live directly in
  `.github/workflows/`, so that one file is the exception living here for a
  different repo's benefit, distinguished only by its `reusable-` prefix.
- **[`github/`](github/README.md)** — everything else meant for other repos to
  consume that isn't a workflow file: composite actions and copyable templates.

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

Two more jobs are opt-in (default off, so existing callers aren't broken) and need
nothing extra from the consuming repo — `actionlint` lints `.github/workflows/**`
with [actionlint](https://github.com/rhysd/actionlint) and shellcheck; `security-audit`
runs `pnpm audit --prod --audit-level=high` (allowlist an unfixable finding under
`auditConfig.ignoreGhsas` in the consuming repo's own `pnpm-workspace.yaml`):

```yaml
# .github/workflows/ci.yml
jobs:
  ci:
    uses: dfadler/boilerplate/.github/workflows/reusable-ci.yml@main
    with:
      actionlint: true
      security-audit: true
```

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
project's own structure. A few things worth knowing before doing that:

- By default knip does **not** flag unused exports on a package's entry file (its
  `main`/`exports` field) — those are treated as public API. For an internal-only
  package nothing outside the repo imports, set `"includeEntryExports": true` in
  that workspace's knip config, or dead exports on the entry file pass silently.
- A devDependency invoked only as a CLI via a script knip can't statically resolve
  (e.g. `oxlint`, run from each package's own `lint` script once a package defines
  one) reads as "unused" until something calls it. `knip.jsonc`'s
  `ignoreDependencies` already covers this for `oxlint`; add to it (with a comment
  saying why) rather than removing a dependency that's genuinely still needed.

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

PRs get an automated first-pass review from [CodeRabbit](https://coderabbit.ai),
configured in [.coderabbit.yaml](.coderabbit.yaml). It's a supplement to CI, not a
replacement — nothing here relaxes `pnpm build`/`lint`/`typecheck`/`test`.

```bash
git clone git@github.com:dfadler/boilerplate.git
cd boilerplate
pnpm install
pnpm build
```
