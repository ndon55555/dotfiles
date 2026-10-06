# Frontend preferences — examples

## Availability check: watcher + enable flags → keyed scope + computed

**Smell:** A per-item composable is gated by parent-level `checksEnabled` / `featureEnabled`, and re-runs on a broad `payload` `WatchSource<unknown>` that the callback ignores. The parent also computes slide-level aggregates (`hasMaskChannels`, `hasRoiExplorerData`) that feed back into each item.

**Before (imperative):**

```ts
// Parent: slide-level gates control every algorithm
const hasMaskChannels = computed(() =>
  rawAnalysisEntries.value.some(entry => entry.maskChannels.length > 0),
);
const hasRoiExplorerData = computed(() =>
  rawAnalysisEntries.value.some(/* displayable / path5-only checks */),
);
const shouldInitializePath5 = computed(
  () => toValue(featureEnabled) && hasRoiExplorerData.value,
);

const algorithmScope = useComposableScope(
  (entry: RoiExplorerAnalysisEntry) =>
    useAlgorithmRoiExplorer({
      entry,
      getPath5CheckUrl,
      checksEnabled: () =>
        shouldInitializePath5.value && hasMaskChannels.value,
      payload: rawAnalysisEntries, // "something changed" — ignored in callback
      calculateWithMask,
    }),
  entry => `${entry.algorithm.id}:${entry.maskId}`,
);
const algorithms = algorithmScope.useList(rawAnalysisEntries);

// Child: watch as init + retry trigger
watch(
  [() => toValue(checksEnabled), payload],
  ([enabled]) => {
    if (enabled) {
      void checkAvailability();
    }
  },
  { immediate: true },
);
```

**After (declarative):**

Only create scopes for entries that should participate. Scope existence *is* the condition; the check runs once when the scope is created. Aggregate upward for display only.

```ts
// Parent: filter the list; no enable flags, no slide-level gates fed downward
const algorithmScope = useComposableScope(
  (entry: RoiExplorerAnalysisEntry) =>
    useAlgorithmRoiExplorer({ entry, getPath5CheckUrl, calculateWithMask }),
  entry => `${entry.algorithm.id}:${entry.maskId}`,
);
const algorithms = algorithmScope.useList(
  computed(() => analysisEntriesWithOptions(rawAnalysisEntries.value)),
);

const roiExplorer = computed((): RoiExplorer => {
  if (algorithms.value.length === 0) {
    return { state: 'initializing' };
  }
  const availabilities = algorithms.value.map(a => a.availability.value);
  if (availabilities.includes('ok')) {
    return { state: hasOpenedRoiExplorer.value ? 'ready' : 'waiting-for-user' };
  }
  if (availabilities.includes(null)) {
    return { state: 'initializing' };
  }
  return getUnavailableState(availabilities.filter(isNotNull));
});

// Child: one fetch on create; null = pending (no separate isChecking)
const availability = shallowRef<Maybe<Path5Availability>>(null);
void fetchAvailability().then(result => {
  availability.value = result;
});
const isSelectable = computed(() => availability.value === 'ok');
```

**Why:** New masks already get a new keyed scope (and thus a check). Watching the whole slide payload to retry failed masks conflates "data refreshed" with "retry this HEAD". Prefer a narrow retry (backoff / user action) if transient failures matter.

## State that only reports on other state → computed

**Smell:** A `ref` / `shallowRef` is updated from several places whenever related conditions change (`updateXFromY`, watchers that assign state).

**Before:**

```ts
const roiExplorer = shallowRef<RoiExplorer>({ state: 'initializing' });

watch(shouldInitializePath5, async newVal => {
  if (!newVal) return;
  roiExplorer.value = { state: 'initializing' };
  isPath5Available = await checkPath5Availability(); // mutates roiExplorer inside
});

const updateRoiExplorerStateFromPath5Availability = (results: ...) => {
  // more assignments to roiExplorer.value
};
```

**After:**

```ts
const hasOpenedRoiExplorer = ref(false); // true user/session state
const availabilityByMask = /* per-scope results */;

const roiExplorer = computed((): RoiExplorer => {
  // derive solely from hasOpenedRoiExplorer + availabilityByMask
});
```

Keep `ref` only for irreducible state (user clicked open, in-flight edit selection). Everything else is a `computed`.

## N of a thing: wrap single-item logic, don't rewrite with dictionaries

**Smell:** Multi-item generalization rewrites the single-item algorithm into nested maps keyed by algorithm / annotation / calculation.

**Before:** One big function that indexes by algorithm ID throughout.

**After:**

```ts
const countBadgeSelectionsForAlgorithm = (insight, entry) => { /* old logic */ };

const countBadgeSelections = (insightsByAlgorithmId) =>
  algorithms.value.reduce(
    (n, algorithm) =>
      n +
      countBadgeSelectionsForAlgorithm(
        insightsByAlgorithmId[algorithm.entry.algorithm.id],
        algorithm.entry,
      ),
    0,
  );
```

Or lift the single-item composable with `useComposableScope` / `useList` and aggregate over the list.

## Exclusive async resource → Mutex

**Smell:** Swapping futures / ad-hoc queues so only one H5 (or similar) is open at a time; correctness depends on every caller participating.

**Before:** Hand-rolled "latest future wins" or a custom queue shared across call sites.

**After:**

```ts
const mutex = new Mutex();

const calculateWithMask = (args) =>
  mutex.runExclusive(async () => {
    // load / compute / unload — local property of this function
  });
```

## Independent requests: update as each resolves

**Smell:** `Promise.all` over checks, then inspect the batch — the UI stays blocking until the slowest finishes even when one success is enough.

**Before:**

```ts
const results = await Promise.all(masks.map(checkOne));
updateStateFromAll(results);
```

**After:**

```ts
for (const mask of masks) {
  void checkOne(mask).then(result => {
    // update that mask's availability; ready as soon as any is ok
  });
}
```

(Or one check per keyed scope, as in the first example.)
