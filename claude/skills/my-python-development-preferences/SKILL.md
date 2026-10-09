---
name: my-python-development-preferences
description: Don's preferences for Python code — imports, Django models/migrations/DRF, SQLAlchemy, msgspec/pydantic validation, error handling and logging, and pytest. Use when writing, refactoring, or reviewing any .py file.
---

# Python development preferences

## Imports
- When adding an import, prefer to add it at the top of the file outside of functions, unless it introduces a cyclic import issue.

## Django models and migrations
- Nullability follows the lifecycle: a column is nullable only if its value is genuinely unknown at insert. A JSONField holding a list/dict uses `default=list`/`db_default=[]` with `null=False`. Don't copy `null=True` from older models (often a blue/green concession).
- One index per column. Never combine `db_index=True` with a `Meta.indexes` entry on the same field. FKs are already indexed.
- `on_delete`: if the parent is removed by a cascade elsewhere, use `RESTRICT`, not `PROTECT`. When adding a PROTECT/RESTRICT FK, update any hand-maintained teardown list (e.g. an admin `delete_model`).
- Never take `[0]` or `.first()` from an unordered queryset. Order by a meaningful field (`ordinal`, timestamp), not a UUID pk. When exactly one row is expected, use `.get()` with a lookup qualified enough to be unique.
- An invariant enforced in `clean()` must also run on save (`full_clean()` in `save()`); don't rely on callers.
- Generic FKs and other polymorphic relations: when the relation can hold a new type, every iterator, prefetch, and dereference of it must filter by content type or handle the new type. GFKs don't cascade, so delete dependents explicitly and test it.
- A settings key read by shared code must exist in every settings module that loads that code (each service, plus test settings).
- Enqueue async side effects (Celery tasks, emails) from inside `transaction.atomic` with `transaction.on_commit`.
- Backfills: filter out both null and empty, count the target rows in production before writing the command, batch with `.iterator()`, and have the migration and the command reference each other.
- New models that write audit or activity records declare their audited fields deliberately; don't leave them empty by default.

## DRF
- Serializer fields that hold an FK use `PrimaryKeyRelatedField`, so a bad id gives a 400 instead of an IntegrityError 500. Validate uniqueness before saving so violations are 400s.
- Scope a view's queryset on the model its pk refers to. Use the project's existing permission/scoping mechanism for the new model rather than scoping through a different one.
- Don't re-scope something that was already scoped earlier in the same request.
- When uniqueness per id is part of the contract, return a dict keyed by id rather than a list.

## Validation (msgspec / pydantic)
- After parsing, read the parsed struct, never the raw dict. Use `msgspec.UNSET` to tell "absent" apart from `null`.
- Don't set `forbid_unknown_fields=True` on payloads produced by systems you don't control; they add fields without notice. Don't flip a strict struct to lenient to tolerate one legacy key; declare that key as optional.
- Check the pydantic major version first. On v1, use `parse_raw`/`parse_obj`, not `validate` or v2 names.

## SQLAlchemy
- Timestamps are `DateTime(timezone=True)` with `server_default=func.now()`.
- Point an FK at the meaningful unique key (e.g. `request_id`) when there is one. Link status/audit rows to the request that produced them.

## Errors and logging
- Raise the module's domain exception, not a bare `ValueError`. Shared layers raise generic exceptions and the caller translates them into its own.
- Never silently coerce, truncate, or skip malformed data. Log a warning with identifiers, or raise.
- Log and error messages include the identifiers of the entities involved. When replacing an error path, keep its log.
- Use the model's existing helper properties instead of probing with `hasattr`/`getattr`.

## Tests (pytest)
- Use real model and entity instances. `MagicMock(spec=...)` is only for external clients.
- Shared fixtures go in `conftest.py`. Don't write factory helpers with parameters no test varies, or fake exception classes nothing raises.
- Use `response.json()`, not `json.loads(response.content)`.
- Avoid `django_assert_max_num_queries`. When the query count is the point (an N+1 fix), assert the exact count with no tolerance.
- Test product behavior through views and viewsets rather than model internals. Include the less-informed case (e.g. the path where an optional relation is absent).

## Standard library
- Don't use `NamedTemporaryFile(delete=False)` just to get a filename. Use a context-managed temp file or `TemporaryDirectory`, and remove generated files after uploading them.

## Before finishing
Search the diff for `.first()`, `[0]`, `null=True`, `db_index=True`, `forbid_unknown_fields`, `except Exception`, `hasattr(`, `MagicMock(`, and `ValueError(`. For each one, apply the rules above or say in your summary why it stays.
