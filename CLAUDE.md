# boilerplate

pnpm + Turborepo monorepo template and shared CI. See [`README.md`](README.md) and
[`docs/monorepo.md`](docs/monorepo.md) for what this repo is and how others consume it.

## Commands

- `pnpm install` — frozen-lockfile in CI; Node version is in `.nvmrc`
- `pnpm build` / `lint` / `typecheck` / `test` — run through Turborepo
- `pnpm format:check` (Prettier) and `pnpm deadcode` (knip)
- `pnpm lint:actions` — workflow concurrency / persist-credentials checks
- `pnpm lint:sh` — shellcheck + shfmt on `github/**/*.sh` (needs both installed)

## Rules

- Work in a git worktree for anything beyond a one-line edit; never commit to `main`.
- Before touching `.github/workflows/`, read the pinned-SHA and permissions comments
  in `reusable-ci.yml`. Pin every action by full commit SHA with a version comment;
  keep `permissions:` least-privilege and give every workflow a `concurrency:` key
  (or a `# concurrency: none — <reason>` opt-out).
- Don't weaken `pnpm-workspace.yaml` supply-chain settings without a comment saying why.
- Don't create or apply GitHub labels that the repo hasn't defined.
