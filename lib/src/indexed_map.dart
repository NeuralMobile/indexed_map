import 'dart:collection';

/// An item that can be indexed by a stable id of type [I].
abstract class MapIndexable<I> {
  I get indexId;
}

/// Wrapper to allow future metadata without changing the container shape.
/// Add fields like: createdAt, isPinned, etc.
final class ItemWrapper<T extends MapIndexable<I>, I> {
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
class IndexedMap<T extends MapIndexable<I>, I> with IterableMixin<T> {
  final Map<I, ItemWrapper<T, I>> _map;
  final List<ItemWrapper<T, I>> _list;

  /// Controls behavior when adding an item with an existing id.
  final DuplicatePolicy duplicatePolicy;

  IndexedMap({
    Map<I, ItemWrapper<T, I>>? map,
    List<ItemWrapper<T, I>>? list,
    this.duplicatePolicy = DuplicatePolicy.replaceKeepPosition,
  }) : _map = map ?? <I, ItemWrapper<T, I>>{},
       _list = list ?? <ItemWrapper<T, I>>[];

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
    if (oldId != newId) {
      // Id changed: treat as position-preserving remove + insert.
      removeById(oldId);
      insertAt(index, newItem);
    } else {
      final wrapped = ItemWrapper<T, I>(newItem);
      _list[index] = wrapped;
      _map[newId] = wrapped;
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
      _list.add(wrapped);
      return true;
    }

    switch (duplicatePolicy) {
      case DuplicatePolicy.ignore:
        return false;
      case DuplicatePolicy.replaceKeepPosition:
        final idx = _list.indexOf(existing);
        final wrapped = ItemWrapper<T, I>(item);
        _list[idx] = wrapped;
        _map[id] = wrapped;
        return true;
      case DuplicatePolicy.replaceMoveToEnd:
        final idx = _list.indexOf(existing);
        final wrapped = ItemWrapper<T, I>(item);
        _list
          ..removeAt(idx)
          ..add(wrapped);
        _map[id] = wrapped;
        return true;
    }
  }

  /// Insert at a specific position. If id exists, behavior depends on [duplicatePolicy].
  void insertAt(int index, T item) {
    final id = item.indexId;
    final existing = _map[id];

    if (existing == null) {
      final wrapped = ItemWrapper<T, I>(item);
      _map[id] = wrapped;
      _list.insert(index, wrapped);
      return;
    }

    switch (duplicatePolicy) {
      case DuplicatePolicy.ignore:
        // Keep as-is, but ensure position is not changed.
        return;
      case DuplicatePolicy.replaceKeepPosition:
        final oldIdx = _list.indexOf(existing);
        final wrapped = ItemWrapper<T, I>(item);
        _list[oldIdx] = wrapped;
        _map[id] = wrapped;
        return;
      case DuplicatePolicy.replaceMoveToEnd:
        final oldIdx = _list.indexOf(existing);
        final wrapped = ItemWrapper<T, I>(item);
        _list
          ..removeAt(oldIdx)
          ..insert(index, wrapped);
        _map[id] = wrapped;
        return;
    }
  }

  /// Remove by id. Returns removed item or null if not present.
  T? removeById(I id) {
    final wrapped = _map.remove(id);
    if (wrapped == null) return null;
    final idx = _list.indexOf(wrapped);
    if (idx != -1) _list.removeAt(idx);
    return wrapped.item;
  }

  /// Remove at index. Returns removed item.
  T removeAt(int index) {
    final wrapped = _list.removeAt(index);
    _map.remove(wrapped.id);
    return wrapped.item;
  }

  /// Move an item identified by [id] to a new [toIndex].
  /// Returns true if moved.
  bool moveIdTo(I id, int toIndex) {
    final wrapped = _map[id];
    if (wrapped == null) return false;
    final from = _list.indexOf(wrapped);
    if (from == -1 || from == toIndex) return false;
    _list
      ..removeAt(from)
      ..insert(toIndex, wrapped);
    return true;
  }

  /// Re-sort the list **in place** using the provided comparator over T.
  /// Map remains valid since ids don't change.
  void sortBy(Comparator<T> comparator) {
    _list.sort((a, b) => comparator(a.item, b.item));
  }

  /// Return read-only iterable of items in order.
  Iterable<T> get values => _list.map((w) => w.item);

  /// Return a defensive copy of the ordered items.
  @override
  List<T> toList({bool growable = false}) =>
      _list.map((w) => w.item).toList(growable: growable);

  /// Index of an id, or -1 if missing.
  int indexOfId(I id) {
    final wrapped = _map[id];
    if (wrapped == null) return -1;
    return _list.indexOf(wrapped);
    // This is O(1) average because indexOf on identical instance is pointer-based.
  }

  /// Update an item whose id **may have changed**.
  /// - If the id is unchanged, it replaces in-place (keeps position).
  /// - If the id changed, it removes the old and inserts the new at the same position.
  /// Returns true if updated/inserted.
  bool upsertKeepingPosition({required I oldId, required T newItem}) {
    final oldWrapped = _map[oldId];
    if (oldWrapped == null) {
      // old not present — regular add semantics
      return add(newItem);
    }
    final pos = _list.indexOf(oldWrapped);
    final newId = newItem.indexId;
    if (newId == oldId) {
      final wrapped = ItemWrapper<T, I>(newItem);
      _list[pos] = wrapped;
      _map[newId] = wrapped;
      return true;
    } else {
      // Id changed: remove old, then insert new at the same position.
      removeById(oldId);
      insertAt(pos, newItem);
      return true;
    }
  }

  /// Clear everything.
  void clear() {
    _map.clear();
    _list.clear();
  }

  /// Iterate items in order.
  @override
  Iterator<T> get iterator => values.iterator;

  /// Unmodifiable view of wrappers if you need metadata externally.
  List<ItemWrapper<T, I>> get wrappers =>
      List<ItemWrapper<T, I>>.unmodifiable(_list);

  /// Unmodifiable view of the backing map if needed.
  Map<I, ItemWrapper<T, I>> get asMapView =>
      Map<I, ItemWrapper<T, I>>.unmodifiable(_map);
}
