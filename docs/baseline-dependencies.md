# Baseline dependencies for web projects

This is guidance, not enforcement — nothing here is installed in this repo or
checked by CI. It's a starting point for what to reach for when scaffolding a new
web project from this template, distilled from patterns that have held up in
production. Deviate when a project's actual requirements call for it.

Two layers, kept separate on purpose: the **dev/build baseline** applies to every
project this template produces; the **product baseline** is a menu to pick from
depending on what the project actually is (a full-stack content-backed app, a static
site, a library, etc.) — not a fixed dependency list every project should install.

## Dev / build baseline

Already what this repo provides or assumes — see
[`monorepo.md`](monorepo.md) for the full architecture:

- **Package manager:** pnpm workspaces, version pinned via `packageManager` in the
  root `package.json` so `corepack` resolves consistently.
- **Task runner:** Turborepo, for dependency-graph-aware `build`/`lint`/`test`/
  `typecheck` across packages.
- **Language:** TypeScript in strict mode (`tsconfig.base.json`).
- **Lint:** oxlint (root `.oxlintrc.json`) over ESLint — faster, single binary, no
  plugin sprawl to maintain.
- **Bundler for library packages:** esbuild, for anything under `packages/*` that
  needs to ship compiled output.
- **CI:** the reusable workflow (`reusable-ci.yml`) other repos can call directly
  instead of copying pipeline YAML.

One nuance worth calling out explicitly: if a project's product baseline includes a
framework with its own bundler (Next.js's Turbopack, for example), that framework's
bundler handles the app itself — esbuild's role stays scoped to standalone library
packages in `packages/*`, not the app's own build. The two aren't in competition;
they operate at different layers.

## Product baseline (pick what applies)

None of this is a default install — it's what to reach for *when the project needs
that capability*, based on combinations that have proven solid rather than
guesswork:

- **Framework:** Next.js (App Router) + React, for anything that's a full-stack app
  rather than a pure static site or a library.
- **CMS / structured content:** when a project needs an admin-editable content model
  rather than hardcoded content, a code-first headless CMS that lives in the same
  repo as the app (schema-as-code, versioned with everything else) over a
  separately-hosted SaaS CMS — keeps content modeling in the same PR review flow as
  the code that renders it.
- **Rich text:** whatever editor the chosen CMS ships by default, rather than
  bolting on a second rich-text library.
- **Styling:** plain CSS Modules by default. Reach for a utility-class framework or
  a component library only when a project's design surface actually justifies the
  extra dependency weight — don't default to one.
- **Diagrams / generated visual content embedded in content:** prefer a
  server-rendered-to-static-asset approach (e.g. rendering to SVG at build/request
  time) over shipping a client-side rendering library — keeps the content's runtime
  JS footprint at zero regardless of how much of it uses diagrams.
- **Object/media storage:** cloud blob storage over storing binary assets in the
  database or the repo.
- **Error monitoring:** wire in a Sentry-protocol-compatible error monitor (self-
  hosted or hosted) at project setup, not as an afterthought once something breaks
  in production.
- **Hosting:** a platform with first-class preview deployments per-PR/branch —
  catching a regression in a preview before merge is worth more than saving the
  platform fee.

## AI-assisted workflow

Treat AI pair-programming tools (an editor-integrated assistant, an agentic CLI) as
a normal part of the dev workflow, not a special case to design around — but keep
the actual engineering discipline (tests written before or alongside the change,
spec/acceptance-criteria written down before implementation starts) as the thing
that makes that workflow trustworthy, not optional because an assistant wrote the
first draft.
