# Features

This directory stores feature plans for meaningful changes to this repo.

These files are intended to be living documents:

- create a plan before implementation starts
- refine it as requirements or design decisions change
- use it as a checklist while iteratively implementing the work
- keep enough context in the file for effective AI-human collaboration over time

## Filename format

Use:

`YYYYMMDD-short-kebab-summary.md`

Examples:

- `20260514-rearchitecture.md`
- `20260520-zsh-migration.md`
- `20260602-shell-smoke-tests.md`

Guidelines:

- `YYYYMMDD` is the date the feature plan is created
- the suffix should be short, descriptive, and stable
- prefer one feature plan per substantial change
- update the existing plan instead of creating a new one when the work is the same project

## Suggested structure

Most plans should include:

1. problem statement and goals
2. non-goals / scope boundaries
3. proposed design
4. phased implementation plan
5. risks and open questions
6. validation or testing strategy
7. checklist for iterative implementation

The goal is not perfect documentation up front; it is to keep a durable plan that can guide several implementation sessions without losing context.
