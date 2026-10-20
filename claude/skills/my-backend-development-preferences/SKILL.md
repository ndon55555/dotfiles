---
name: my-backend-development-preferences
description: Don's language-agnostic preferences for backend code — database schema, query counts and Postgres query plans, transactions and async side effects, backfills, API contracts, validating external payloads, and errors and logging. Use when writing, refactoring, or reviewing server-side code, ORM or SQL queries, migrations, or API endpoints in any language.
---

# Backend development preferences

Language-specific mechanisms for these rules live in the language skills (e.g. my-python-development-preferences for Django, DRF, SQLAlchemy, msgspec, pydantic).

## Schema
- Nullability follows the lifecycle: a column is nullable only if its value is genuinely unknown at insert. A list/dict column defaults to empty and is not nullable. Don't copy nullable columns from older tables (often a blue/green concession).
- One index per column; don't declare the same index twice through two mechanisms. Check whether the framework already indexes FKs before adding one.
- Timestamps are timezone-aware, with a database-side default of now.
- Point an FK at the meaningful unique key (e.g. `request_id`) when there is one. Link status/audit rows to the request that produced them.
- Polymorphic relations (generic FKs, type + id pairs): when the relation can hold a new type, every iterator, prefetch, and dereference of it must filter by type or handle the new type. They don't cascade, so delete dependents explicitly and test it.
- New tables that write audit or activity records declare their audited fields deliberately; don't leave them empty by default.

## Queries and performance
- Count queries per call and per loop iteration before calling data-access code done. Look for N+1 and for the same related row refetched on every iteration. Know which accessors issue queries: lazy relations, polymorphic dereferences, history-based helpers, and managers or properties that look like attribute access.
- Never take the first row of an unordered result. Order by a meaningful column (`ordinal`, timestamp), not a UUID pk. When exactly one row is expected, use a lookup qualified enough to be unique and fail if it isn't.
- Check every filter and join shape against the table's actual indexes (`pg_indexes`). On Postgres, `id IN (subquery) OR id IN (subquery)` plans as `(hashed SubPlan) OR (hashed SubPlan)` over a full scan and can't use the pk index. `id = (scalar subquery)` runs the subquery once as an InitPlan and can use the index, including under `OR` (BitmapOr). A literal `id IN (...)` list on the pk can always use the index. A correlated subquery runs once per outer row.
- Verify with `EXPLAIN (ANALYZE)` on the SQL the code actually emits. Tiny dev tables get seq scans whether or not an index applies, so don't explain a bad plan away as small data: tell the cases apart with `SET LOCAL enable_seqscan = off` or a scale test on a temp table.
- Readability wins ties. A couple of simple, clearly indexed queries beat one clever query; two round trips with explicit values (fetch the ids, then `id IN (...)`) are fine. Keep each fetch next to the code that uses it. When several call sites need the same related data, give one function ownership of the fetch (e.g. a per-object sync that loads its object with its joins and annotations in one query) instead of prefetching far from use or passing preloaded objects through parameters with implicit invariants.

## Transactions and data changes
- Enqueue async side effects (tasks, emails, messages) only after the transaction commits, so a rollback can't leave them pointing at rows that don't exist.
- An invariant is enforced on every write path, not left to callers.
- Backfills: filter out both null and empty, count the target rows in production before writing the command, batch the reads, and have the migration and the command reference each other.

## APIs
- A bad reference id or a uniqueness violation in a request is a 400, validated before saving, never an integrity-error 500.
- Scope a resource's query on the model its pk refers to, using the project's existing permission/scoping mechanism. Don't re-scope something already scoped earlier in the same request.
- When uniqueness per id is part of the contract, return a dict keyed by id rather than a list.

## Validating external payloads
- After parsing, read the parsed object, never the raw dict. Keep "absent" distinct from `null`.
- Don't forbid unknown fields on payloads produced by systems you don't control; they add fields without notice. Don't make a strict schema lenient to tolerate one legacy key; declare that key as optional.

## Errors and logging
- Raise the module's domain exception, not a generic one. Shared layers raise generic exceptions and the caller translates them into its own.
- Never silently coerce, truncate, or skip malformed data. Log a warning with identifiers, or raise.
- Log and error messages include the identifiers of the entities involved. When replacing an error path, keep its log.
