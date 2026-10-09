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
- `watch(..., { immediate: true })` used as "run once when this exists" → give each item its own keyed `effectScope`, created when the item enters the list and disposed when it leaves, so the effect runs once at creation.
- An `enabled`/`checksEnabled` flag passed into a child composable → filter the input list so unwanted children are never created.
- A parent-level aggregate (`list.some(...)`) fed back down to control each item → derive per item.
- Separate `isLoading` + `result` refs → one ref where `null` means pending.
- The same predicate defined in two places → one helper.
- Two components each holding the same state, kept in sync by a `watch` → pick one owner and pass it down (controlled prop plus a `set` emit).
- Two watchers persisting a selection → one writable `computed`.

## Setup scope and lifecycle

- Call `use*` composables, `watch`, and `computed` only at the top level of `setup` or of another composable. Never call them inside functions, event handlers, `computed` getters, or after an `await`.
- Code that needs a template ref runs in `onMounted`, not in an `immediate` watch, which fires before mount.
- Composables clean up with `onScopeDispose`, not `onBeforeUnmount`.
- Prefer `set*` events and functions over `toggle*`.
- Reuse the component's existing `toRefs(props)` instead of adding `toRef` calls. Type slots with `defineSlots`, and check whether a slot renders content, not just whether `$slots.name` exists (that only means the slot function is defined).

## Collections and composables

- For "N of a thing", keep the single-item composable and lift it into keyed per-item scopes (the project's helper, or one built on `effectScope`); aggregate over the list. Don't mix array reshaping into business logic.
- When generalizing logic to many items, wrap the existing single-item function rather than rewriting it with dictionaries.
- Many helpers that juggle indexes means the data shape is wrong: consider compound keys, per-scope views, or asking the backend for a frontend-friendly shape (e.g. a dict keyed by ID).

## Async

- Exclusive resources: guard the function that uses them with an `async-mutex` `Mutex`; don't hand-roll queues of futures.
- Independent requests: fire them all and update state as each resolves; don't `Promise.all` and then inspect.
- Every fire-and-forget call (`void fn()`) has a `.catch` that surfaces the error and clears pending/loading state.
- After an `await`, re-read shared maps before deleting or overwriting entries; the user may have changed them while the request was in flight.
- A payload for a replace-set endpoint is built from the full persisted set, never from a filtered or display view; otherwise the hidden items get deleted.
- A component writing to a shared store or filter only writes the values it owns. Test it with out-of-scope values already seeded.

## Persisted state

- When a `localStorage`/session value changes shape, use a new key, or validate on read and drop what doesn't parse.
- Check what happens when a persisted value is replayed in a different mode (e.g. a sort field that becomes invalid after switching views).

## Types

- String-literal unions (or `enum`) over `const` objects sliced with `typeof`/`Values`.
- No indexed access types (`Foo['bar']`) outside generic contexts; write the type out.
- Do not re-export imported types; import from the source module.
- No `as`, `as unknown as`, or casts around `computed` to quiet TS/Volar; fix the generic instead. Pass generics explicitly (`isGroup<O>(x)`) and use `<!-- @vue-generic {O} -->` for generic child components.
- Type guards narrow without `as`. Discriminate on a value (`kind: 'group'`), not on key presence or the shape of `options[0]`.
- A prop that is always supplied is required, not optional.
- `NaN` is already a `number`. Don't invent sentinel classes or write `number | typeof NaN`.

## Docs and tests

- Docstrings state the input/output contract. Don't warn against misusing things the code never does.
- Test composables in an `effectScope`, not a throwaway component.
- Be consistent within a spec (e.g. `mockResolvedValueOnce` everywhere, or call-count assertions everywhere).
- Cypress: use cypress-real-events for hover and mouse movement, give new widgets a `data-testid`, and hoist repeated fixtures into constants. When a component's props or gating change, update its `.cy.tsx` consumers in the same change.

## Hot loops

- In per-pixel and per-element loops, avoid closures, `Map` lookups, and default no-op callbacks (`() => true`); use `null` and short-circuit. Hoist work that doesn't change within a row.

## Before finishing

Search the diff for `watch(`, `immediate: true`, `shallowRef`/`ref` assigned from multiple places, `enabled`-style options, `use[A-Z]` calls inside function bodies or `computed` getters, ` as `, `void `, and `toggle`. For each one, either convert it per the rules above or state in your summary why it must stay imperative.

See [examples.md](examples.md) for before/after examples.
