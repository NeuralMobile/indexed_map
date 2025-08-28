import 'package:indexed_map/indexed_map.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'dart:math' as math;

// Test model
class TestItem implements MapIndexable<String> {
  final String id;
  final String name;
  final int value;

  TestItem(this.id, this.name, this.value);

  @override
  String get indexId => id;

  @override
  String toString() => 'TestItem($id, $name, $value)';
}

// IndexedMap benchmarks
class IndexedMapAddBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  late List<TestItem> items;

  IndexedMapAddBenchmark() : super('IndexedMap.add');

  @override
  void setup() {
    items = List.generate(
      itemCount,
      (i) => TestItem('item_$i', 'Item $i', math.Random().nextInt(1000)),
    );
  }

  @override
  void run() {
    final map = IndexedMap<TestItem, String>();
    for (final item in items) {
      map.add(item);
    }
  }
}

class IndexedMapLookupBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int lookupCount = 1000;
  late IndexedMap<TestItem, String> map;
  late List<String> lookupIds;

  IndexedMapLookupBenchmark() : super('IndexedMap.getById');

  @override
  void setup() {
    map = IndexedMap<TestItem, String>();
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      map.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }

    // Generate random lookup IDs
    lookupIds = List.generate(
      lookupCount,
      (i) => 'item_${random.nextInt(itemCount)}',
    );
  }

  @override
  void run() {
    for (final id in lookupIds) {
      map.getById(id);
    }
  }
}

class IndexedMapIndexAccessBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int accessCount = 1000;
  late IndexedMap<TestItem, String> map;
  late List<int> indices;

  IndexedMapIndexAccessBenchmark() : super('IndexedMap.operator[]');

  @override
  void setup() {
    map = IndexedMap<TestItem, String>();
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      map.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }

    // Generate random indices
    indices = List.generate(accessCount, (i) => random.nextInt(itemCount));
  }

  @override
  void run() {
    for (final index in indices) {
      map[index];
    }
  }
}

class IndexedMapInsertBenchmark extends BenchmarkBase {
  static const int itemCount = 1000; // Smaller for insert operations
  late IndexedMap<TestItem, String> map;
  late List<TestItem> itemsToInsert;

  IndexedMapInsertBenchmark() : super('IndexedMap.insertAt');

  @override
  void setup() {
    map = IndexedMap<TestItem, String>();
    final random = math.Random();

    // Pre-populate with some items
    for (int i = 0; i < itemCount; i++) {
      map.add(TestItem('existing_$i', 'Existing $i', random.nextInt(1000)));
    }

    // Items to insert
    itemsToInsert = List.generate(
      100,
      (i) => TestItem('new_$i', 'New $i', random.nextInt(1000)),
    );
  }

  @override
  void run() {
    final random = math.Random();
    for (final item in itemsToInsert) {
      final index = random.nextInt(map.length + 1);
      map.insertAt(index, item);
    }
  }
}

class IndexedMapRemoveBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int removeCount = 1000;
  late IndexedMap<TestItem, String> map;
  late List<String> idsToRemove;

  IndexedMapRemoveBenchmark() : super('IndexedMap.removeById');

  @override
  void setup() {
    map = IndexedMap<TestItem, String>();
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      map.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }

    // IDs to remove
    idsToRemove = List.generate(
      removeCount,
      (i) => 'item_${random.nextInt(itemCount)}',
    );
  }

  @override
  void run() {
    // Create a fresh map for each run
    final testMap = IndexedMap<TestItem, String>();
    for (int i = 0; i < itemCount; i++) {
      testMap.add(TestItem('item_$i', 'Item $i', math.Random().nextInt(1000)));
    }

    for (final id in idsToRemove) {
      testMap.removeById(id);
    }
  }
}

class IndexedMapSortBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  late IndexedMap<TestItem, String> map;

  IndexedMapSortBenchmark() : super('IndexedMap.sortBy');

  @override
  void setup() {
    map = IndexedMap<TestItem, String>();
    final random = math.Random();

    // Add items with random values
    for (int i = 0; i < itemCount; i++) {
      map.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }
  }

  @override
  void run() {
    map.sortBy((a, b) => a.value.compareTo(b.value));
  }
}

// Comparison benchmarks with standard collections

class MapLookupBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int lookupCount = 1000;
  late Map<String, TestItem> map;
  late List<String> lookupIds;

  MapLookupBenchmark() : super('Map.lookup');

  @override
  void setup() {
    map = <String, TestItem>{};
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      final item = TestItem('item_$i', 'Item $i', random.nextInt(1000));
      map[item.id] = item;
    }

    // Generate random lookup IDs
    lookupIds = List.generate(
      lookupCount,
      (i) => 'item_${random.nextInt(itemCount)}',
    );
  }

  @override
  void run() {
    for (final id in lookupIds) {
      map[id];
    }
  }
}

class ListIndexAccessBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int accessCount = 1000;
  late List<TestItem> list;
  late List<int> indices;

  ListIndexAccessBenchmark() : super('List.operator[]');

  @override
  void setup() {
    list = <TestItem>[];
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      list.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }

    // Generate random indices
    indices = List.generate(accessCount, (i) => random.nextInt(itemCount));
  }

  @override
  void run() {
    for (final index in indices) {
      list[index];
    }
  }
}

class ListFindBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int lookupCount = 1000;
  late List<TestItem> list;
  late List<String> lookupIds;

  ListFindBenchmark() : super('List.firstWhere');

  @override
  void setup() {
    list = <TestItem>[];
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      list.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }

    // Generate random lookup IDs
    lookupIds = List.generate(
      lookupCount,
      (i) => 'item_${random.nextInt(itemCount)}',
    );
  }

  @override
  void run() {
    for (final id in lookupIds) {
      try {
        list.firstWhere((item) => item.id == id);
      } catch (e) {
        // Item not found, continue
      }
    }
  }
}

class ListSortBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  late List<TestItem> list;

  ListSortBenchmark() : super('List.sort');

  @override
  void setup() {
    list = <TestItem>[];
    final random = math.Random();

    // Add items with random values
    for (int i = 0; i < itemCount; i++) {
      list.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }
  }

  @override
  void run() {
    final listCopy = List<TestItem>.from(list);
    listCopy.sort((a, b) => a.value.compareTo(b.value));
  }
}

// Combined data structure benchmark (Map + List)
class MapListCombinedBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int operationCount = 1000;
  late Map<String, TestItem> map;
  late List<TestItem> list;
  late List<String> lookupIds;
  late List<int> indices;

  MapListCombinedBenchmark() : super('Map+List.combined_ops');

  @override
  void setup() {
    map = <String, TestItem>{};
    list = <TestItem>[];
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      final item = TestItem('item_$i', 'Item $i', random.nextInt(1000));
      map[item.id] = item;
      list.add(item);
    }

    // Generate random operations
    lookupIds = List.generate(
      operationCount,
      (i) => 'item_${random.nextInt(itemCount)}',
    );
    indices = List.generate(operationCount, (i) => random.nextInt(itemCount));
  }

  @override
  void run() {
    // Simulate mixed operations that require both map and list
    for (int i = 0; i < operationCount; i++) {
      // Lookup by ID
      map[lookupIds[i]];
      // Access by index
      list[indices[i]];
    }
  }
}

class IndexedMapCombinedBenchmark extends BenchmarkBase {
  static const int itemCount = 10000;
  static const int operationCount = 1000;
  late IndexedMap<TestItem, String> indexedMap;
  late List<String> lookupIds;
  late List<int> indices;

  IndexedMapCombinedBenchmark() : super('IndexedMap.combined_ops');

  @override
  void setup() {
    indexedMap = IndexedMap<TestItem, String>();
    final random = math.Random();

    // Add items
    for (int i = 0; i < itemCount; i++) {
      indexedMap.add(TestItem('item_$i', 'Item $i', random.nextInt(1000)));
    }

    // Generate random operations
    lookupIds = List.generate(
      operationCount,
      (i) => 'item_${random.nextInt(itemCount)}',
    );
    indices = List.generate(operationCount, (i) => random.nextInt(itemCount));
  }

  @override
  void run() {
    // Same operations as MapListCombinedBenchmark
    for (int i = 0; i < operationCount; i++) {
      // Lookup by ID
      indexedMap.getById(lookupIds[i]);
      // Access by index
      indexedMap[indices[i]];
    }
  }
}

void main() {
  print('IndexedMap Performance Benchmarks');
  print('==================================\n');

  print('Running IndexedMap benchmarks...');

  // IndexedMap specific benchmarks
  IndexedMapAddBenchmark().report();
  IndexedMapLookupBenchmark().report();
  IndexedMapIndexAccessBenchmark().report();
  IndexedMapInsertBenchmark().report();
  IndexedMapRemoveBenchmark().report();
  IndexedMapSortBenchmark().report();

  print('\nRunning comparison benchmarks...');

  // Comparison with standard collections
  MapLookupBenchmark().report();
  ListIndexAccessBenchmark().report();
  ListFindBenchmark().report();
  ListSortBenchmark().report();

  print('\nRunning combined operation benchmarks...');

  // Combined operations comparison
  MapListCombinedBenchmark().report();
  IndexedMapCombinedBenchmark().report();

  print('\nBenchmark Analysis:');
  print('==================');
  print('• IndexedMap.getById should be comparable to Map lookup (both O(1))');
  print('• IndexedMap[index] should be comparable to List[index] (both O(1))');
  print(
    '• IndexedMap.getById should be much faster than List.firstWhere (O(1) vs O(n))',
  );
  print(
    '• Combined operations show IndexedMap advantage over separate Map+List',
  );
  print(
    '• Memory usage: IndexedMap uses wrapper objects, slight overhead vs separate collections',
  );
  print(
    '• IndexedMap.sortBy maintains ID mappings, unlike separate sort operations',
  );
}
