# Git submodules as packages

Submodules are **opt-in per package**, not the default. Most packages should stay
plain directories under `packages/*` — reach for a submodule only when a package
genuinely needs to be its own independently-versioned or independently-shared repo
(e.g. it's also consumed outside this monorepo, or maintained by a different set of
collaborators).

## Adding a submodule package

```bash
# public repo
git submodule add https://github.com/<owner>/<repo>.git packages/<name>

# private repo — use SSH so both local dev and CI can auth via a deploy key
git submodule add git@github.com:<owner>/<repo>.git packages/<name>
```

The submodule still needs a `package.json` at its root (or a subpath mapped via the
workspace glob) to be picked up by pnpm/Turborepo — same requirement as any other
package. If the upstream repo doesn't already have one, that's a sign it isn't
actually ready to be a workspace package yet.

## Cloning / updating this repo

```bash
git clone --recurse-submodules git@github.com:dfadler/boilerplate.git
# or, after a normal clone:
git submodule update --init --recursive
```

Pulling `main` later doesn't auto-update submodule contents — run
`git submodule update --init --recursive` again after any pull that touched
`.gitmodules` or bumped a submodule's pinned commit.

## Public vs. private submodules

Turborepo's task running and caching don't care whether a submodule's origin is
public or private — both are just a directory on disk to it. The difference is
entirely at **checkout time**:

- **Public** submodules clone anonymously — nothing extra to configure.
- **Private** submodules need credentials wired into whatever's doing the checkout:
  an SSH deploy key for local dev, and (in CI) either a deploy key added as a secret
  or a PAT with access to the private repo, passed to `actions/checkout`'s
  `submodules: recursive` + `ssh-key`/`token` inputs (or the equivalent for
  whichever CI runs this repo).

## The `turbo prune` caveat

Turborepo's caching hashes files by shelling out to git. Historically that hashing
path broke at a submodule boundary — [vercel/turborepo#5485](https://github.com/vercel/turborepo/issues/5485)
and [#5521](https://github.com/vercel/turborepo/issues/5521) (both filed against
1.10.7) show `git ls-tree`/hashing erroring out with `fatal: not a git repository`
when it crossed into a submodule's own `.git/modules/...` directory. Both were fixed
in 1.10.9, which added a fallback to manual (non-git) file hashing whenever the git
path errors — so a plain `turbo run <task>` no longer hard-crashes on a repo with
submodules.

`turbo prune` — used to produce a slimmed-down subset of the monorepo for CI/Docker
builds — was the specific command that crashed in those issues, and there's no
confirmation since that it's been re-verified as solid against submodule packages.
Turborepo's own docs don't mention submodules at all, in either direction.

**Until it's actually exercised against a submodule package in this repo, treat
`turbo prune` as untested here** — don't wire it into CI for a submodule-containing
filter without first confirming it works against the current Turborepo version.
Plain `turbo run build`/`lint`/`test`/`typecheck` are fine.
