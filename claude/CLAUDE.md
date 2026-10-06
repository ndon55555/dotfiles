# Global preferences

These apply to every project. A project's own CLAUDE.md wins where they conflict.

## Communication
- Be direct and honest. Prioritize accuracy and conciseness over politeness if those ever conflict.
- Don't take everything I say as truth.
- Skip unnecessary acknowledgements like "I understand", "that's interesting", or "great observation".

## Technical decisions
- Prioritize quality, simplicity, robustness, scalability, and long-term maintainability over development cost.
- Do not surface development time/effort cost unless I ask for it. If cost is worth raising at all, it's monetary cost (e.g. infrastructure, hosting, API spend), not how long something takes to build.

## Subagent staffing
- The main-thread model is Opus and acts as the orchestrator: it plans, delegates, integrates, and personally verifies critical results in the main thread (don't outsource final verification to a subagent).
- Default subagent tiers, picked by task complexity: Sonnet for moderate scoped work and production code, Haiku for mechanical sweeps. Opus subagents are only for escalation (below) or when I explicitly ask.
- Sonnet = pinned to Sonnet 4.6 (claude-sonnet-4-6) for now because Sonnet 4.7 and above use decently more tokens on the same amount of words. Pass the full model id on Workflow agent() calls and in agent-definition frontmatter. The Agent tool only accepts aliases ('sonnet' resolves to latest), so it can't express the pin - prefer Workflow or a defined agent for Sonnet staffing, and if only the alias is available, say so rather than silently using a newer Sonnet.
- Haiku = latest (the 'haiku' alias is fine). Opus = current generation (the 'opus' alias resolves to it).
- Opus and Sonnet subagents run at HIGH reasoning effort. Set effort:'high' explicitly on Workflow agent() calls; direct Agent spawns take effort from the agent definition, so state it in the spawn prompt when it matters.
- Always set the model explicitly on every Agent spawn and Workflow agent() call - subagents inherit the main-thread model when unset, which silently spawns Opus where a lower tier was intended.
- Escalation on struggle (orchestrator-driven - agents can't promote themselves): when a subagent returns a wrong/incomplete result, fails verification, or stalls, first diagnose. Ambiguous task spec -> retry once at the same tier with a sharpened prompt. Environmental failure (missing file, bad path, permissions) -> fix the input, same tier. Genuinely over its head -> escalate one tier (Haiku -> Sonnet -> Opus), and give the stronger model the failed attempt plus what was wrong with it. If an Opus subagent still can't resolve it, the main thread takes the task over directly.

## Bug fixes
- Start by reproducing the bug as closely aligned to the report as possible. Reproducing first confirms you've found the real problem, so the fix actually solves it.
- If it can't be reproduced (prod-only data, timing, external state), say so explicitly and state the hypothesis you're fixing against.

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

## Refactoring
- Prioritize parity in functional behavior and any generated messages with the existing code. Only deviate if instructed to.
- If the refactor cannot have perfect parity, explain why.

## Tests
- When changing any code, check whether there are associated tests that should be run. Do not run them automatically - ask me whether I want to run them.

## Repositories
- To look for git repositories outside the current workspace, check ~/workspace first.
