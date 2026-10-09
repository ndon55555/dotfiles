# Global preferences

These apply to every project. A project's own CLAUDE.md wins where they conflict.

## Communication
- Be direct and honest. Prioritize accuracy and conciseness over politeness if those ever conflict.
- Don't take everything I say as truth.
- Skip unnecessary acknowledgements like "I understand", "that's interesting", or "great observation".

## Technical decisions
- Prioritize quality, simplicity, robustness, scalability, and long-term maintainability over development cost.
- Do not surface development time/effort cost unless I ask for it. If cost is worth raising at all, it's monetary cost (e.g. infrastructure, hosting, API spend), not how long something takes to build.

## Changing shared contracts
- Before changing anything other code consumes, search every consumer across all apps and packages in the repo, not only the one being edited. That includes a widened union/GFK/polymorphic type, an FK or `on_delete`, a URL kwarg or pk, a serializer/API response shape, a persisted value (localStorage key, DB column, message payload), an exported type, markup that tests locate, a Docker target's CMD/USER/contents, and a settings key read by shared code. Update each consumer or add a regression test, and list the consumers checked in the summary.
- When adding one member of a family (env var, queue, Kafka topic, error enum value, feature flag, message field, environment/region config), find an existing sibling and add the new item everywhere that sibling appears (env samples, test env, CI, deploy YAML, egress rules, message/error specs, docs, changelog). Add a test that sets it.
- When a persisted value changes shape, bump the key, migrate, or validate on read. Never silently reuse the old key.

## Reuse before adding
- Before writing a helper, enum, constant, type, formatter, fixture, page object, exception class, or concurrency primitive, search the repo for an existing one and use it. Extend the existing implementation rather than adding a parallel one beside it.
- Check the project's pinned version of a library before using its API (e.g. pydantic v1 vs v2, boto3).

## No speculative surface
- Don't add parameters, props, options, flags, base classes, CLI flags, or TODOs for needs nobody has stated. Use language builtins (`NaN`, `Symbol`, enums) before inventing sentinel types.
- Don't guard against states that would mean an upstream bug; raise the module's domain exception or assert. Don't add workarounds (stripping nulls, refreshes, extra locks, `.first()` "just in case") without reproducing the need first. Don't loosen validation to make a change fit.

## Subagent staffing
- The main-thread model is Opus and acts as the orchestrator: it plans, delegates, integrates, and personally verifies critical results in the main thread (don't outsource final verification to a subagent).
- Default subagent tiers, picked by task complexity: Sonnet for moderate scoped work and production code, Haiku for mechanical sweeps. Opus subagents are only for escalation (below) or when I explicitly ask.
- Mechanical work goes to Haiku by default. Use the cursor-composer agent instead only for large multi-file edits where the transformation is decided and locating the sites is most of the work. If it reports the Cursor CLI unavailable, reassign the task to Haiku.
- Use the model aliases ('sonnet', 'haiku', 'opus') and let them resolve to Claude Code's default version for each tier.
- Opus and Sonnet subagents run at HIGH reasoning effort. Set effort:'high' explicitly on Workflow agent() calls; direct Agent spawns take effort from the agent definition, so state it in the spawn prompt when it matters.
- Always set the model explicitly on every Agent spawn and Workflow agent() call - subagents inherit the main-thread model when unset, which silently spawns Opus where a lower tier was intended.
- Escalation on struggle (orchestrator-driven - agents can't promote themselves): when a subagent returns a wrong/incomplete result, fails verification, or stalls, first diagnose. Ambiguous task spec -> retry once at the same tier with a sharpened prompt. Environmental failure (missing file, bad path, permissions) -> fix the input, same tier. Genuinely over its head -> escalate one tier (Haiku -> Sonnet -> Opus), and give the stronger model the failed attempt plus what was wrong with it. If an Opus subagent still can't resolve it, the main thread takes the task over directly.

## Bug fixes
- Start by reproducing the bug as closely aligned to the report as possible. Reproducing first confirms you've found the real problem, so the fix actually solves it.
- If it can't be reproduced (prod-only data, timing, external state), say so explicitly and state the hypothesis you're fixing against.
- After a fix, re-check every value derived from what changed. Fixes often introduce a second bug in an adjacent computation (e.g. clamping a bound breaks a stride, or serializing work causes re-fetching).

## UI changes
- Be picky. Point out inconsistencies. Make sure elements are pixel-perfect.

## Memory maintenance
- When a fact in a CLAUDE.md or memory file changes, rewrite the entry to state the current truth cleanly. Never append a correction on top of stale text (no "anything above saying X is now stale" chains) - resolve the contradiction in place.
- Delete or rewrite superseded entries rather than layering notes. If the old state still matters (e.g. old names in historical docs), keep it as one line of translation guidance, not as preserved stale claims.

## Noticing problems
- If something in the project clearly looks off, even if it's unrelated to the current task, flag it for me to review in the final reply. Don't fix it as part of the current change unless I ask.

## Code comments
- Do not narrate what the code does, does not do, or what stayed the same.
- Do not explain the diff, the PR decision, or review feedback in comments/docstrings.
- Do not justify choosing one API/mixin/pattern over another, or describe parity with removed/old behavior. That belongs in the MR/review reply, not in code.
- Only comment when a future reader would misread a subtle invariant that is still true in the code (ordering constraint, matching an external API, a real footgun). If removing the comment wouldn't cause a wrong change later, omit it.
- Prefer deleting a weak comment over rewriting it.
- Never claim an invariant the code doesn't enforce (e.g. "only one at a time" with nothing serializing it).
- Docstrings state the contract (what goes in, what comes out, what it stores and in whose terms), not how it works.
- Any magic number in config, CI, or SQL (interval, timeout, limit, workaround) gets a one-line reason and its source (measurement, doc link).

## Refactoring
- Prioritize parity in functional behavior and any generated messages with the existing code. Only deviate if instructed to.
- If the refactor cannot have perfect parity, explain why.

## Tests
- Every new branch, error path, and field gets a test. Parsers and filters also get boundary inputs: empty, missing optional field, escaped characters, fewer than expected.
- Every assertion must fail if the behavior it tests broke. Assert exact values, not `at.least`/`objectContaining`/tolerance margins. Test through the public surface (views, components) rather than internals.
- Use real instances of the project's own models and objects; mock only external boundaries.
- When a contract changes, find tests that now pass vacuously and rewrite or delete them.
- When changing code, identify the narrowest relevant tests (the single test or file covering the change) and ask me whether to run them. Do not run them automatically.
- Never propose or run a full suite or package-wide run unless I ask. See the run-tests skill for how to run them.

## Before finishing a change
- Re-read the whole final diff, not just the last iteration. Delete anything no longer referenced (functions, props, stages, env vars, exception classes, test helpers), leftover local/debug changes, and duplication introduced along the way.
- If the diff has grown past what one reviewer can follow (thousands of lines, dozens of files, or unrelated concerns bundled together), stop and propose a split. Preparatory refactors go in a preceding MR.

## Merge requests
- Follow the package's actual changelog convention (CHANGELOG `Unreleased` section or towncrier fragment, whichever it uses) for every behavior change, including side changes to other components. Every TODO/FIXME cites a ticket.
- Fill in every section of the MR template, and keep the description accurate as the diff changes.
- During review, push fixes as new commits instead of amending, so reviewers and review bots can follow what changed.

## Repositories
- To look for git repositories outside the current workspace, check ~/workspace first.
