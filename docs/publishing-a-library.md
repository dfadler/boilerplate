# Publishing a library to npm

Guidance, not enforcement — like [`baseline-dependencies.md`](baseline-dependencies.md),
nothing here is installed or checked by CI in this repo itself. It's the pattern to
reach for when a project under this template is a **publishable library** (an npm
package other projects install) rather than an app — a materially different shape
than the monorepo-of-apps assumption the rest of this repo's docs make. Distilled
from two packages actually shipping this way: `payload-plugin-mermaid` (a single,
bundled package) and `zombie-mermaid` (a pnpm workspace of several published
packages).

## Versioning and releasing: Changesets

Use [Changesets](https://github.com/changesets/changesets)
(`@changesets/cli` + `@changesets/changelog-github`) to manage version bumps and
changelogs. A PR that changes shipped behavior adds a `.changeset/*.md` file
(`pnpm changeset add`) describing the bump; a release workflow later consumes all
pending changesets at once.

**Release workflow** — triggered on every push to `main`, using
[`changesets/action`](https://github.com/changesets/action):

- No pending changesets, nothing just merged → no-op.
- Pending changesets exist → opens/updates a "Version Packages" PR that bumps
  `package.json`/`CHANGELOG.md` from the pending changeset files.
- That Version PR gets merged → publishes to npm and tags the release.

```yaml
permissions:
  contents: write # changesets/action commits/pushes the Version PR and tags
  pull-requests: write # changesets/action opens/updates the Version PR
  id-token: write # required for npm trusted publishing (OIDC)

steps:
  # checkout (fetch-depth: 0), pnpm/node setup, install, test, typecheck …
  - uses: changesets/action@8488615a623b1b9c987934bb89eae8af6a946ac1 # v2.1.1
    with:
      version-script: pnpm changeset version
      publish-script: pnpm changeset publish
      create-github-releases: true
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      # No NPM_TOKEN / NODE_AUTH_TOKEN — see npm trusted publishing below.
```

Full working example: `payload-plugin-mermaid`'s
`.github/workflows/publish.yml`.

### npm trusted publishing (OIDC), not a token

Publish via npm's [trusted publishing](https://docs.npmjs.com/trusted-publishers)
(OIDC), not a long-lived `NPM_TOKEN` secret — nothing to rotate, nothing to leak.
Needs `id-token: write` on the publish job (above) plus a one-time trusted-publisher
link on npmjs.com scoped to this exact repo + workflow file. `changesets/action`'s
`publish-script` picks this up automatically once npm itself supports it
(`npm install -g npm@latest` right before the publish step, if the runner's
preinstalled npm predates trusted-publishing support).

### Require a changeset on every PR

Gate PRs on having a pending changeset, so a shipped-behavior change can't merge
without one:

```yaml
- run: pnpm changeset status --since origin/main
```

Exempt the release workflow's own "Version Packages" PR (it consumes changesets,
never adds one) — scope the exemption to the same-repo PR head ref, not just a branch
name match, so a fork can't spoof it. Full working example: `zombie-mermaid`'s
`ci.yml` `changeset` job.

## peerDependencies and bundler externals

Anything the _consumer_ also has its own copy of — a host framework (`payload`),
`react`/`react-dom`, anything that establishes module-singleton state (a React
context, in particular) — belongs in `peerDependencies`, not `dependencies`. A
bundled copy inside the package creates a second identity for that module; for
React specifically, that breaks any hook relying on context (`useField`,
`useFormFields`, etc.) the moment the consumer's copy doesn't reference-match the
package's own.

Mark those same packages external in the bundler config so the build never inlines
them. With [tsdown](https://tsdown.dev):

```ts
export default defineConfig({
  deps: {
    neverBundle: ["payload", "@payloadcms/ui", "react", "react-dom"],
  },
});
```

## tsconfig for a bundled library

The root [`tsconfig.base.json`](../tsconfig.base.json) assumes this repo's own
`packages/*` shape (`composite: true`, project-reference build graph). A
single-package library that ships bundled ESM output via tsdown/esbuild needs a
different shape instead of extending that base — `moduleResolution: "bundler"`,
`verbatimModuleSyntax: true`, `allowImportingTsExtensions: true`, no `composite`. See
`payload-plugin-mermaid`'s `tsconfig.json` for the full working config.

### Typecheck the emitted output too

Source-only `tsc --noEmit` can miss issues that only appear once the bundler emits
declaration files — most commonly literal-type widening (a `const` string/number
literal type collapsing to its base type across the `.d.ts` boundary). Add a second,
minimal tsconfig that typechecks `dist/*.d.ts` directly, and a `typecheck:dist`
script that runs it after `build`:

```jsonc
// dist-typecheck/tsconfig.json — deliberately minimal, points at emitted .d.ts only
{
  "compilerOptions": {
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
  },
  "include": ["../dist/**/*.d.ts"],
}
```

```jsonc
// package.json
"typecheck:dist": "tsc --noEmit -p dist-typecheck/tsconfig.json"
```

## Bundle-size budget gate

A small in-house script (not a new dependency like `size-limit`/`bundlewatch`) that
gzips each budgeted file in `dist/` via `node:zlib` and fails if any exceeds a budget
recorded in a checked-in JSON file. Raising a budget after a reviewed size increase
is a direct edit to that file — no separate "update" mode, so a size regression is
always a visible diff, not a silently regenerated snapshot. Full working example:
`zombie-mermaid`'s `scripts/check-bundle-size.ts` + `bundle-size-budget.json`.

## The fork-of-this-fork guard

A public, forkable repo's `push`/`schedule`-triggered workflows still fire inside
someone else's fork once they enable Actions there — using their own Actions
budget, and, for a publish workflow specifically, attempting (and failing) an npm
trusted-publish that leaves a stray "Version Packages" PR behind. Guard any workflow
that publishes, spends a paid/rate-limited API call, or otherwise assumes it's
running as the canonical repo:

```yaml
if: github.repository == 'dfadler/<this-repo>'
```

This is distinct from the fork-PR case GitHub Actions already restricts secrets for
— `github.repository` always resolves to the _base_ repo for a `pull_request` event
regardless of which fork the PR's head branch lives on, so this guard does nothing
for (and isn't needed against) an untrusted fork's PR. It only matters for
`push`/`schedule` events, which do run inside the fork's own copy of the workflow.
Most relevant here to the publish workflow (above) and to any opt-in `reusable-ci.yml`
job that spends a rate-limited external call (Semgrep, CodeQL) if the consuming repo
is itself public and forkable.
