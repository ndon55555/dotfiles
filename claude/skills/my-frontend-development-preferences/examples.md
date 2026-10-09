# Frontend preferences — examples

The examples use a generic "explorer" panel over a list of data sources. `useKeyedScopes` stands for a keyed per-item scope helper. It creates one `effectScope` per item key when the item enters the list, and disposes it when the item leaves. Use the project's equivalent, or build one on `effectScope`.

## Availability check: watcher + enable flags → keyed scope + computed

**Smell:** A per-item composable is gated by parent-level `checksEnabled`/`featureEnabled` flags. It re-runs on a broad `payload` `WatchSource<unknown>` that the callback ignores. The parent also computes page-level aggregates (`hasDatasets`, `hasExplorerData`) that feed back into each item.

**Before (imperative):**

```ts
// Parent: page-level gates control every source
const hasDatasets = computed(() =>
  rawSources.value.some(source => source.datasets.length > 0),
);
const hasExplorerData = computed(() =>
  rawSources.value.some(/* displayable checks */),
);
const shouldInitialize = computed(
  () => toValue(featureEnabled) && hasExplorerData.value,
);

const sources = useKeyedScopes(
  rawSources,
  source => `${source.id}:${source.datasetId}`,
  (source: ExplorerSource) =>
    useSourceExplorer({
      source,
      getAvailabilityUrl,
      checksEnabled: () => shouldInitialize.value && hasDatasets.value,
      payload: rawSources, // "something changed" — ignored in callback
      computeWithDataset,
    }),
);

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

Only create scopes for the entries that should take part. The scope existing *is* the condition, so the check runs once when the scope is created. Aggregate upward for display only.

```ts
// Parent: filter the list; no enable flags, no page-level gates fed downward
const sources = useKeyedScopes(
  computed(() => sourcesWithOptions(rawSources.value)),
  source => `${source.id}:${source.datasetId}`,
  (source: ExplorerSource) =>
    useSourceExplorer({ source, getAvailabilityUrl, computeWithDataset }),
);

const explorer = computed((): Explorer => {
  if (sources.value.length === 0) {
    return { state: 'initializing' };
  }
  const availabilities = sources.value.map(s => s.availability.value);
  if (availabilities.includes('ok')) {
    return { state: hasOpenedExplorer.value ? 'ready' : 'waiting-for-user' };
  }
  if (availabilities.includes(null)) {
    return { state: 'initializing' };
  }
  return getUnavailableState(availabilities.filter(isNotNull));
});

// Child: one fetch on create; null = pending (no separate isChecking)
const availability = shallowRef<Availability | null>(null);
void fetchAvailability().then(result => {
  availability.value = result;
});
const isSelectable = computed(() => availability.value === 'ok');
```

**Why:** A new dataset already gets a new keyed scope, and with it a check. Watching the whole page payload to retry failed checks conflates "data refreshed" with "retry this request". If transient failures matter, prefer a narrow retry (backoff or a user action).

## State that only reports on other state → computed

**Smell:** A `ref`/`shallowRef` is updated from several places whenever related conditions change (`updateXFromY` functions, watchers that assign state).

**Before:**

```ts
const explorer = shallowRef<Explorer>({ state: 'initializing' });

watch(shouldInitialize, async newVal => {
  if (!newVal) return;
  explorer.value = { state: 'initializing' };
  isAvailable = await checkAvailability(); // mutates explorer inside
});

const updateExplorerStateFromAvailability = (results: ...) => {
  // more assignments to explorer.value
};
```

**After:**

```ts
const hasOpenedExplorer = ref(false); // true user/session state
const availabilityByDataset = /* per-scope results */;

const explorer = computed((): Explorer => {
  // derive solely from hasOpenedExplorer + availabilityByDataset
});
```

Keep a `ref` only for state that can't be derived (the user opened the panel, an in-flight edit selection). Everything else is a `computed`.

## N of a thing: wrap single-item logic, don't rewrite with dictionaries

**Smell:** Generalizing to many items rewrites the single-item logic into nested maps keyed by source, item, and metric.

**Before:** One big function that indexes by source ID throughout.

**After:**

```ts
const countBadgeSelectionsForSource = (selection, source) => { /* old logic */ };

const countBadgeSelections = (selectionsBySourceId) =>
  sources.value.reduce(
    (n, s) =>
      n + countBadgeSelectionsForSource(selectionsBySourceId[s.source.id], s.source),
    0,
  );
```

Or lift the single-item composable into keyed per-item scopes and aggregate over the list.

## Exclusive async resource → Mutex

**Smell:** Swapped futures or ad-hoc queues keep only one large resource (a big file in memory, a worker) open at a time. Correctness depends on every caller participating.

**Before:** A hand-rolled "latest future wins" or a custom queue shared across call sites.

**After:**

```ts
const mutex = new Mutex();

const computeWithDataset = (args) =>
  mutex.runExclusive(async () => {
    // load / compute / unload — local property of this function
  });
```

## Independent requests: update as each resolves

**Smell:** `Promise.all` over the checks, then inspect the batch. The UI stays blocked until the slowest check finishes, even when one success is enough.

**Before:**

```ts
const results = await Promise.all(datasets.map(checkOne));
updateStateFromAll(results);
```

**After:**

```ts
for (const dataset of datasets) {
  void checkOne(dataset).then(result => {
    // update that dataset's availability; ready as soon as any is ok
  });
}
```

(Or one check per keyed scope, as in the first example.)
