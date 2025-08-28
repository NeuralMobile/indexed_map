## 1.0.0

### Initial Release

**Core Features:**

- ✅ **IndexedMap<T, I>** - Hybrid data structure combining Map and List benefits
- ✅ **O(1) ID-based lookups** via `getById(id)`
- ✅ **O(1) indexed access** via `operator[](index)`
- ✅ **Ordered iteration** with full Iterable mixin support
- ✅ **MapIndexable<I> interface** for type-safe ID extraction

**Duplicate Handling Policies:**

- ✅ `DuplicatePolicy.ignore` - Keep existing, ignore duplicates
- ✅ `DuplicatePolicy.replaceKeepPosition` - Replace in-place (default)
- ✅ `DuplicatePolicy.replaceMoveToEnd` - Replace and move to end

**Core Operations:**

- ✅ `add(item)` - Append to end with duplicate policy handling
- ✅ `insertAt(index, item)` - Insert at specific position
- ✅ `removeById(id)` / `removeAt(index)` - Remove by ID or position
- ✅ `moveIdTo(id, toIndex)` - Reorder items by ID
- ✅ `sortBy(comparator)` - In-place sorting maintaining ID associations
- ✅ `upsertKeepingPosition()` - Update with potential ID changes

**Query Operations:**

- ✅ `containsId(id)` - Check ID existence
- ✅ `indexOfId(id)` - Find position by ID
- ✅ `getWrapperById(id)` - Access to internal wrapper metadata

**Views and Access:**

- ✅ `values` - Read-only iterable of items
- ✅ `toList()` - Defensive copy as List
- ✅ `wrappers` - Unmodifiable view of internal wrappers
- ✅ `asMapView` - Unmodifiable view of internal map

**Construction Methods:**

- ✅ `IndexedMap()` - Empty constructor with optional policy
- ✅ `IndexedMap.fromIterable()` - Bulk construction from iterable

**ItemWrapper<T, I>:**

- ✅ Wrapper class for future metadata extensions
- ✅ Efficient internal storage with pointer-based identity

**Developer Experience:**

- ✅ **Comprehensive test suite** with 100% coverage
- ✅ **Performance benchmarks** vs standard collections
- ✅ **Rich documentation** with real-world examples
- ✅ **Type safety** with full generic support
- ✅ **Null safety** compliance

**Performance Characteristics:**

- ✅ O(1) add, getById, operator[]
- ✅ O(n) insert, remove, move operations
- ✅ O(n log n) sorting
- ✅ Memory efficient with minimal wrapper overhead

**Use Cases Demonstrated:**

- ✅ Chat/message management with ID-based editing
- ✅ User activity tracking with recent-activity policies
- ✅ Product catalogs with sorting and fast lookups
- ✅ Cache implementations with insertion order
- ✅ Any scenario requiring both random access and ordered iteration

**Quality Assurance:**

- ✅ Dart 3.8.1+ compatibility
- ✅ No runtime dependencies
- ✅ Comprehensive error handling
- ✅ Edge case coverage
- ✅ Real-world scenario testing
- ✅ Performance regression testing
