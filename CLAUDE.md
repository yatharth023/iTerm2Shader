# CLAUDE.md — Implementation Rules

## Purpose

This repository is for a macOS terminal-background shader engine built with Swift, Metal, and Homebrew distribution.

Claude must use this file as the primary implementation contract.

## Primary rule

Before making implementation changes, read `PRD.md` in the repository root and treat it as the source of truth for product behavior, scope, and acceptance criteria.

Do not deviate from the PRD.

If a requested change conflicts with the PRD, stop and report the conflict instead of improvising.

## Anti-hallucination rules

1. Only use information present in the repository, the PRD, the codebase, or the current task.
2. Do not invent APIs, files, shaders, classes, or behavior that are not supported by the repository context.
3. If a detail is missing, ask for clarification or state that it is unknown.
4. Do not “fill in” missing product behavior with assumptions.
5. Prefer explicit minimal behavior over vague general behavior.
6. When uncertain, say so clearly.

## Product priorities

1. Terminal readability.
2. Correctness.
3. Performance.
4. Visual quality.
5. Implementation simplicity.

## Architecture rules

The project must stay split into these layers:
- App layer
- Rendering layer
- Preset layer
- Packaging layer

Do not blur these responsibilities.

## Swift rules

- Keep app logic in Swift.
- Keep configuration, state, and UI concerns out of shader code.
- Use clear type names.
- Avoid overengineering.
- Prefer small, composable structs and enums.

## Metal rules

- Use Metal for rendering and shader execution.
- Keep shader logic deterministic and easy to reason about.
- Favor procedural effects over heavy asset pipelines.
- Minimize per-frame allocations.
- Reuse GPU resources where possible.
- Keep passes simple unless complexity is required by the PRD.

## Preset rules

Every preset must:
- implement the same shared interface,
- use the same configuration model shape,
- preserve readability constraints,
- support time-driven motion,
- optionally support typing reactivity.

Do not create one-off preset behavior that breaks the shared architecture.

## Typing reaction rules

Typing reaction must be:
- subtle,
- physically believable,
- low impact on performance,
- non-distracting,
- safe for readability.

Do not make typing effects flashy or aggressive.

## Visual rules

- Keep contrast low.
- Keep the center of the screen calm by default.
- Avoid bright clutter behind text.
- Maintain a premium, cinematic feel.
- Do not add visual noise just to make output look “cool.”

## Performance rules

- Keep the render loop efficient.
- Avoid unnecessary redraws.
- Avoid unnecessary state churn.
- Reuse buffers, textures, and objects.
- Profile before optimizing.
- Treat battery usage as important.

## File organization rules

Use a clean and predictable structure.

Recommended layout:
- `App/`
- `Rendering/`
- `Presets/`
- `UI/`
- `Packaging/`
- `Docs/`

Do not place unrelated code in these directories.

## Preset implementation rules

Each preset should live in its own file or module.

Suggested preset files:
- `SpaceflightPreset`
- `NightSkyFlightPreset`
- `MorningSkyFlightPreset`
- `OceanWaveFlightPreset`
- `AuroraDriftPreset`

Do not merge preset logic into one giant file unless there is a clear technical reason.

## Configuration rules

Only support the approved parameters:
- intensity
- speed
- depth
- contrast
- color temperature
- glow
- typing-reactivity strength

Do not add unrelated settings in version 1.

## Packaging rules

Homebrew packaging must be treated as a first-class part of the project.

Requirements:
- provide install path,
- provide update path,
- provide uninstall guidance,
- keep release versioning explicit,
- keep tap formula stable.

## Work process rules

When implementing:
1. Read the relevant files first.
2. Make the smallest correct change.
3. Keep diffs focused.
4. Update docs when behavior changes.
5. Validate the result.
6. Do not do unrelated refactors.

## Response rules for Claude

When responding during implementation:
- be concise,
- state only verified facts,
- separate assumptions from facts,
- ask clarifying questions if needed,
- do not present guesses as decisions.

## Completion criteria

A task is complete only when:
- it compiles or is otherwise validated,
- The implementation matches `PRD.md` in the repository root.
- it preserves readability,
- it does not introduce unnecessary complexity,
- and the implementation is clean.

## Important behavior constraint

If a task cannot be done cleanly within the current architecture, stop and explain the issue instead of forcing a broken workaround.