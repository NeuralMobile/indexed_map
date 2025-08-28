# IndexedMap

[![pub package](https://img.shields.io/pub/v/indexed_map.svg)](https://pub.dev/packages/indexed_map)
[![popularity](https://img.shields.io/pub/popularity/indexed_map?logo=dart)](https://pub.dev/packages/indexed_map/score)
[![likes](https://img.shields.io/pub/likes/indexed_map?logo=dart)](https://pub.dev/packages/indexed_map/score)
[![pub points](https://img.shields.io/pub/points/indexed_map?logo=dart)](https://pub.dev/packages/indexed_map/score)

A high-performance hybrid data structure that combines the benefits of both Map and List in a single container, providing **O(1) lookup by ID** while maintaining **ordered/indexed access** to elements.

## Features

✅ **O(1) ID-based lookups** - Fast retrieval using unique identifiers  
✅ **O(1) indexed access** - Direct access by position like a List  
✅ **Ordered iteration** - Maintains insertion/move order  
✅ **Configurable duplicate policies** - Control how duplicate IDs are handled  
✅ **In-place sorting** - Sort without losing ID associations  
✅ **Memory efficient** - Optimized internal storage with wrapper objects  
✅ **Type safe** - Full generic type support with compile-time safety  
✅ **Comprehensive API** - Rich set of operations for all use cases

## Perfect for

- **User lists** with fast lookup by user ID
- **Chat/message histories** with chronological order and ID-based editing
- **Product catalogs** with sorting and quick lookups
- **Cache implementations** with insertion order preservation
- **Any collection** where you need both random access and ordered iteration

## Quick Start

```dart
import 'package:indexed_map/indexed_map.dart';

// Define your indexable class
class User implements MapIndexable<String> {
  final String id;
  final String name;

  User(this.id, this.name);

  @override
  String get indexId => id;

  @override
  String toString() => 'User($id, $name)';
}

void main() {
  // Create an IndexedMap
  final users = IndexedMap<User, String>();

  // Add users
  users.add(User('u1', 'Alice'));
  users.add(User('u2', 'Bob'));
  users.add(User('u3', 'Carol'));

  // O(1) lookup by ID
  final alice = users.getById('u1');
  print(alice); // User(u1, Alice)

  // O(1) indexed access
  final firstUser = users[0];
  print(firstUser); // User(u1, Alice)

  // Insert at specific position
  users.insertAt(1, User('u4', 'David'));

  // Move items around
  users.moveIdTo('u1', 3); // Move Alice to position 3

  // Sort while maintaining ID associations
  users.sortBy((a, b) => a.name.compareTo(b.name));

  // Iterate in order
  for (final user in users) {
    print(user);
  }
}
```

## Core Concepts

### MapIndexable Interface

Your classes must implement the `MapIndexable<I>` interface to provide a stable ID:

```dart
class Product implements MapIndexable<int> {
  final int id;
  final String name;
  final double price;

  Product(this.id, this.name, this.price);

  @override
  int get indexId => id;  // Must return a stable, unique identifier
}
```

### Duplicate Policies

Control how duplicate IDs are handled:

```dart
enum DuplicatePolicy {
  ignore,                 // Keep existing item, ignore new one
  replaceKeepPosition,    // Replace item, keep same position (default)
  replaceMoveToEnd,       // Replace item, move to end (useful for "recent activity")
}

// Example: Recent activity tracking
final activeUsers = IndexedMap<User, String>(
  duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
);

activeUsers.add(User('alice', 'Alice'));
activeUsers.add(User('bob', 'Bob'));
activeUsers.add(User('alice', 'Alice')); // Alice moves to end
```

## Performance Characteristics

| Operation               | Time Complexity | Description           |
| ----------------------- | --------------- | --------------------- |
| `add(item)`             | O(1) amortized  | Add to end            |
| `getById(id)`           | O(1)            | Lookup by ID          |
| `operator[](index)`     | O(1)            | Access by index       |
| `insertAt(index, item)` | O(n)            | Insert at position    |
| `removeById(id)`        | O(n)            | Remove by ID          |
| `removeAt(index)`       | O(n)            | Remove by index       |
| `moveIdTo(id, index)`   | O(n)            | Move item to position |
| `sortBy(comparator)`    | O(n log n)      | In-place sort         |
| `indexOfId(id)`         | O(1)            | Find position of ID   |

### Benchmark Results

Based on 10,000 items with 1,000 operations:

| Operation             | IndexedMap | Alternative            |
| --------------------- | ---------- | ---------------------- |
| ID Lookup             | ~0.05ms    | Map: ~0.05ms           |
| Index Access          | ~0.03ms    | List: ~0.03ms          |
| ID Lookup (vs Linear) | ~0.05ms    | List.firstWhere: ~50ms |
| Combined Ops          | ~0.08ms    | Map+List: ~0.12ms      |

_Run benchmarks: `dart run benchmark/indexed_map_benchmark.dart`_

## Common Use Cases

### 1. Chat Message Management

```dart
class Message implements MapIndexable<String> {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;

  Message(this.id, this.content, this.senderId);

  @override
  String get indexId => id;
}

final messages = IndexedMap<Message, String>();

// Add messages in chronological order
messages.add(Message('msg1', 'Hello!', 'alice'));
messages.add(Message('msg2', 'Hi there!', 'bob'));

// Quick edit by ID (e.g., user edited message)
final originalMsg = messages.getById('msg1');
messages[messages.indexOfId('msg1')] =
    Message('msg1', 'Hello everyone!', 'alice');

// Insert out-of-order message
messages.insertAt(1, Message('msg3', 'Good morning!', 'carol'));
```

### 2. User Activity Tracking

```dart
final activeUsers = IndexedMap<User, String>(
  duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
);

// Users become active (automatically move to end)
activeUsers.add(User('alice', 'Alice'));
activeUsers.add(User('bob', 'Bob'));
activeUsers.add(User('alice', 'Alice')); // Alice moves to end

// Most recently active user
final mostActive = activeUsers.last;

// Activity ranking
for (int i = 0; i < activeUsers.length; i++) {
  print('${i + 1}. ${activeUsers[i].name}');
}
```

### 3. Product Catalog with Sorting

```dart
final catalog = IndexedMap<Product, int>();

// Add products
catalog.add(Product(1, 'Laptop', 999.99));
catalog.add(Product(2, 'Mouse', 29.99));
catalog.add(Product(3, 'Keyboard', 79.99));

// Sort by price (IDs remain valid)
catalog.sortBy((a, b) => a.price.compareTo(b.price));

// Quick lookup still works after sorting
final laptop = catalog.getById(1);
final laptopPosition = catalog.indexOfId(1);
```

### 4. Cache with LRU-like Behavior

```dart
class CacheItem<T> implements MapIndexable<String> {
  final String key;
  final T value;
  final DateTime accessTime;

  CacheItem(this.key, this.value) : accessTime = DateTime.now();

  @override
  String get indexId => key;
}

final cache = IndexedMap<CacheItem<String>, String>(
  duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
);

// Access moves item to end (most recently used)
String getValue(String key) {
  final item = cache.getById(key);
  if (item != null) {
    // Re-add to move to end
    cache.add(CacheItem(key, item.value));
    return item.value;
  }
  return loadFromSource(key);
}
```

## API Reference

### Construction

```dart
// Empty constructor
IndexedMap<T, I>({DuplicatePolicy duplicatePolicy})

// From iterable
IndexedMap<T, I>.fromIterable(Iterable<T> items, {DuplicatePolicy duplicatePolicy})
```

### Core Operations

```dart
// Adding items
bool add(T item)
void insertAt(int index, T item)

// Retrieving items
T? getById(I id)
T operator[](int index)
bool containsId(I id)
int indexOfId(I id)

// Removing items
T? removeById(I id)
T removeAt(int index)
void clear()

// Updating items
void operator[]=(int index, T newItem)
bool upsertKeepingPosition({required I oldId, required T newItem})

// Moving items
bool moveIdTo(I id, int toIndex)

// Sorting
void sortBy(Comparator<T> comparator)
```

### Views and Iteration

```dart
// Read-only access
Iterable<T> get values
List<T> toList({bool growable = false})
List<ItemWrapper<T, I>> get wrappers
Map<I, ItemWrapper<T, I>> get asMapView

// Properties
int get length
bool get isEmpty
bool get isNotEmpty

// Iteration
Iterator<T> get iterator  // Supports for-in loops
```

## Advanced Features

### Custom Wrapper Metadata

The `ItemWrapper<T, I>` class can be extended for additional metadata:

```dart
class TimestampedWrapper<T extends MapIndexable<I>, I> extends ItemWrapper<T, I> {
  final DateTime createdAt;
  final bool isPinned;

  TimestampedWrapper(T item, {this.isPinned = false})
      : createdAt = DateTime.now(),
        super(item);
}
```

### Bulk Operations

```dart
// Bulk add with duplicate handling
final users = [User('1', 'Alice'), User('2', 'Bob')];
final map = IndexedMap<User, String>.fromIterable(users);

// Bulk operations using standard Iterable methods
final adults = map.where((user) => user.age >= 18);
final names = map.map((user) => user.name);
final sorted = map.toList()..sort((a, b) => a.name.compareTo(b.name));
```

### Error Handling

```dart
// Safe operations that return null
final user = map.getById('nonexistent'); // null
final removed = map.removeById('nonexistent'); // null

// Operations that throw on invalid input
final user = map[999]; // RangeError
final removed = map.removeAt(-1); // RangeError
```

## Testing

Run the comprehensive test suite:

```bash
dart test
```

The test suite includes:

- ✅ All operations and edge cases
- ✅ All duplicate policies
- ✅ Error conditions
- ✅ Real-world scenarios
- ✅ Type safety verification
- ✅ Memory leak detection

## Benchmarking

Run performance benchmarks:

```bash
dart run benchmark/indexed_map_benchmark.dart
```

Compare with alternatives:

```bash
# Add benchmark_harness to dev_dependencies first
dart pub get
dart run benchmark/indexed_map_benchmark.dart
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and:

1. 🐛 **Report bugs** with minimal reproduction cases
2. 💡 **Suggest features** with clear use cases
3. 🔧 **Submit PRs** with tests and benchmarks
4. 📚 **Improve docs** and examples

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and migration guides.
