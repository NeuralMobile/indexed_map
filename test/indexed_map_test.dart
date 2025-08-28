import 'package:indexed_map/indexed_map.dart';
import 'package:test/test.dart';

// Test models
class User implements MapIndexable<String> {
  final String id;
  final String name;
  final int age;

  User(this.id, this.name, {this.age = 0});

  @override
  String get indexId => id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(id, name, age);

  @override
  String toString() => 'User($id, $name, age: $age)';
}

class Product implements MapIndexable<int> {
  final int id;
  final String name;
  final double price;

  Product(this.id, this.name, this.price);

  @override
  int get indexId => id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, price);

  @override
  String toString() => 'Product($id, $name, \$${price.toStringAsFixed(2)})';
}

void main() {
  group('IndexedMap Construction', () {
    test('creates empty IndexedMap', () {
      final map = IndexedMap<User, String>();
      expect(map.length, equals(0));
      expect(map.isEmpty, isTrue);
      expect(map.isNotEmpty, isFalse);
    });

    test('creates IndexedMap with custom duplicate policy', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.ignore,
      );
      expect(map.duplicatePolicy, equals(DuplicatePolicy.ignore));
    });

    test('creates IndexedMap from iterable', () {
      final users = [User('1', 'Alice'), User('2', 'Bob'), User('3', 'Carol')];
      final map = IndexedMap<User, String>.fromIterable(users);
      expect(map.length, equals(3));
      expect(map.getById('2')?.name, equals('Bob'));
    });

    test('fromIterable handles duplicates according to policy', () {
      final users = [
        User('1', 'Alice'),
        User('2', 'Bob'),
        User('1', 'Alice Updated'), // Duplicate ID
      ];

      // Default policy: replaceKeepPosition
      final map1 = IndexedMap<User, String>.fromIterable(users);
      expect(map1.length, equals(2));
      expect(map1.getById('1')?.name, equals('Alice Updated'));
      expect(map1[0].name, equals('Alice Updated')); // Kept position

      // Ignore policy
      final map2 = IndexedMap<User, String>.fromIterable(
        users,
        duplicatePolicy: DuplicatePolicy.ignore,
      );
      expect(map2.length, equals(2));
      expect(map2.getById('1')?.name, equals('Alice')); // Original kept

      // Move to end policy
      final map3 = IndexedMap<User, String>.fromIterable(
        users,
        duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
      );
      expect(map3.length, equals(2));
      expect(map3.getById('1')?.name, equals('Alice Updated'));
      expect(map3[1].name, equals('Alice Updated')); // Moved to end
    });
  });

  group('Basic Operations', () {
    late IndexedMap<User, String> map;
    late User alice, bob;

    setUp(() {
      map = IndexedMap<User, String>();
      alice = User('1', 'Alice', age: 25);
      bob = User('2', 'Bob', age: 30);
    });

    test('add items', () {
      expect(map.add(alice), isTrue);
      expect(map.add(bob), isTrue);
      expect(map.length, equals(2));
      expect(map.getById('1'), equals(alice));
      expect(map.getById('2'), equals(bob));
    });

    test('indexed access', () {
      map.add(alice);
      map.add(bob);
      expect(map[0], equals(alice));
      expect(map[1], equals(bob));
    });

    test('containsId', () {
      map.add(alice);
      expect(map.containsId('1'), isTrue);
      expect(map.containsId('999'), isFalse);
    });

    test('getById returns null for missing id', () {
      expect(map.getById('999'), isNull);
    });

    test('getWrapperById', () {
      map.add(alice);
      final wrapper = map.getWrapperById('1');
      expect(wrapper, isNotNull);
      expect(wrapper!.item, equals(alice));
      expect(wrapper.id, equals('1'));
    });
  });

  group('Duplicate Policies', () {
    test('ignore policy', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.ignore,
      );
      final alice1 = User('1', 'Alice');
      final alice2 = User('1', 'Alice Updated');

      expect(map.add(alice1), isTrue);
      expect(map.add(alice2), isFalse); // Ignored
      expect(map.getById('1'), equals(alice1)); // Original kept
    });

    test('replaceKeepPosition policy', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.replaceKeepPosition,
      );
      final alice1 = User('1', 'Alice');
      final bob = User('2', 'Bob');
      final alice2 = User('1', 'Alice Updated');

      map.add(alice1);
      map.add(bob);
      expect(map.add(alice2), isTrue);

      expect(map.length, equals(2));
      expect(map[0], equals(alice2)); // Replaced at original position
      expect(map[1], equals(bob));
    });

    test('replaceMoveToEnd policy', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
      );
      final alice1 = User('1', 'Alice');
      final bob = User('2', 'Bob');
      final alice2 = User('1', 'Alice Updated');

      map.add(alice1);
      map.add(bob);
      expect(map.add(alice2), isTrue);

      expect(map.length, equals(2));
      expect(map[0], equals(bob));
      expect(map[1], equals(alice2)); // Moved to end
    });
  });

  group('Insertion Operations', () {
    late IndexedMap<User, String> map;
    late User alice, bob, carol;

    setUp(() {
      map = IndexedMap<User, String>();
      alice = User('1', 'Alice');
      bob = User('2', 'Bob');
      carol = User('3', 'Carol');
    });

    test('insertAt beginning', () {
      map.add(alice);
      map.add(bob);
      map.insertAt(0, carol);

      expect(map.length, equals(3));
      expect(map[0], equals(carol));
      expect(map[1], equals(alice));
      expect(map[2], equals(bob));
    });

    test('insertAt middle', () {
      map.add(alice);
      map.add(bob);
      map.insertAt(1, carol);

      expect(map.length, equals(3));
      expect(map[0], equals(alice));
      expect(map[1], equals(carol));
      expect(map[2], equals(bob));
    });

    test('insertAt end', () {
      map.add(alice);
      map.add(bob);
      map.insertAt(2, carol);

      expect(map.length, equals(3));
      expect(map[2], equals(carol));
    });

    test('insertAt with duplicate ID respects policy', () {
      map.add(alice);
      map.add(bob);
      final alice2 = User('1', 'Alice Updated');

      map.insertAt(1, alice2);

      // Default policy: replaceKeepPosition
      expect(map.length, equals(2));
      expect(map[0], equals(alice2)); // Replaced at original position
      expect(map[1], equals(bob));
    });
  });

  group('Removal Operations', () {
    late IndexedMap<User, String> map;
    late User alice, bob, carol;

    setUp(() {
      map = IndexedMap<User, String>();
      alice = User('1', 'Alice');
      bob = User('2', 'Bob');
      carol = User('3', 'Carol');
      map.add(alice);
      map.add(bob);
      map.add(carol);
    });

    test('removeById existing item', () {
      final removed = map.removeById('2');
      expect(removed, equals(bob));
      expect(map.length, equals(2));
      expect(map.getById('2'), isNull);
      expect(map[0], equals(alice));
      expect(map[1], equals(carol));
    });

    test('removeById non-existing item', () {
      final removed = map.removeById('999');
      expect(removed, isNull);
      expect(map.length, equals(3));
    });

    test('removeAt valid index', () {
      final removed = map.removeAt(1);
      expect(removed, equals(bob));
      expect(map.length, equals(2));
      expect(map.getById('2'), isNull);
      expect(map[0], equals(alice));
      expect(map[1], equals(carol));
    });

    test('removeAt throws on invalid index', () {
      expect(() => map.removeAt(-1), throwsRangeError);
      expect(() => map.removeAt(3), throwsRangeError);
    });
  });

  group('Update Operations', () {
    late IndexedMap<User, String> map;
    late User alice, bob, carol;

    setUp(() {
      map = IndexedMap<User, String>();
      alice = User('1', 'Alice');
      bob = User('2', 'Bob');
      carol = User('3', 'Carol');
      map.add(alice);
      map.add(bob);
      map.add(carol);
    });

    test('operator []= with same ID', () {
      final alice2 = User('1', 'Alice Updated');
      map[0] = alice2;

      expect(map.length, equals(3));
      expect(map[0], equals(alice2));
      expect(map.getById('1'), equals(alice2));
    });

    test('operator []= with different ID', () {
      final david = User('4', 'David');
      map[0] = david;

      expect(map.length, equals(3));
      expect(map[0], equals(david));
      expect(map.getById('1'), isNull); // Old ID removed
      expect(map.getById('4'), equals(david)); // New ID added
    });

    test('upsertKeepingPosition with existing ID unchanged', () {
      final alice2 = User('1', 'Alice Updated');
      final result = map.upsertKeepingPosition(oldId: '1', newItem: alice2);

      expect(result, isTrue);
      expect(map.length, equals(3));
      expect(map[0], equals(alice2)); // Same position
      expect(map.getById('1'), equals(alice2));
    });

    test('upsertKeepingPosition with ID change', () {
      final david = User('4', 'David');
      final result = map.upsertKeepingPosition(oldId: '1', newItem: david);

      expect(result, isTrue);
      expect(map.length, equals(3));
      expect(map[0], equals(david)); // Same position
      expect(map.getById('1'), isNull); // Old ID removed
      expect(map.getById('4'), equals(david)); // New ID added
    });

    test('upsertKeepingPosition with non-existing old ID', () {
      final david = User('4', 'David');
      final result = map.upsertKeepingPosition(oldId: '999', newItem: david);

      expect(result, isTrue);
      expect(map.length, equals(4));
      expect(map[3], equals(david)); // Added at end
    });
  });

  group('Movement Operations', () {
    late IndexedMap<User, String> map;
    late User alice, bob, carol;

    setUp(() {
      map = IndexedMap<User, String>();
      alice = User('1', 'Alice');
      bob = User('2', 'Bob');
      carol = User('3', 'Carol');
      map.add(alice);
      map.add(bob);
      map.add(carol);
    });

    test('moveIdTo forward', () {
      final result = map.moveIdTo('1', 2); // Move Alice to end

      expect(result, isTrue);
      expect(map[0], equals(bob));
      expect(map[1], equals(carol));
      expect(map[2], equals(alice));
    });

    test('moveIdTo backward', () {
      final result = map.moveIdTo('3', 0); // Move Carol to beginning

      expect(result, isTrue);
      expect(map[0], equals(carol));
      expect(map[1], equals(alice));
      expect(map[2], equals(bob));
    });

    test('moveIdTo same position', () {
      final result = map.moveIdTo('2', 1); // Bob stays at position 1

      expect(result, isFalse);
      expect(map[1], equals(bob)); // No change
    });

    test('moveIdTo non-existing ID', () {
      final result = map.moveIdTo('999', 0);

      expect(result, isFalse);
      expect(map.length, equals(3)); // No change
    });
  });

  group('Sorting Operations', () {
    test('sortBy name', () {
      final map = IndexedMap<User, String>();
      final users = [
        User('1', 'Charlie'),
        User('2', 'Alice'),
        User('3', 'Bob'),
      ];

      for (final user in users) {
        map.add(user);
      }

      map.sortBy((a, b) => a.name.compareTo(b.name));

      expect(map[0].name, equals('Alice'));
      expect(map[1].name, equals('Bob'));
      expect(map[2].name, equals('Charlie'));

      // IDs should still work
      expect(map.getById('2')?.name, equals('Alice'));
    });

    test('sortBy age', () {
      final map = IndexedMap<User, String>();
      final users = [
        User('1', 'Alice', age: 30),
        User('2', 'Bob', age: 25),
        User('3', 'Carol', age: 35),
      ];

      for (final user in users) {
        map.add(user);
      }

      map.sortBy((a, b) => a.age.compareTo(b.age));

      expect(map[0].age, equals(25));
      expect(map[1].age, equals(30));
      expect(map[2].age, equals(35));
    });
  });

  group('Query Operations', () {
    late IndexedMap<User, String> map;
    late User alice, bob, carol;

    setUp(() {
      map = IndexedMap<User, String>();
      alice = User('1', 'Alice');
      bob = User('2', 'Bob');
      carol = User('3', 'Carol');
      map.add(alice);
      map.add(bob);
      map.add(carol);
    });

    test('indexOfId existing', () {
      expect(map.indexOfId('1'), equals(0));
      expect(map.indexOfId('2'), equals(1));
      expect(map.indexOfId('3'), equals(2));
    });

    test('indexOfId non-existing', () {
      expect(map.indexOfId('999'), equals(-1));
    });

    test('values iterable', () {
      final values = map.values.toList();
      expect(values, equals([alice, bob, carol]));
    });

    test('toList defensive copy', () {
      final list = map.toList();
      expect(list, equals([alice, bob, carol]));

      // Modify original map
      map.add(User('4', 'David'));

      // List should be unchanged
      expect(list.length, equals(3));
    });

    test('wrappers view', () {
      final wrappers = map.wrappers;
      expect(wrappers.length, equals(3));
      expect(wrappers[0].item, equals(alice));
      expect(wrappers[0].id, equals('1'));

      // Should be unmodifiable
      expect(
        () => wrappers.add(ItemWrapper(User('4', 'David'))),
        throwsUnsupportedError,
      );
    });

    test('asMapView', () {
      final mapView = map.asMapView;
      expect(mapView['1']?.item, equals(alice));
      expect(mapView['2']?.item, equals(bob));

      // Should be unmodifiable
      expect(
        () => mapView['4'] = ItemWrapper(User('4', 'David')),
        throwsUnsupportedError,
      );
    });
  });

  group('Iteration', () {
    test('iterator', () {
      final map = IndexedMap<User, String>();
      final users = [User('1', 'Alice'), User('2', 'Bob'), User('3', 'Carol')];

      for (final user in users) {
        map.add(user);
      }

      final iterated = <User>[];
      for (final user in map) {
        iterated.add(user);
      }

      expect(iterated, equals(users));
    });

    test('iterable methods', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice', age: 25));
      map.add(User('2', 'Bob', age: 30));
      map.add(User('3', 'Carol', age: 28));

      // where
      final adults = map.where((user) => user.age >= 28).toList();
      expect(adults.length, equals(2));
      expect(adults.map((u) => u.name), containsAll(['Bob', 'Carol']));

      // map
      final names = map.map((user) => user.name).toList();
      expect(names, equals(['Alice', 'Bob', 'Carol']));

      // first
      expect(map.first.name, equals('Alice'));

      // last
      expect(map.last.name, equals('Carol'));
    });
  });

  group('Clear Operation', () {
    test('clear empties the map', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));

      expect(map.length, equals(2));

      map.clear();

      expect(map.length, equals(0));
      expect(map.isEmpty, isTrue);
      expect(map.getById('1'), isNull);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('out of bounds access throws', () {
      final map = IndexedMap<User, String>();
      expect(() => map[0], throwsRangeError);
      expect(() => map[-1], throwsRangeError);
    });

    test('works with different ID types', () {
      final map = IndexedMap<Product, int>();
      final products = [
        Product(1, 'Laptop', 999.99),
        Product(2, 'Mouse', 29.99),
        Product(3, 'Keyboard', 79.99),
      ];

      for (final product in products) {
        map.add(product);
      }

      expect(map.getById(2)?.name, equals('Mouse'));
      expect(map.indexOfId(3), equals(2));
    });

    test('handles null edge cases gracefully', () {
      final map = IndexedMap<User, String>();
      expect(map.getById('non-existent'), isNull);
      expect(map.getWrapperById('non-existent'), isNull);
      expect(map.removeById('non-existent'), isNull);
    });
  });

  group('ItemWrapper', () {
    test('wrapper properties', () {
      final user = User('1', 'Alice');
      final wrapper = ItemWrapper(user);

      expect(wrapper.item, equals(user));
      expect(wrapper.id, equals('1'));
      expect(wrapper.toString(), contains('ItemWrapper'));
      expect(wrapper.toString(), contains('1'));
      expect(wrapper.toString(), contains('Alice'));
    });
  });

  group('Real-world Scenarios', () {
    test('chat message management', () {
      final messages = IndexedMap<Message, String>();

      // Add messages in chronological order
      messages.add(Message('msg1', 'Hello'));
      messages.add(Message('msg2', 'How are you?'));
      messages.add(Message('msg3', 'Fine, thanks!'));

      // Quick lookup by ID
      expect(messages.getById('msg2')?.content, equals('How are you?'));

      // Edit a message (replace in place)
      messages[1] = Message('msg2', 'How are you doing?');
      expect(messages[1].content, equals('How are you doing?'));

      // Insert a message in the middle (like a delayed message)
      messages.insertAt(1, Message('msg4', 'Actually...'));
      expect(messages.length, equals(4));
      expect(messages[1].content, equals('Actually...'));
    });

    test('user management with recent activity', () {
      final users = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
      );

      // Add users
      users.add(User('alice', 'Alice'));
      users.add(User('bob', 'Bob'));
      users.add(User('carol', 'Carol'));

      // Alice becomes active (moves to end)
      users.add(User('alice', 'Alice Active'));

      expect(users.last.name, equals('Alice Active'));
      expect(users.indexOfId('alice'), equals(2)); // Moved to end
    });
  });
}

// Helper class for testing
class Message implements MapIndexable<String> {
  final String id;
  final String content;
  final DateTime timestamp;

  Message(this.id, this.content) : timestamp = DateTime.now();

  @override
  String get indexId => id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content;

  @override
  int get hashCode => Object.hash(id, content);

  @override
  String toString() => 'Message($id, $content)';
}
