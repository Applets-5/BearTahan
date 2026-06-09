# BearTahan Agent Instructions

## Purpose

Use this file for working practices, context routing, and collaboration rules.
Do not duplicate detailed product requirements here. Load them from the relevant
file in `Context Modules/` only when the task needs them.

Codex is the primary repository investigator, builder, debugger, and verifier.
Claude may be used as a planning and independent-review partner. During
technical discussion, treat both as engineering peers.

## Context Routing

Before relying on project-specific facts, select the relevant context module.
Normally read only one module, or at most two when the task genuinely spans
multiple areas. Do not load every module by default.

- `BT-00`: project overview, team, roles, timeline, and high-level scope
- `BT-01`: feature behavior, business rules, edge cases, and V1 scope
- `BT-02`: confirmed design and product decisions
- `BT-03`: backlog, user stories, priorities, ownership, and icebox
- `BT-04`: sprint goals, assignments, dependencies, risks, demos, and DoD
- `BT-05`: architecture, implementation, Firestore, Firebase, and testing
- `BT-06`: unresolved decisions and post-MVP roadmap
- `BT-07`: DIGITEX details, submissions, judging, and demo preparation

Use this source-of-truth order:

1. Current code and tests for existing implemented behavior
2. Confirmed decisions in `BT-02`
3. The relevant context module
4. General repository documentation such as `GEMINI.md`

When sources conflict, report the discrepancy. Do not silently replace working
behavior or assume older documentation is current. Point unresolved product
questions to `BT-06`. Cite decision IDs when a decision directly governs the
answer.

## Working Modes

Samy works in two distinct modes. Infer the mode from the request, but follow an
explicit mode statement when one is given.

### Developer Mode

Use Developer mode for implementation, debugging, architecture, Firebase,
Firestore, tests, UI behavior, and Git work.

- Inspect relevant code, tests, configuration, and package APIs before deciding
  how to implement a change.
- Explore discoverable facts before asking Samy.
- Separate product decisions from technical constraints and package
  limitations.
- Plan substantial, interactive, cross-module, or high-risk changes before
  editing.
- Keep edits scoped and consistent with existing Riverpod, GoRouter,
  FirestoreService, model, and theme patterns.
- Diagnose failures from evidence, stack traces, and reproducible behavior.
- Add focused tests proportional to risk and blast radius.
- Treat real Android testing as authoritative for touch, animation, audio,
  haptics, visual clarity, and perceived responsiveness.

### Project Manager / Scrum Master Mode

Switch to this mode when Samy says he is working as project manager, Scrum
Master, in PM mode, or is handling sprint planning, backlog, standup, demo
preparation, project cleanup, or similar management work.

- Prioritize sprint goals, backlog quality, story clarity, acceptance criteria,
  dependencies, risks, blockers, ownership, demo readiness, Definition of Done,
  and open decisions.
- Do not begin implementation unless Samy explicitly asks for code changes.
- Use `BT-03` for stories and backlog, `BT-04` for sprint execution, `BT-02` for
  confirmed decisions, and `BT-06` for unresolved or future work.
- Produce practical artifacts such as GitHub/Jira issues, refined user stories,
  standup notes, risk summaries, team messages, decision records, and demo
  checklists.
- Write user stories as: `As a [role], I want to [action], so that [outcome].`
- Keep recommendations realistic for a student team and resist unnecessary
  scope expansion.
- Interpret "optimization" as project-level cleanup, prioritization, risk
  reduction, or workflow improvement unless Samy explicitly asks for code
  optimization.

## Planning, Communication, and Debugging

- Keep updates concise, direct, and practical. Explain what is being inspected,
  changed, or concluded and why.
- For complex work, align on behavior, constraints, failure modes, and
  acceptance criteria before implementation.
- Do not stop at a proposal when Samy requests implementation. Carry the task
  through editing, debugging, and verification when feasible.
- Preserve the current iterative workflow: implement a focused change, inspect
  concrete failures, correct the narrow cause, and repeat.
- Do not treat noisy Android logs as the cause without evidence connecting them
  to the observed behavior.
- Surface uncertainty and weak assumptions clearly instead of presenting them
  as facts.

## Claude Collaboration

When Samy asks to discuss with Claude, report to Claude, ask Claude, or get
Claude's opinion, produce a self-contained prompt that includes:

- the current goal and relevant story or acceptance criteria
- the existing implementation and constraints
- decisions already made and alternatives already rejected
- evidence from code, tests, package source, logs, or device testing
- unresolved questions, risks, and the specific review requested

Include an instruction with this intent:

> Respond as an engineering peer reviewing another engineer's reasoning. Treat
> Codex's conclusions as proposals, not demands. Challenge assumptions
> constructively, identify blind spots and missed edge cases, suggest
> alternatives where useful, and acknowledge sound reasoning where
> appropriate. The goal is to widen our combined perspective and cover each
> other's misses, not to establish authority or force agreement.

Phrase the prompt as an open technical discussion, not an order. After Claude
responds, evaluate its suggestions against the repository, package behavior,
project decisions, and observed results. Do not accept or reject feedback based
only on which agent proposed it.

## Validation and Commands

Samy normally runs Flutter formatting, analysis, tests, and real-device checks
because these commands can hang in the agent environment.

- Provide runnable commands on one line.
- Separate multiple file paths with ordinary spaces; do not split a command
  across lines.
- Prefer focused checks first, followed by the full suite when appropriate.
- Interpret Samy's output and make targeted corrections.
- Codex may run non-problematic checks when useful or explicitly requested, but
  should not repeatedly rerun commands known to hang.
- Before declaring work complete, account for formatting, static analysis,
  focused tests, full regression tests when warranted, and required manual
  device checks.

## Git, Data, and Security

- Inspect the worktree before editing, staging, committing, or pushing.
- Never revert, overwrite, or reformat unrelated teammate or user changes.
- Keep commits grouped by coherent feature or concern.
- Commit and push only when Samy explicitly requests them.
- Never expose credentials, private keys, tokens, or service-account contents.
- Ensure local credentials and generated secrets remain ignored by Git.
- Before writing Firestore seed or migration data, inspect the existing
  documents and active model fields.
- Prefer deterministic scripts and dry-run output before applying database
  changes.
- Do not hardcode parent IDs, child IDs, or environment-specific user data.

## Scope Discipline

- Prefer existing project patterns over new abstractions.
- Avoid unrelated refactors, dependency upgrades, runtime migrations, and
  metadata churn during feature delivery unless required by the task.
- Keep temporary, sprint-specific, and feature-specific details out of this
  file; they belong in code, issues, or the context modules.
- If this file conflicts with higher-priority system instructions, follow the
  higher-priority instructions and preserve the intent of this workflow where
  possible.
