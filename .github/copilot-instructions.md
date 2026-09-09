# Copilot Instructions — Slate

## Project state

This repository is a **greenfield, early-bootstrap project**. As of now there is no build
system, no packages, no source tree, and no tests. Do not assume any conventional
project layout, build tooling, or architecture exists — check the actual repo contents
before relying on anything described elsewhere (including in this file's older
revisions) as still accurate.

When you add the first real code, build steps, or tests, **update this file** with:
- the actual build/test/lint commands (including how to run a single test)
- the real directory layout and how the pieces fit together
- any conventions that emerge (packaging format, scripting language, config layout, etc.)

## What this project is

Slate is an opinionated, **Arch-based Linux distro** built as an **Agentic OS** — a
system designed around agent-driven workflows rather than traditional interactive-only
use. Expect eventual work with Arch packaging conventions (PKGBUILDs, pacman, archiso)
alongside whatever agent-facing tooling gets built on top.

## Guiding pillars (apply to every decision, including tooling choices)

- **Reliable** — predictable behavior, well-understood failure modes.
- **Blazing fast** — boot time, package operations, and agent workflows are actively
  optimized, not left "good enough."
- **Best in class** — pick the strongest available tool/approach for a job, not the
  most familiar or convenient one.
- **Well crafted** — no half-finished decisions; if something is added, it's done
  properly.
- **Every tool must earn its keep** — the strongest constraint on this project. Don't
  add a dependency, script, abstraction, CI job, or linter unless it provides ongoing,
  clear value. When in doubt, leave it out. This also means: don't scaffold structure,
  tooling, or process speculatively — add it when a real need forces the issue.

## Working in this repo right now

- There is nothing to build, test, or lint yet — don't invent commands or config for
  tooling that doesn't exist.
- Because of the "earn its keep" pillar, resist the urge to add conventional
  boilerplate (CI pipelines, linters, elaborate directory scaffolding) preemptively.
  Wait until a concrete need justifies it, and prefer the minimal version that
  satisfies that need.
- Since this is an Arch-based distro, when packaging work begins, prefer idiomatic
  Arch/archiso conventions (PKGBUILDs, `makepkg`, `archiso` profiles) over inventing
  custom packaging formats, unless a custom approach is demonstrably better and earns
  its keep.
