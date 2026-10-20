---
name: my-python-development-preferences
description: Don's preferences for Python code — imports, Django models/migrations/queries/DRF, SQLAlchemy, msgspec/pydantic validation, error handling, and pytest. Use when writing, refactoring, or reviewing any .py file.
---

# Python development preferences

For backend code, also load my-backend-development-preferences. It holds the language-agnostic schema, query, API, validation, and error rules; this skill covers the Python mechanisms for them.

## Imports
- When adding an import, prefer to add it at the top of the file outside of functions, unless it introduces a cyclic import issue.

## Django models and migrations
- A JSONField holding a list/dict uses `default=list`/`db_default=[]` with `null=False`.
- Never combine `db_index=True` with a `Meta.indexes` entry on the same field. Django already indexes FKs.
- `on_delete`: if the parent is removed by a cascade elsewhere, use `RESTRICT`, not `PROTECT`. When adding a PROTECT/RESTRICT FK, update any hand-maintained teardown list (e.g. an admin `delete_model`).
- An invariant enforced in `clean()` must also run on save (`full_clean()` in `save()`).
- Generic FKs: filter every iterator, prefetch, and dereference by content type.
- A settings key read by shared code must exist in every settings module that loads that code (each service, plus test settings).
- Enqueue async side effects (Celery tasks, emails) from inside `transaction.atomic` with `transaction.on_commit`.
- Backfill commands batch with `.iterator()`.

## Django queries
- Never take `[0]` or `.first()` from an unordered queryset. When exactly one row is expected, use `.get()`.
- Accessors that query: lazy FK access, GFK dereferences, history-based helpers, and managers such as `ims_deployment_user`. A GFK `parent` followed by `latest_created()` is two queries per lookup, and GFKs can't be `select_related`.
- `Q(id__in=subquery) | Q(id__in=subquery)` is the unindexable OR-of-IN-subqueries shape. The explicit two-round-trip form is `.values(...).get()`, then `id__in=[...]`.
- Capture the emitted SQL for `EXPLAIN (ANALYZE)` with `CaptureQueriesContext`. Query-count assertions in tests follow the Tests section below.
- When one function owns a fetch, it loads its object with `select_related` and annotations in one query.

## DRF
- Serializer fields that hold an FK use `PrimaryKeyRelatedField`, so a bad id gives a 400 instead of an IntegrityError 500.

## Validation (msgspec / pydantic)
- Use `msgspec.UNSET` to tell "absent" apart from `null`.
- Don't set `forbid_unknown_fields=True` on payloads produced by systems you don't control.
- Check the pydantic major version first. On v1, use `parse_raw`/`parse_obj`, not `validate` or v2 names.

## SQLAlchemy
- Timestamps are `DateTime(timezone=True)` with `server_default=func.now()`.

## Errors
- Raise the module's domain exception, not a bare `ValueError`.
- Use the model's existing helper properties instead of probing with `hasattr`/`getattr`.

## Tests (pytest)
- `MagicMock(spec=...)` is only for external clients.
- Shared fixtures go in `conftest.py`. Don't write factory helpers with parameters no test varies, or fake exception classes nothing raises.
- Use `response.json()`, not `json.loads(response.content)`.
- Never use `django_assert_max_num_queries`. When the query count is the point (an N+1 fix), assert the exact count with no tolerance.
- The public surface is views, viewsets, and the real signal senders, not model internals. Include the less-informed case (e.g. the path where an optional relation is absent).

## Standard library
- Don't use `NamedTemporaryFile(delete=False)` just to get a filename. Use a context-managed temp file or `TemporaryDirectory`, and remove generated files after uploading them.

## Before finishing
Search the diff for `.first()`, `[0]`, `| Q(`, `Subquery(`, `OuterRef(`, related-object access inside loops, `null=True`, `db_index=True`, `forbid_unknown_fields`, `except Exception`, `hasattr(`, `MagicMock(`, and `ValueError(`. For each one, apply the rules here and in my-backend-development-preferences, or say in your summary why it stays.
