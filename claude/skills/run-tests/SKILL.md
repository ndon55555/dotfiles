---
name: run-tests
description: >
  Run tests with minimal token use while preserving full failure context.
  Use when the user asks to run tests, verify a change, or debug a failing test.
---

# Run tests

## Defaults

1. **Ask before running** unless the user already asked to run tests.
2. Prefer the repo’s documented runner (`just`, `npm test`, `pytest`, etc.) when present.
3. Run the **narrowest** target (file → class/describe → single test / `--spec`). Never a full suite unless asked.
4. Run outside the agent sandbox when the project requires it (e.g. Docker/`just`).

## Two-phase output (save tokens)

Quiet pass/fail first (tee to a log); only on failure, re-run with a useful traceback and **read the log**. Do not paste full green-run stdout into chat. Escalate to a longer traceback only if needed.

Pytest example (adapt flags for other runners — e.g. Vitest `--reporter=dot`, Jest `--silent`, etc.):

```bash
# Phase 1 — quiet
pytest <target> -q --tb=no 2>&1 | tee /tmp/test.out
echo EXIT:$?

# Phase 2 — failures only
pytest --lf --tb=short -vv 2>&1 | tee /tmp/test.fail.out
```

## Reporting

- Pass: one line — what ran + exit 0.
- Fail: failed node IDs, error gist, likely fix. Offer to re-run failures after a fix.
