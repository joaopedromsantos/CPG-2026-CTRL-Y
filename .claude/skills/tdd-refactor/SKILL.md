---
name: tdd-refactor
description: Refactor code safely with tests-first workflow, behavior preservation, scoped file moves, naming cleanup, and post-refactor verification. Use when Codex is asked to refactor a module/file/class, split responsibilities into new files or folders, rename public/internal APIs, migrate references, or add regression tests before changing implementation.
---

# TDD Refactor

## Core Workflow

Use a tests-first refactor loop. Preserve behavior unless the user explicitly asks for functional changes.

1. Inspect the current implementation and all call sites before editing.
2. Identify public API, file references, runtime entrypoints, and behavior that must remain stable.
3. Write focused regression tests before the refactor. Include success and failure cases.
4. Run the tests and confirm the expected failure when tests target the new shape or missing abstractions.
5. Refactor in small steps until tests pass.
6. Search for stale names, stale paths, old class names, and dead wrapper files.
7. Run the relevant test/build/check command again and report warnings separately from failures.

## Refactor Rules

- Keep the change scoped to the requested module/context.
- Split by responsibility, not by arbitrary size. Common buckets: controller/orchestrator, domain logic, drawing/rendering, data access, adapters.
- Preserve existing data shapes, item structures, metadata keys, scene node names, serialized paths, and external contracts unless the user requested those changes.
- Rename variables/classes to the requested language or naming convention, but update all call sites in the same refactor.
- Do not optimize, redesign, or clean unrelated code during a behavior-preserving refactor.
- Avoid adding abstractions unless the split removes a real mixed responsibility or is required by the user.
- Prefer moving code over rewriting code. Keep formulas, constants, condition order, and side effects recognizable.

## Test Design

Choose the existing project test framework when available. If none exists, add the smallest project-appropriate test harness or framework only after checking local conventions.

Cover at minimum:

- construction/setup/reset behavior;
- the main success path;
- representative error/failure paths;
- edge cases created by the refactor boundary;
- integration between the old caller and the new class/file names;
- any public signal/event/callback/API behavior.

For engine/framework code, account for lifecycle semantics. Example: queued deletion may require waiting a frame before asserting child counts.

## Moving and Renaming

When moving a file into a new context folder:

- create the destination folder using the context name requested by the user;
- move the controller into the new folder if the user asked file references to point there;
- rename public class names and typed variables consistently;
- update explicit paths such as `preload`, `load`, scene references, docs, configs, and tests;
- remove the old source file only after references are updated;
- search for old symbols and old paths before finishing.

Suggested stale-reference searches:

```sh
rg -n "OldClass|old_file\.gd|_old_name|oldName|res://old/path" .
```

## Verification

Run the narrowest reliable verification first, then broaden if risk warrants it.

- Run the new tests.
- Run existing tests that touch the module.
- Run a syntax/build/editor import check when the framework supports it.
- For UI/game/engine work, launch the app or headless project load when practical.
- If verification cannot run, state the exact command that failed or was unavailable.

## Completion Report

Keep the final report short and concrete:

- what was split or renamed;
- where the new files/tests live;
- what references were updated;
- the exact verification result;
- any unrelated warnings or residual risks.
