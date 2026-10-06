---
name: my-frontend-development-preferences
description: Don's preferences for TypeScript and Vue code — reactivity (computed over watchers), composables, async coordination, types, and tests. Use when writing, refactoring, or reviewing frontend code, including .vue/.ts files, composables, and Vitest/Cypress specs.
---

# Frontend development preferences

## Reactivity: declarative first

State that only reports on other state is a `computed`, not a `ref` updated by a `watch` or by calls to "update" functions.

Treat these as smells; fix or justify each one:

- A `watch` whose callback only assigns refs → `computed`.
- A `watch` that ignores its source value, or a `WatchSource<unknown>` "something changed" signal → find the real condition, or delete it.
- `watch(..., { immediate: true })` used as "run once when this exists" → let a keyed scope (`useComposableScope` + `useList`) own the lifecycle; the effect runs when the item is created.
- An `enabled`/`checksEnabled` flag passed into a child composable → filter the input list so unwanted children are never created.
- A parent-level aggregate (`list.some(...)`) fed back down to control each item → derive per item.
- Separate `isLoading` + `result` refs → one ref where `null` means pending.
- The same predicate defined in two places → one helper.

## Collections and composables

- For "N of a thing", keep the single-item composable and lift it with `useComposableScope`/`useList`; aggregate over the list. Don't mix array reshaping into business logic.
- When generalizing logic to many items, wrap the existing single-item function rather than rewriting it with dictionaries.
- Many helpers that juggle indexes means the data shape is wrong: consider compound keys, per-scope views, or asking the backend for a frontend-friendly shape (e.g. a dict keyed by ID).

## Async

- Exclusive resources: guard the function that uses them with an `async-mutex` `Mutex`; don't hand-roll queues of futures.
- Independent requests: fire them all and update state as each resolves; don't `Promise.all` and then inspect.

## Types

- String-literal unions (or `enum`) over `const` objects sliced with `typeof`/`Values`.
- No indexed access types (`Foo['bar']`) outside generic contexts; write the type out.
- Do not re-export imported types; import from the source module.

## Docs and tests

- Docstrings state the input/output contract. Don't warn against misusing things the code never does.
- Test composables in an `effectScope`, not a throwaway component.
- Be consistent within a spec (e.g. `mockResolvedValueOnce` everywhere, or call-count assertions everywhere).

## Before finishing

Search the diff for `watch(`, `immediate: true`, `shallowRef`/`ref` assigned from multiple places, and `enabled`-style options. For each one, either convert it per the rules above or state in your summary why it must stay imperative.

See [examples.md](examples.md) for before/after examples.
