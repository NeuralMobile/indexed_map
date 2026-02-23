## 1.1.0

### Performance

- **O(1) `indexOfId`**: Added a reverse index map (`Map<I, int>`) that keeps ID-to-position mappings synchronized on every mutation. This makes `indexOfId()` truly O(1) instead of the previous O(n) linear scan via `List.indexOf`. All internal operations (`add`, `insertAt`, `removeById`, `moveIdTo`, `upsertKeepingPosition`, `sortBy`) now benefit from this.
- **O(1) `contains` override**: Uses the item's `indexId` for instant membership checks instead of the inherited O(n) iteration from `IterableMixin`. Note: this checks by ID, not by value equality. Use `any((e) => e == element)` for equality-based checks.
- **O(1) `first` / `last` overrides**: Direct list access instead of going through the lazy `values` iterable.
- **Dedicated `Iterator`**: Custom `_IndexedMapIterator` avoids creating intermediate lazy iterables on every `for-in` loop, with fail-fast concurrent-modification detection.

### Bug Fixes

- **`ItemWrapper` changed from `final` to `base` class**: Users can now extend `ItemWrapper` to add custom metadata fields (e.g., `createdAt`, `isPinned`). Previously, the `final` modifier prevented this outside the library.
- **`operator []=` with ID collision**: Fixed a bug where setting `map[index] = newItem` with a `newItem.indexId` that already exists at a different index could corrupt internal state. The colliding entry is now properly removed first, and the insertion position is correctly adjusted when the colliding entry is before the target index.
- **`upsertKeepingPosition` with ID collision**: Fixed a bug where changing an item's ID to one that already exists elsewhere in the map would leave orphaned entries. Both the old entry and the colliding entry are now properly cleaned up, with correct position adjustment when the collision is before the target.
- **`moveIdTo` bounds validation**: Now returns `false` for out-of-bounds `toIndex` (negative or >= length) instead of throwing a `RangeError`. This is consistent with the method's `bool` return type contract.
- **`insertAt` with `replaceMoveToEnd`**: Fixed index adjustment when the existing item is before the insertion point, preventing off-by-one positioning.
- **`removeWhere` single-pass evaluation**: The predicate is now evaluated exactly once per item in a single pass, preventing state desync with stateful or non-deterministic predicates. Re-entrant mutations inside the predicate throw `ConcurrentModificationError`.
- **Fail-fast iteration**: Structural mutations (additions, removals, reordering) during iteration now throw `ConcurrentModificationError`, matching standard Dart collection semantics. In-place value replacements at a fixed position (same-id swaps) do **not** invalidate iterators.
- **Constructor `map`/`list` params deprecated**: These parameters are now `@Deprecated` and ignored (previously they could corrupt internal state via shared mutable references). They will be removed in 2.0.0.

### New API

- **`addAll(Iterable<T> items)`**: Bulk-add items, returning the count of items actually inserted/replaced (respects duplicate policy).
- **`removeWhere(bool Function(T) test)`**: Remove all items matching a predicate, returning the count removed.
- **`Iterable<I> get keys`**: Ordered iterable of all IDs.
- **`Map<I, T> toMap()`**: Returns a simple `Map<I, T>` from ID to item (not wrappers).
- **`toString()`**: Meaningful debug output showing all entries (e.g., `IndexedMap(u1: User(u1, Alice), u2: User(u2, Bob))`).

### Documentation

- Fixed performance table: corrected `indexOfId` complexity to O(1) (now accurate with reverse index).
- Fixed `add(item)` complexity note to clarify O(1) for new items.
- Added documentation for all new API methods.
- Removed incorrect `ItemWrapper` extension example from Advanced Features (replaced with accurate guidance).
- Fixed `Message` constructor in code examples to match actual API.

### Infrastructure

- Fixed `dependabot.yml`: set `package-ecosystem` to `"pub"` (was empty string).
- Removed unused `collection` dev dependency.

---

## 1.0.0

### Initial Release

**Core Features:**

- **IndexedMap<T, I>** - Hybrid data structure combining Map and List benefits
- **O(1) ID-based lookups** via `getById(id)`
- **O(1) indexed access** via `operator[](index)`
- **Ordered iteration** with full Iterable mixin support
- **MapIndexable<I> interface** for type-safe ID extraction

**Duplicate Handling Policies:**

- `DuplicatePolicy.ignore` - Keep existing, ignore duplicates
- `DuplicatePolicy.replaceKeepPosition` - Replace in-place (default)
- `DuplicatePolicy.replaceMoveToEnd` - Replace and move to end

**Core Operations:**

- `add(item)` - Append to end with duplicate policy handling
- `insertAt(index, item)` - Insert at specific position
- `removeById(id)` / `removeAt(index)` - Remove by ID or position
- `moveIdTo(id, toIndex)` - Reorder items by ID
- `sortBy(comparator)` - In-place sorting maintaining ID associations
- `upsertKeepingPosition()` - Update with potential ID changes

**Query Operations:**

- `containsId(id)` - Check ID existence
- `indexOfId(id)` - Find position by ID
- `getWrapperById(id)` - Access to internal wrapper metadata

**Views and Access:**

- `values` - Read-only iterable of items
- `toList()` - Defensive copy as List
- `wrappers` - Unmodifiable view of internal wrappers
- `asMapView` - Unmodifiable view of internal map

**Construction Methods:**

- `IndexedMap()` - Empty constructor with optional policy
- `IndexedMap.fromIterable()` - Bulk construction from iterable
