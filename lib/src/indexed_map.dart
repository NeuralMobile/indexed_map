import 'dart:collection';

/// An item that can be indexed by a stable id of type [I].
abstract class MapIndexable<I> {
  I get indexId;
}

/// Wrapper to allow future metadata without changing the container shape.
/// Add fields like: createdAt, isPinned, etc.
base class ItemWrapper<T extends MapIndexable<I>, I> {
  final T item;

  const ItemWrapper(this.item);

  I get id => item.indexId;

  @override
  String toString() => 'ItemWrapper(id: $id, item: $item)';
}

/// How to handle inserting an item whose id already exists.
enum DuplicatePolicy {
  /// Do nothing if id exists.
  ignore,

  /// Replace the existing item, keeping its current position.
  replaceKeepPosition,

  /// Replace the existing item and move it to the end (like recent activity).
  replaceMoveToEnd,
}

/// A hybrid container that provides O(1) lookup by id and ordered/indexed access.
///
/// T must expose a stable [indexId] of type [I].
///
/// Internally maintains three synchronized structures:
/// - A [Map] for O(1) lookup by id
/// - A [List] for O(1) indexed access
/// - A reverse index [Map] for O(1) id-to-index resolution
class IndexedMap<T extends MapIndexable<I>, I> with IterableMixin<T> {
  final Map<I, ItemWrapper<T, I>> _map;
  final List<ItemWrapper<T, I>> _list;

  /// Reverse index: maps each id to its current position in [_list].
  final Map<I, int> _indexMap;

  /// Monotonically increasing counter; bumped on every operation that changes
  /// the list length or element order (structural mutation). In-place value
  /// replacements at a fixed position do **not** increment this counter.
  ///
  /// Used by [_IndexedMapIterator] for fail-fast concurrent-modification
  /// detection, matching standard Dart collection semantics where only
  /// length/order changes invalidate iterators.
  int _modCount = 0;

  /// Controls behavior when adding an item with an existing id.
  final DuplicatePolicy duplicatePolicy;

  IndexedMap({
    @Deprecated('This parameter is ignored and will be removed in 2.0.0.')
    Map<I, ItemWrapper<T, I>>? map,
    @Deprecated('This parameter is ignored and will be removed in 2.0.0.')
    List<ItemWrapper<T, I>>? list,
    this.duplicatePolicy = DuplicatePolicy.replaceKeepPosition,
  }) : _map = <I, ItemWrapper<T, I>>{},
       _list = <ItemWrapper<T, I>>[],
       _indexMap = <I, int>{};

  /// Build from an iterable. Duplicates are resolved via [duplicatePolicy].
  factory IndexedMap.fromIterable(
    Iterable<T> items, {
    DuplicatePolicy duplicatePolicy = DuplicatePolicy.replaceKeepPosition,
  }) {
    final im = IndexedMap<T, I>(duplicatePolicy: duplicatePolicy);
    for (final item in items) {
      im.add(item);
    }
    return im;
  }

  /// Number of items.
  @override
  int get length => _list.length;

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  /// O(1) check whether [element] is in this collection.
  ///
  /// Uses the item's [MapIndexable.indexId] for the lookup, so this returns
  /// `true` when an item with the same id exists, regardless of value
  /// equality.  For strict equality semantics use the inherited iterable
  /// methods (e.g. `any((e) => e == element)`).
  @override
  bool contains(Object? element) {
    if (element is T) {
      return _map.containsKey(element.indexId);
    }
    return false;
  }

  /// O(1) first item.
  @override
  T get first => _list.first.item;

  /// O(1) last item.
  @override
  T get last => _list.last.item;

  /// True if the id exists.
  bool containsId(I id) => _map.containsKey(id);

  /// O(1) lookup by id. Returns null if not present.
  T? getById(I id) => _map[id]?.item;

  /// O(1) wrapper lookup by id (if you need metadata).
  ItemWrapper<T, I>? getWrapperById(I id) => _map[id];

  /// O(1) by index (bounds-checked by List).
  T operator [](int index) => _list[index].item;

  /// Replace the item at a position. Id consistency is enforced.
  void operator []=(int index, T newItem) {
    final existing = _list[index];
    final oldId = existing.id;
    final newId = newItem.indexId;
    if (oldId == newId) {
      // Same id: in-place value replacement — not a structural change.
      final wrapped = ItemWrapper<T, I>(newItem);
      _list[index] = wrapped;
      _map[newId] = wrapped;
    } else {
      // Id changed: remove old entry from _map/_indexMap, AND from _list.
      _map.remove(oldId);
      _indexMap.remove(oldId);

      final existingNew = _map[newId];
      if (existingNew != null) {
        // newId already exists elsewhere — remove that entry too.
        final existingIdx = _indexMap[newId]!;
        _map.remove(newId);
        _indexMap.remove(newId);
        // Remove both the old item at `index` and the colliding entry.
        // Remove higher index first to avoid shifting issues.
        if (index > existingIdx) {
          _list.removeAt(index);
          _list.removeAt(existingIdx);
        } else {
          _list.removeAt(existingIdx);
          _list.removeAt(index);
        }
        // Adjust insertion point: if the collision was before the target
        // position, its removal shifted the target left by 1.
        final insertIdx = (existingIdx < index ? index - 1 : index).clamp(
          0,
          _list.length,
        );
        final wrapped = ItemWrapper<T, I>(newItem);
        _list.insert(insertIdx, wrapped);
        _map[newId] = wrapped;
        _rebuildIndexMap();
        _modCount++;
      } else {
        // No collision — in-place swap at same list position, different id.
        final wrapped = ItemWrapper<T, I>(newItem);
        _list[index] = wrapped;
        _map[newId] = wrapped;
        _indexMap[newId] = index;
      }
    }
  }

  /// Append to the end. Handles duplicates per [duplicatePolicy].
  /// Returns true if a new id was inserted or an existing id was replaced.
  bool add(T item) {
    final id = item.indexId;
    final existing = _map[id];

    if (existing == null) {
      final wrapped = ItemWrapper<T, I>(item);
      _map[id] = wrapped;
      _indexMap[id] = _list.length;
      _list.add(wrapped);
      _modCount++;
      return true;
    }

    switch (duplicatePolicy) {
      case DuplicatePolicy.ignore:
        return false;
      case DuplicatePolicy.replaceKeepPosition:
        // In-place value replacement — not a structural change.
        final idx = _indexMap[id]!;
        final wrapped = ItemWrapper<T, I>(item);
        _list[idx] = wrapped;
        _map[id] = wrapped;
        return true;
      case DuplicatePolicy.replaceMoveToEnd:
        final idx = _indexMap[id]!;
        _list.removeAt(idx);
        final wrapped = ItemWrapper<T, I>(item);
        _list.add(wrapped);
        _map[id] = wrapped;
        _rebuildIndexMapFrom(idx);
        _modCount++;
        return true;
    }
  }

  /// Add all items from [items]. Returns the number of items actually inserted
  /// or replaced (not ignored).
  int addAll(Iterable<T> items) {
    var count = 0;
    for (final item in items) {
      if (add(item)) count++;
    }
    return count;
  }

  /// Insert at a specific position. If id exists, behavior depends on [duplicatePolicy].
  void insertAt(int index, T item) {
    final id = item.indexId;
    final existing = _map[id];

    if (existing == null) {
      final wrapped = ItemWrapper<T, I>(item);
      _map[id] = wrapped;
      _list.insert(index, wrapped);
      _rebuildIndexMapFrom(index);
      _modCount++;
      return;
    }

    switch (duplicatePolicy) {
      case DuplicatePolicy.ignore:
        return;
      case DuplicatePolicy.replaceKeepPosition:
        // In-place value replacement — not a structural change.
        final oldIdx = _indexMap[id]!;
        final wrapped = ItemWrapper<T, I>(item);
        _list[oldIdx] = wrapped;
        _map[id] = wrapped;
        return;
      case DuplicatePolicy.replaceMoveToEnd:
        final oldIdx = _indexMap[id]!;
        _list.removeAt(oldIdx);
        final wrapped = ItemWrapper<T, I>(item);
        final adjustedIndex = oldIdx < index ? index - 1 : index;
        final clampedIndex = adjustedIndex.clamp(0, _list.length);
        _list.insert(clampedIndex, wrapped);
        _map[id] = wrapped;
        _rebuildIndexMapFrom(oldIdx < clampedIndex ? oldIdx : clampedIndex);
        _modCount++;
        return;
    }
  }

  /// Remove by id. Returns removed item or null if not present.
  T? removeById(I id) {
    final wrapped = _map.remove(id);
    if (wrapped == null) return null;
    final idx = _indexMap.remove(id)!;
    _list.removeAt(idx);
    _rebuildIndexMapFrom(idx);
    _modCount++;
    return wrapped.item;
  }

  /// Remove at index. Returns removed item.
  T removeAt(int index) {
    final wrapped = _list.removeAt(index);
    _map.remove(wrapped.id);
    _indexMap.remove(wrapped.id);
    _rebuildIndexMapFrom(index);
    _modCount++;
    return wrapped.item;
  }

  /// Remove all items matching [test]. Returns the number of items removed.
  ///
  /// The predicate is evaluated exactly once per item in a snapshot taken
  /// before any removal begins. If the predicate mutates this [IndexedMap],
  /// a [ConcurrentModificationError] is thrown.
  int removeWhere(bool Function(T item) test) {
    final expectedModCount = _modCount;
    final indicesToRemove = <int>[];
    for (var i = 0; i < _list.length; i++) {
      if (test(_list[i].item)) {
        indicesToRemove.add(i);
      }
      if (_modCount != expectedModCount) {
        throw ConcurrentModificationError(this);
      }
    }
    if (indicesToRemove.isEmpty) return 0;
    // Remove from back to front so indices stay valid.
    for (var i = indicesToRemove.length - 1; i >= 0; i--) {
      final idx = indicesToRemove[i];
      final wrapped = _list.removeAt(idx);
      _map.remove(wrapped.id);
      _indexMap.remove(wrapped.id);
    }
    _rebuildIndexMap();
    _modCount++;
    return indicesToRemove.length;
  }

  /// Move an item identified by [id] to a new [toIndex].
  /// Returns true if moved, false if [id] not found, [toIndex] out of bounds,
  /// or item is already at [toIndex].
  bool moveIdTo(I id, int toIndex) {
    final wrapped = _map[id];
    if (wrapped == null) return false;
    final from = _indexMap[id]!;
    if (from == toIndex) return false;
    if (toIndex < 0 || toIndex >= _list.length) return false;
    _list.removeAt(from);
    _list.insert(toIndex, wrapped);
    _rebuildIndexMapFrom(from < toIndex ? from : toIndex);
    _modCount++;
    return true;
  }

  /// Re-sort the list **in place** using the provided comparator over T.
  /// Map remains valid since ids don't change.
  void sortBy(Comparator<T> comparator) {
    _list.sort((a, b) => comparator(a.item, b.item));
    _rebuildIndexMap();
    _modCount++;
  }

  /// Return read-only iterable of items in order.
  Iterable<T> get values => _list.map((w) => w.item);

  /// Return an iterable of all ids in order.
  Iterable<I> get keys => _list.map((w) => w.id);

  /// Return a defensive copy of the ordered items.
  @override
  List<T> toList({bool growable = false}) =>
      _list.map((w) => w.item).toList(growable: growable);

  /// Return a [Map] from id to item.
  Map<I, T> toMap() => {
    for (final entry in _map.entries) entry.key: entry.value.item,
  };

  /// O(1) index of an id, or -1 if missing.
  int indexOfId(I id) => _indexMap[id] ?? -1;

  /// Update an item whose id **may have changed**.
  /// - If the id is unchanged, it replaces in-place (keeps position).
  /// - If the id changed, it removes the old and inserts the new at the same
  ///   position (adjusted when a colliding entry before the target is removed).
  ///   If the new id collides with an existing entry, that entry is removed first.
  /// Returns true if updated/inserted.
  bool upsertKeepingPosition({required I oldId, required T newItem}) {
    final oldWrapped = _map[oldId];
    if (oldWrapped == null) {
      return add(newItem);
    }
    final pos = _indexMap[oldId]!;
    final newId = newItem.indexId;
    if (newId == oldId) {
      // In-place value replacement — not a structural change.
      final wrapped = ItemWrapper<T, I>(newItem);
      _list[pos] = wrapped;
      _map[newId] = wrapped;
      return true;
    } else {
      // Id changed: remove old entry from all structures.
      _map.remove(oldId);
      _indexMap.remove(oldId);

      // If newId collides with another existing entry, remove it too.
      final existingNew = _map[newId];
      if (existingNew != null) {
        final existingIdx = _indexMap[newId]!;
        _map.remove(newId);
        _indexMap.remove(newId);
        // Remove both old item and colliding item from list.
        // Remove higher index first to avoid shifting issues.
        if (pos > existingIdx) {
          _list.removeAt(pos);
          _list.removeAt(existingIdx);
        } else {
          _list.removeAt(existingIdx);
          _list.removeAt(pos);
        }
        // Adjust insertion point: if the collision was before the target
        // position, its removal shifted the target left by 1.
        final insertPos = (existingIdx < pos ? pos - 1 : pos).clamp(
          0,
          _list.length,
        );
        final wrapped = ItemWrapper<T, I>(newItem);
        _list.insert(insertPos, wrapped);
        _map[newId] = wrapped;
        _rebuildIndexMap();
        _modCount++;
      } else {
        // No collision — in-place swap at same list position, different id.
        final wrapped = ItemWrapper<T, I>(newItem);
        _list[pos] = wrapped;
        _map[newId] = wrapped;
        _indexMap[newId] = pos;
      }
      return true;
    }
  }

  /// Clear everything.
  void clear() {
    _map.clear();
    _list.clear();
    _indexMap.clear();
    _modCount++;
  }

  /// Iterate items in order.
  ///
  /// Throws [ConcurrentModificationError] if the map is structurally modified
  /// (length or order changes) during iteration. In-place value replacements
  /// at a fixed position do not invalidate iterators.
  @override
  Iterator<T> get iterator => _IndexedMapIterator<T, I>(this);

  /// Unmodifiable view of wrappers if you need metadata externally.
  List<ItemWrapper<T, I>> get wrappers =>
      List<ItemWrapper<T, I>>.unmodifiable(_list);

  /// Unmodifiable view of the backing map if needed.
  Map<I, ItemWrapper<T, I>> get asMapView =>
      Map<I, ItemWrapper<T, I>>.unmodifiable(_map);

  @override
  String toString() {
    if (isEmpty) return 'IndexedMap()';
    final entries = _list.map((w) => '${w.id}: ${w.item}').join(', ');
    return 'IndexedMap($entries)';
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Rebuild the entire reverse index map.
  void _rebuildIndexMap() {
    _indexMap.clear();
    for (var i = 0; i < _list.length; i++) {
      _indexMap[_list[i].id] = i;
    }
  }

  /// Rebuild the reverse index map from [startIndex] to the end of the list.
  /// More efficient than a full rebuild when only a tail segment changed.
  void _rebuildIndexMapFrom(int startIndex) {
    for (var i = startIndex; i < _list.length; i++) {
      _indexMap[_list[i].id] = i;
    }
  }
}

/// Dedicated iterator with fail-fast concurrent-modification detection.
class _IndexedMapIterator<T extends MapIndexable<I>, I> implements Iterator<T> {
  final IndexedMap<T, I> _owner;
  final int _expectedModCount;
  int _index = -1;

  _IndexedMapIterator(this._owner) : _expectedModCount = _owner._modCount;

  @override
  T get current => _owner._list[_index].item;

  @override
  bool moveNext() {
    if (_expectedModCount != _owner._modCount) {
      throw ConcurrentModificationError(_owner);
    }
    _index++;
    return _index < _owner._list.length;
  }
}
