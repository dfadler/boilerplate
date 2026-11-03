# github/

Assets in this repo meant for **other** repos to consume — as opposed to `.github/`,
which is what this repo needs to run itself (its own CI, and the reusable workflows
GitHub requires to live in `.github/workflows/`).

- **`actions/`** — composite actions (`action.yml`), referenced from a consuming repo as:

  ```yaml
  uses: dfadler/boilerplate/github/actions/<name>@main
  ```

  `reusable-ci.yml` itself pins these to a specific commit SHA rather than `@main`
  (a mutable ref would let a later push to main change this repo's own CI without
  review) — see the pinned `uses:` lines in that file and each action's own header
  comment. A consuming repo can do the same for the same reason, at the cost of not
  picking up action changes until the pin is bumped.

  Currently ships:
  - `actions/install-shellcheck` — used by `reusable-ci.yml`'s `actionlint` job.
  - `actions/setup-pnpm-node` — pnpm + Node.js + frozen-lockfile install, used by
    `reusable-ci.yml`'s `build`, `deadcode`, `security-audit`, and `format` jobs.

- **`templates/`** — files a new repo copies in rather than references live (a starting
  PR template, `dependabot.yml`, etc.). Copy, don't symlink or submodule — a template is
  a starting point a project is expected to diverge from.

  Currently ships:
  - `templates/dependabot.yml` — weekly, grouped, 7-day cooldown; copy to `.github/dependabot.yml`.
  - `templates/PULL_REQUEST_TEMPLATE.md` — copy to `.github/PULL_REQUEST_TEMPLATE.md`.

Reusable **workflows** (`reusable-ci.yml` and any future ones) are the one exception:
GitHub requires them to live directly in `.github/workflows/`, with no subdirectories
([docs](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)) —
so they stay there, distinguished from this repo's own workflows only by their
`reusable-` filename prefix.
