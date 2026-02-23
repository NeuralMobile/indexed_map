import 'package:indexed_map/indexed_map.dart';
import 'package:test/test.dart';
import 'dart:math';

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

    test('insertAt with replaceMoveToEnd adjusts index correctly', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
      );
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      // Insert duplicate of Alice at position 2 with move-to-end policy
      map.insertAt(2, User('1', 'Alice Updated'));

      expect(map.length, equals(3));
      // Alice was at 0, removed (shifting Bob to 0, Carol to 1),
      // then inserted at adjusted index
      expect(map.getById('1')?.name, equals('Alice Updated'));
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

    test('removeById updates indexOfId correctly for remaining items', () {
      map.removeById('1');
      expect(map.indexOfId('2'), equals(0));
      expect(map.indexOfId('3'), equals(1));
      expect(map.indexOfId('1'), equals(-1));
    });
  });

  group('removeWhere', () {
    test('removes items matching predicate', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice', age: 25));
      map.add(User('2', 'Bob', age: 30));
      map.add(User('3', 'Carol', age: 28));
      map.add(User('4', 'Dave', age: 20));

      final count = map.removeWhere((user) => user.age < 27);

      expect(count, equals(2));
      expect(map.length, equals(2));
      expect(map[0].name, equals('Bob'));
      expect(map[1].name, equals('Carol'));
      expect(map.containsId('1'), isFalse);
      expect(map.containsId('4'), isFalse);
      expect(map.indexOfId('2'), equals(0));
      expect(map.indexOfId('3'), equals(1));
    });

    test('returns 0 when nothing matches', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice', age: 25));

      final count = map.removeWhere((user) => user.age > 100);
      expect(count, equals(0));
      expect(map.length, equals(1));
    });

    test('works on empty map', () {
      final map = IndexedMap<User, String>();
      final count = map.removeWhere((user) => true);
      expect(count, equals(0));
    });
  });

  group('addAll', () {
    test('adds all items', () {
      final map = IndexedMap<User, String>();
      final users = [User('1', 'Alice'), User('2', 'Bob'), User('3', 'Carol')];
      final count = map.addAll(users);

      expect(count, equals(3));
      expect(map.length, equals(3));
      expect(map[0].name, equals('Alice'));
      expect(map[2].name, equals('Carol'));
    });

    test('handles duplicates according to policy', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.ignore,
      );
      map.add(User('1', 'Alice'));
      final count = map.addAll([
        User('1', 'Alice Updated'), // duplicate
        User('2', 'Bob'),
      ]);

      expect(count, equals(1)); // Only Bob was added
      expect(map.length, equals(2));
      expect(map.getById('1')?.name, equals('Alice')); // Original kept
    });

    test('addAll with empty iterable', () {
      final map = IndexedMap<User, String>();
      final count = map.addAll([]);
      expect(count, equals(0));
      expect(map.length, equals(0));
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
      expect(map.indexOfId('1'), equals(0));
    });

    test('operator []= with different ID', () {
      final david = User('4', 'David');
      map[0] = david;

      expect(map.length, equals(3));
      expect(map[0], equals(david));
      expect(map.getById('1'), isNull); // Old ID removed
      expect(map.getById('4'), equals(david)); // New ID added
      expect(map.indexOfId('4'), equals(0));
    });

    test('operator []= with ID collision at different index', () {
      // map: [Alice(1), Bob(2), Carol(3)]
      // Set index 0 to an item with Bob's ID (2)
      final bobUpdated = User('2', 'Bob Replacement');
      map[0] = bobUpdated;

      // Alice(1) should be removed, Bob(2) at old position removed,
      // new item inserted at position 0
      expect(map.containsId('1'), isFalse); // Alice removed
      expect(map.getById('2')?.name, equals('Bob Replacement'));
      expect(map.containsId('3'), isTrue); // Carol still there

      // Full state consistency: length, indexOfId, and no orphans
      expect(map.length, equals(2));
      expect(map.indexOfId('2'), equals(0));
      expect(map.indexOfId('3'), equals(1));
      expect(map.indexOfId('1'), equals(-1));
      // Verify every list slot has a matching _map entry
      for (var i = 0; i < map.length; i++) {
        final item = map[i];
        expect(map.containsId(item.indexId), isTrue);
        expect(map.indexOfId(item.indexId), equals(i));
      }
    });

    test('upsertKeepingPosition with existing ID unchanged', () {
      final alice2 = User('1', 'Alice Updated');
      final result = map.upsertKeepingPosition(oldId: '1', newItem: alice2);

      expect(result, isTrue);
      expect(map.length, equals(3));
      expect(map[0], equals(alice2)); // Same position
      expect(map.getById('1'), equals(alice2));
      expect(map.indexOfId('1'), equals(0));
    });

    test('upsertKeepingPosition with ID change', () {
      final david = User('4', 'David');
      final result = map.upsertKeepingPosition(oldId: '1', newItem: david);

      expect(result, isTrue);
      expect(map.length, equals(3));
      expect(map[0], equals(david)); // Same position
      expect(map.getById('1'), isNull); // Old ID removed
      expect(map.getById('4'), equals(david)); // New ID added
      expect(map.indexOfId('4'), equals(0));
    });

    test('upsertKeepingPosition with non-existing old ID', () {
      final david = User('4', 'David');
      final result = map.upsertKeepingPosition(oldId: '999', newItem: david);

      expect(result, isTrue);
      expect(map.length, equals(4));
      expect(map[3], equals(david)); // Added at end
    });

    test('upsertKeepingPosition with new ID colliding with existing entry', () {
      // map: [Alice(1), Bob(2), Carol(3)]
      // Upsert oldId=1, newItem has id=2 (collision with Bob)
      final newItem = User('2', 'Replacement for Bob at Alice position');
      final result = map.upsertKeepingPosition(oldId: '1', newItem: newItem);

      expect(result, isTrue);
      expect(map.containsId('1'), isFalse); // Alice's old ID gone
      expect(
        map.getById('2')?.name,
        equals('Replacement for Bob at Alice position'),
      );
      expect(map.containsId('3'), isTrue); // Carol still there
      // Total count should be 2 (Bob replaced, Alice removed)
      expect(map.length, equals(2));
    });

    test('operator []= collision where colliding entry is BEFORE target', () {
      // map: [a@0, b@1, c@2, d@3]
      final map = IndexedMap<User, String>();
      map.add(User('a', 'Alice'));
      map.add(User('b', 'Bob'));
      map.add(User('c', 'Carol'));
      map.add(User('d', 'Dave'));

      // Replace c(index 2) with new item that has id 'a' (collision at index 0)
      map[2] = User('a', 'New-A');

      // c is removed, collision a(at 0) is removed, new item goes where c was
      // (adjusted: index 2 - 1 = 1, since collision was before target)
      // Expected: [b, New-A, d]
      expect(map.length, equals(3));
      expect(map[0].name, equals('Bob'));
      expect(map[1].name, equals('New-A'));
      expect(map[2].name, equals('Dave'));

      expect(map.containsId('c'), isFalse);
      expect(map.indexOfId('a'), equals(1));
      expect(map.indexOfId('b'), equals(0));
      expect(map.indexOfId('d'), equals(2));
    });

    test('operator []= collision where colliding entry is AFTER target', () {
      // map: [a@0, b@1, c@2, d@3]
      final map = IndexedMap<User, String>();
      map.add(User('a', 'Alice'));
      map.add(User('b', 'Bob'));
      map.add(User('c', 'Carol'));
      map.add(User('d', 'Dave'));

      // Replace a(index 0) with new item that has id 'c' (collision at index 2)
      map[0] = User('c', 'New-C');

      // a is removed, collision c(at 2) is removed, new item goes at index 0
      // (no adjustment needed since collision was after target)
      // Expected: [New-C, b, d]
      expect(map.length, equals(3));
      expect(map[0].name, equals('New-C'));
      expect(map[1].name, equals('Bob'));
      expect(map[2].name, equals('Dave'));

      expect(map.containsId('a'), isFalse);
      expect(map.indexOfId('c'), equals(0));
      expect(map.indexOfId('b'), equals(1));
      expect(map.indexOfId('d'), equals(2));
    });

    test(
      'upsertKeepingPosition collision where colliding entry is BEFORE target',
      () {
        // map: [a@0, b@1, c@2, d@3]
        final map = IndexedMap<User, String>();
        map.add(User('a', 'Alice'));
        map.add(User('b', 'Bob'));
        map.add(User('c', 'Carol'));
        map.add(User('d', 'Dave'));

        // Upsert oldId='c', newItem has id='a' (collision at index 0, before target at 2)
        map.upsertKeepingPosition(oldId: 'c', newItem: User('a', 'New-A'));

        // c removed, a(at 0) removed, new item at adjusted pos (2-1=1)
        // Expected: [b, New-A, d]
        expect(map.length, equals(3));
        expect(map[0].name, equals('Bob'));
        expect(map[1].name, equals('New-A'));
        expect(map[2].name, equals('Dave'));

        expect(map.containsId('c'), isFalse);
        expect(map.indexOfId('a'), equals(1));
        expect(map.indexOfId('b'), equals(0));
        expect(map.indexOfId('d'), equals(2));
      },
    );

    test(
      'upsertKeepingPosition collision where colliding entry is AFTER target',
      () {
        // map: [a@0, b@1, c@2, d@3]
        final map = IndexedMap<User, String>();
        map.add(User('a', 'Alice'));
        map.add(User('b', 'Bob'));
        map.add(User('c', 'Carol'));
        map.add(User('d', 'Dave'));

        // Upsert oldId='a', newItem has id='c' (collision at index 2, after target at 0)
        map.upsertKeepingPosition(oldId: 'a', newItem: User('c', 'New-C'));

        // a removed, c(at 2) removed, new item at pos 0 (no adjustment)
        // Expected: [New-C, b, d]
        expect(map.length, equals(3));
        expect(map[0].name, equals('New-C'));
        expect(map[1].name, equals('Bob'));
        expect(map[2].name, equals('Dave'));

        expect(map.containsId('a'), isFalse);
        expect(map.indexOfId('c'), equals(0));
        expect(map.indexOfId('b'), equals(1));
        expect(map.indexOfId('d'), equals(2));
      },
    );
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
      expect(map.indexOfId('1'), equals(2));
      expect(map.indexOfId('2'), equals(0));
    });

    test('moveIdTo backward', () {
      final result = map.moveIdTo('3', 0); // Move Carol to beginning

      expect(result, isTrue);
      expect(map[0], equals(carol));
      expect(map[1], equals(alice));
      expect(map[2], equals(bob));
      expect(map.indexOfId('3'), equals(0));
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

    test('moveIdTo with out-of-bounds toIndex returns false', () {
      expect(map.moveIdTo('1', -1), isFalse);
      expect(map.moveIdTo('1', 3), isFalse); // >= length
      expect(map.moveIdTo('1', 100), isFalse);
      // Map should be unchanged
      expect(map[0], equals(alice));
      expect(map[1], equals(bob));
      expect(map[2], equals(carol));
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
      // indexOfId should be correct after sort
      expect(map.indexOfId('2'), equals(0));
      expect(map.indexOfId('3'), equals(1));
      expect(map.indexOfId('1'), equals(2));
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

    test('sortBy on empty map does not throw', () {
      final map = IndexedMap<User, String>();
      map.sortBy((a, b) => a.name.compareTo(b.name));
      expect(map.isEmpty, isTrue);
    });

    test('sortBy on single-element map', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.sortBy((a, b) => a.name.compareTo(b.name));
      expect(map.length, equals(1));
      expect(map[0].name, equals('Alice'));
      expect(map.indexOfId('1'), equals(0));
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

    test('indexOfId is O(1) via reverse index', () {
      // Verify it works correctly after various mutations
      map.removeById('2');
      expect(map.indexOfId('1'), equals(0));
      expect(map.indexOfId('3'), equals(1));
      expect(map.indexOfId('2'), equals(-1));
    });

    test('values iterable', () {
      final values = map.values.toList();
      expect(values, equals([alice, bob, carol]));
    });

    test('keys iterable', () {
      final keys = map.keys.toList();
      expect(keys, equals(['1', '2', '3']));
    });

    test('toList defensive copy', () {
      final list = map.toList();
      expect(list, equals([alice, bob, carol]));

      // Modify original map
      map.add(User('4', 'David'));

      // List should be unchanged
      expect(list.length, equals(3));
    });

    test('toList growable parameter', () {
      final nonGrowable = map.toList(growable: false);
      expect(() => nonGrowable.add(User('x', 'X')), throwsUnsupportedError);

      final growable = map.toList(growable: true);
      growable.add(User('x', 'X'));
      expect(growable.length, equals(4));
    });

    test('toMap returns id-to-item map', () {
      final result = map.toMap();
      expect(result.length, equals(3));
      expect(result['1'], equals(alice));
      expect(result['2'], equals(bob));
      expect(result['3'], equals(carol));
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

    test('contains uses O(1) id lookup', () {
      expect(map.contains(alice), isTrue);
      expect(map.contains(User('1', 'Alice')), isTrue); // same id
      expect(map.contains(User('999', 'Nobody')), isFalse);
    });

    test('contains returns false for non-T types', () {
      // ignore: collection_methods_unrelated_type
      expect(map.contains('not a user'), isFalse);
      // ignore: collection_methods_unrelated_type
      expect(map.contains(42), isFalse);
      expect(map.contains(null), isFalse);
    });
  });

  group('first and last', () {
    test('first returns first item', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      expect(map.first, equals(User('1', 'Alice')));
    });

    test('last returns last item', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      expect(map.last, equals(User('2', 'Bob')));
    });

    test('first throws on empty map', () {
      final map = IndexedMap<User, String>();
      expect(() => map.first, throwsStateError);
    });

    test('last throws on empty map', () {
      final map = IndexedMap<User, String>();
      expect(() => map.last, throwsStateError);
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

    test('iterator on empty map', () {
      final map = IndexedMap<User, String>();
      final iterated = <User>[];
      for (final user in map) {
        iterated.add(user);
      }
      expect(iterated, isEmpty);
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
      expect(map.indexOfId('1'), equals(-1));
    });
  });

  group('toString', () {
    test('toString on empty map', () {
      final map = IndexedMap<User, String>();
      expect(map.toString(), equals('IndexedMap()'));
    });

    test('toString shows entries', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      final str = map.toString();
      expect(str, startsWith('IndexedMap('));
      expect(str, contains('1:'));
      expect(str, contains('2:'));
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

    test('single-element removal', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      final removed = map.removeById('1');
      expect(removed?.name, equals('Alice'));
      expect(map.isEmpty, isTrue);
      expect(map.indexOfId('1'), equals(-1));
    });

    test('single-element map operations', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));

      expect(map.first.name, equals('Alice'));
      expect(map.last.name, equals('Alice'));
      expect(map.length, equals(1));

      map.sortBy((a, b) => a.name.compareTo(b.name));
      expect(map[0].name, equals('Alice'));
      expect(map.indexOfId('1'), equals(0));
    });

    test('empty map views', () {
      final map = IndexedMap<User, String>();
      expect(map.values.toList(), isEmpty);
      expect(map.keys.toList(), isEmpty);
      expect(map.wrappers, isEmpty);
      expect(map.asMapView, isEmpty);
      expect(map.toList(), isEmpty);
      expect(map.toMap(), isEmpty);
    });

    test('indexOfId consistency through multiple operations', () {
      final map = IndexedMap<User, String>();
      map.add(User('a', 'Alice'));
      map.add(User('b', 'Bob'));
      map.add(User('c', 'Carol'));
      map.add(User('d', 'Dave'));

      // Verify initial indices
      expect(map.indexOfId('a'), equals(0));
      expect(map.indexOfId('b'), equals(1));
      expect(map.indexOfId('c'), equals(2));
      expect(map.indexOfId('d'), equals(3));

      // Remove from middle
      map.removeById('b');
      expect(map.indexOfId('a'), equals(0));
      expect(map.indexOfId('b'), equals(-1));
      expect(map.indexOfId('c'), equals(1));
      expect(map.indexOfId('d'), equals(2));

      // Insert at beginning
      map.insertAt(0, User('e', 'Eve'));
      expect(map.indexOfId('e'), equals(0));
      expect(map.indexOfId('a'), equals(1));
      expect(map.indexOfId('c'), equals(2));
      expect(map.indexOfId('d'), equals(3));

      // Sort
      map.sortBy((a, b) => a.name.compareTo(b.name));
      // Alice, Carol, Dave, Eve
      expect(map.indexOfId('a'), equals(0));
      expect(map.indexOfId('c'), equals(1));
      expect(map.indexOfId('d'), equals(2));
      expect(map.indexOfId('e'), equals(3));

      // Move
      map.moveIdTo('a', 3);
      // Carol, Dave, Eve, Alice
      expect(map.indexOfId('c'), equals(0));
      expect(map.indexOfId('d'), equals(1));
      expect(map.indexOfId('e'), equals(2));
      expect(map.indexOfId('a'), equals(3));
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

    test('bulk operations workflow', () {
      final map = IndexedMap<User, String>();

      // Bulk add
      final count = map.addAll([
        User('1', 'Alice', age: 25),
        User('2', 'Bob', age: 30),
        User('3', 'Carol', age: 22),
        User('4', 'Dave', age: 35),
        User('5', 'Eve', age: 28),
      ]);
      expect(count, equals(5));

      // Bulk remove young users
      final removed = map.removeWhere((u) => u.age < 25);
      expect(removed, equals(1)); // Carol
      expect(map.length, equals(4));

      // Verify indices are consistent
      for (var i = 0; i < map.length; i++) {
        expect(map.indexOfId(map[i].indexId), equals(i));
      }
    });
  });

  group('Concurrent modification detection', () {
    test('add during iteration throws ConcurrentModificationError', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));

      expect(() {
        for (final _ in map) {
          map.add(User('3', 'Carol'));
        }
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('removeById during iteration throws ConcurrentModificationError', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      expect(() {
        for (final user in map) {
          if (user.id == '2') {
            map.removeById('2');
          }
        }
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('operator []= same-id replacement during iteration does NOT throw '
        '(non-structural)', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));

      // Same-id in-place replacement is non-structural — iterator stays valid.
      final results = <String>[];
      for (final user in map) {
        results.add(user.name);
        if (user.id == '1') {
          map[0] = User('1', 'Alice Updated');
        }
      }
      expect(results, equals(['Alice', 'Bob']));
      expect(map[0].name, equals('Alice Updated'));
    });

    test('operator []= with id change during iteration throws '
        'ConcurrentModificationError (structural)', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      // Different-id with collision is structural — iterator must fail.
      expect(() {
        for (final _ in map) {
          map[2] = User('1', 'New-A'); // collision: structural change
        }
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('sortBy during iteration throws ConcurrentModificationError', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));

      expect(() {
        for (final _ in map) {
          map.sortBy((a, b) => a.name.compareTo(b.name));
        }
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('clear during iteration throws ConcurrentModificationError', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));

      expect(() {
        for (final _ in map) {
          map.clear();
        }
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('non-mutating access during iteration is fine', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));

      // These should not throw
      final results = <String>[];
      for (final user in map) {
        results.add(user.name);
        map.getById('1'); // read-only
        map.containsId('1'); // read-only
        map.indexOfId('1'); // read-only
      }
      expect(results, equals(['Alice', 'Bob']));
    });
  });

  group('removeWhere single-pass safety', () {
    test('removeWhere with stateful predicate evaluates each item once', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice', age: 25));
      map.add(User('2', 'Bob', age: 30));
      map.add(User('3', 'Carol', age: 28));

      var callCount = 0;
      final removed = map.removeWhere((user) {
        callCount++;
        return user.age < 28;
      });

      expect(removed, equals(1)); // Only Alice
      expect(callCount, equals(3)); // Evaluated exactly once per item
      expect(map.length, equals(2));
      expect(map[0].name, equals('Bob'));
      expect(map[1].name, equals('Carol'));

      // Full state consistency
      expect(map.indexOfId('2'), equals(0));
      expect(map.indexOfId('3'), equals(1));
      expect(map.indexOfId('1'), equals(-1));
      expect(map.containsId('1'), isFalse);
    });

    test('removeWhere with toggling predicate is consistent', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      // Predicate that flips each call — only first evaluation matters.
      var toggle = true;
      final removed = map.removeWhere((_) {
        final result = toggle;
        toggle = !toggle;
        return result;
      });

      // With single-pass: Alice(true), Bob(false), Carol(true) → 2 removed
      expect(removed, equals(2));
      expect(map.length, equals(1));
      expect(map[0].name, equals('Bob'));
      expect(map.indexOfId('2'), equals(0));
    });
  });

  group('Deprecated constructor params', () {
    test('deprecated map and list params are accepted but ignored', () {
      // ignore: deprecated_member_use_from_same_package
      final map = IndexedMap<User, String>(
        // ignore: deprecated_member_use_from_same_package
        map: {'1': ItemWrapper(User('1', 'External'))},
        // ignore: deprecated_member_use_from_same_package
        list: [ItemWrapper(User('1', 'External'))],
      );

      // The passed-in map/list should be ignored — IndexedMap should be empty
      expect(map.isEmpty, isTrue);
      expect(map.length, equals(0));
    });
  });

  group('contains semantics', () {
    test('contains matches by ID, not by equality', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice', age: 25));

      // Different object, same ID → true (ID-based lookup)
      expect(map.contains(User('1', 'Alice Modified', age: 99)), isTrue);

      // Different ID → false
      expect(map.contains(User('2', 'Alice', age: 25)), isFalse);
    });
  });

  group('removeWhere re-entrant mutation safety', () {
    test('removeWhere throws if predicate mutates the map', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      expect(() {
        map.removeWhere((user) {
          if (user.id == '2') {
            map.add(User('4', 'Dave')); // structural mutation inside predicate
          }
          return false;
        });
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('removeWhere throws if predicate clears the map', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      expect(() {
        map.removeWhere((user) {
          if (user.id == '1') {
            map.clear();
          }
          return false;
        });
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('removeWhere throws if predicate removes by id', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      expect(() {
        map.removeWhere((user) {
          if (user.id == '1') {
            map.removeById('2');
          }
          return false;
        });
      }, throwsA(isA<ConcurrentModificationError>()));
    });

    test('removeWhere allows non-structural replacement during predicate '
        '(same id)', () {
      final map = IndexedMap<User, String>();
      map.add(User('1', 'Alice', age: 20));
      map.add(User('2', 'Bob', age: 30));
      map.add(User('3', 'Carol', age: 40));

      final removed = map.removeWhere((user) {
        if (user.id == '1') {
          map[0] = User('1', 'Alice Updated', age: 21);
        }
        return user.age >= 40;
      });

      expect(removed, equals(1));
      expect(map.length, equals(2));
      expect(map[0].name, equals('Alice Updated'));
      expect(map.indexOfId('1'), equals(0));
      expect(map.indexOfId('2'), equals(1));
      expect(map.indexOfId('3'), equals(-1));
    });
  });

  group('Bulk operation edge cases', () {
    test('addAll(self) in replaceKeepPosition policy is stable', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.replaceKeepPosition,
      );
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      final count = map.addAll(map);
      expect(count, equals(3));
      expect(map.length, equals(3));
      expect(map.keys.toList(), equals(['1', '2', '3']));
    });

    test('addAll(self) in replaceMoveToEnd policy throws', () {
      final map = IndexedMap<User, String>(
        duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
      );
      map.add(User('1', 'Alice'));
      map.add(User('2', 'Bob'));
      map.add(User('3', 'Carol'));

      expect(
        () => map.addAll(map),
        throwsA(isA<ConcurrentModificationError>()),
      );
    });

    test(
      'addAll from lazy iterable view handles duplicate replacement count',
      () {
        final map = IndexedMap<User, String>();
        map.add(User('1', 'Alice'));
        map.add(User('2', 'Bob'));

        final transformed = map.values.map(
          (u) => User(u.id, '${u.name} copy', age: u.age + 1),
        );
        final count = map.addAll(transformed);

        expect(count, equals(2));
        expect(map.length, equals(2));
        expect(map[0].name, equals('Alice copy'));
        expect(map[1].name, equals('Bob copy'));
      },
    );
  });

  group('Deep invariant stress tests', () {
    test('randomized differential test: replaceKeepPosition', () {
      _runRandomizedDifferentialTest(DuplicatePolicy.replaceKeepPosition, 2026);
    });

    test('randomized differential test: ignore', () {
      _runRandomizedDifferentialTest(DuplicatePolicy.ignore, 2027);
    });

    test('randomized differential test: replaceMoveToEnd', () {
      _runRandomizedDifferentialTest(DuplicatePolicy.replaceMoveToEnd, 2028);
    });

    test('multi-seed sweep: replaceKeepPosition', () {
      for (var seed = 3000; seed < 3040; seed++) {
        _runRandomizedDifferentialTest(
          DuplicatePolicy.replaceKeepPosition,
          seed,
          steps: 600,
        );
      }
    });

    test('multi-seed sweep: ignore', () {
      for (var seed = 4000; seed < 4040; seed++) {
        _runRandomizedDifferentialTest(
          DuplicatePolicy.ignore,
          seed,
          steps: 600,
        );
      }
    });

    test('multi-seed sweep: replaceMoveToEnd', () {
      for (var seed = 5000; seed < 5040; seed++) {
        _runRandomizedDifferentialTest(
          DuplicatePolicy.replaceMoveToEnd,
          seed,
          steps: 600,
        );
      }
    });
  });
}

void _runRandomizedDifferentialTest(
  DuplicatePolicy policy,
  int seed, {
  int steps = 400,
}) {
  final rng = Random(seed);
  final map = IndexedMap<User, String>(duplicatePolicy: policy);
  final ref = _RefIndexedMap(policy);
  var serial = 0;

  User nextUser({String? forcedId}) {
    final id = forcedId ?? 'id_${rng.nextInt(8)}';
    serial++;
    return User(id, 'Name_$serial', age: serial % 100);
  }

  for (var step = 0; step < steps; step++) {
    final op = rng.nextInt(9);
    switch (op) {
      case 0:
        // add
        final user = nextUser();
        expect(map.add(user), equals(ref.add(user)), reason: 'step=$step add');
      case 1:
        // insertAt
        final user = nextUser();
        final index = map.isEmpty ? 0 : rng.nextInt(map.length + 1);
        map.insertAt(index, user);
        ref.insertAt(index, user);
      case 2:
        // removeById
        final id = 'id_${rng.nextInt(8)}';
        expect(
          map.removeById(id),
          equals(ref.removeById(id)),
          reason: 'step=$step removeById($id)',
        );
      case 3:
        // removeAt (if possible)
        if (map.isNotEmpty) {
          final idx = rng.nextInt(map.length);
          expect(
            map.removeAt(idx),
            equals(ref.removeAt(idx)),
            reason: 'step=$step removeAt($idx)',
          );
        }
      case 4:
        // moveIdTo
        final id = 'id_${rng.nextInt(8)}';
        final to = map.isEmpty
            ? 0
            : rng.nextInt(map.length + 3) - 1; // includes OOB
        expect(
          map.moveIdTo(id, to),
          equals(ref.moveIdTo(id, to)),
          reason: 'step=$step moveIdTo($id,$to)',
        );
      case 5:
        // operator []=
        if (map.isNotEmpty) {
          final idx = rng.nextInt(map.length);
          final useExistingId = rng.nextBool();
          final forcedId = useExistingId && map.isNotEmpty
              ? map[rng.nextInt(map.length)].id
              : null;
          final user = nextUser(forcedId: forcedId);
          map[idx] = user;
          ref.setAt(idx, user);
        }
      case 6:
        // upsertKeepingPosition
        final oldId = map.isNotEmpty && rng.nextBool()
            ? map[rng.nextInt(map.length)].id
            : 'id_${rng.nextInt(8)}';
        final forcedId = map.isNotEmpty && rng.nextBool()
            ? map[rng.nextInt(map.length)].id
            : null;
        final user = nextUser(forcedId: forcedId);
        expect(
          map.upsertKeepingPosition(oldId: oldId, newItem: user),
          equals(ref.upsertKeepingPosition(oldId: oldId, newItem: user)),
          reason: 'step=$step upsert(old:$oldId,new:${user.id})',
        );
      case 7:
        // sortBy
        map.sortBy((a, b) => a.id.compareTo(b.id));
        ref.sortById();
      case 8:
        // removeWhere (deterministic predicate by age parity threshold)
        final threshold = rng.nextInt(4);
        final removedMap = map.removeWhere((u) => u.age % 4 == threshold);
        final removedRef = ref.removeWhere((u) => u.age % 4 == threshold);
        expect(
          removedMap,
          equals(removedRef),
          reason: 'step=$step removeWhere threshold=$threshold',
        );
    }

    _assertInvariants(
      map: map,
      expectedValues: ref.toList(),
      reason: 'policy=$policy step=$step op=$op',
    );
  }
}

void _assertInvariants({
  required IndexedMap<User, String> map,
  required List<User> expectedValues,
  required String reason,
}) {
  expect(map.length, equals(expectedValues.length), reason: reason);
  expect(map.toList(), equals(expectedValues), reason: reason);
  expect(map.values.toList(), equals(expectedValues), reason: reason);
  expect(map.keys.toList(), equals(expectedValues.map((u) => u.id).toList()));

  final toMap = map.toMap();
  expect(toMap.length, equals(expectedValues.length), reason: reason);
  for (var i = 0; i < expectedValues.length; i++) {
    final item = expectedValues[i];
    expect(map[i], equals(item), reason: '$reason at index=$i');
    expect(map.indexOfId(item.id), equals(i), reason: '$reason id=${item.id}');
    expect(map.containsId(item.id), isTrue, reason: '$reason id=${item.id}');
    expect(map.getById(item.id), equals(item), reason: '$reason id=${item.id}');
    expect(toMap[item.id], equals(item), reason: '$reason id=${item.id}');
  }

  final allIds = <String>{for (final u in expectedValues) u.id};
  for (var idNum = 0; idNum < 8; idNum++) {
    final id = 'id_$idNum';
    final exists = allIds.contains(id);
    expect(map.containsId(id), equals(exists), reason: '$reason id=$id');
    if (!exists) {
      expect(map.indexOfId(id), equals(-1), reason: '$reason id=$id');
      expect(map.getById(id), isNull, reason: '$reason id=$id');
    }
  }

  if (expectedValues.isEmpty) {
    expect(map.isEmpty, isTrue, reason: reason);
  } else {
    expect(map.isNotEmpty, isTrue, reason: reason);
    expect(map.first, equals(expectedValues.first), reason: reason);
    expect(map.last, equals(expectedValues.last), reason: reason);
  }
}

class _RefIndexedMap {
  final DuplicatePolicy _policy;
  final List<User> _list = <User>[];
  final Map<String, User> _map = <String, User>{};
  final Map<String, int> _index = <String, int>{};

  _RefIndexedMap(this._policy);

  List<User> toList() => List<User>.of(_list);

  bool add(User item) {
    final id = item.id;
    final existingIdx = _index[id];
    if (existingIdx == null) {
      _list.add(item);
      _map[id] = item;
      _index[id] = _list.length - 1;
      return true;
    }

    switch (_policy) {
      case DuplicatePolicy.ignore:
        return false;
      case DuplicatePolicy.replaceKeepPosition:
        _list[existingIdx] = item;
        _map[id] = item;
        return true;
      case DuplicatePolicy.replaceMoveToEnd:
        _list.removeAt(existingIdx);
        _list.add(item);
        _map[id] = item;
        _rebuildIndex();
        return true;
    }
  }

  void insertAt(int index, User item) {
    final existingIdx = _index[item.id];
    if (existingIdx == null) {
      _list.insert(index, item);
      _map[item.id] = item;
      _rebuildIndex();
      return;
    }

    switch (_policy) {
      case DuplicatePolicy.ignore:
        return;
      case DuplicatePolicy.replaceKeepPosition:
        _list[existingIdx] = item;
        _map[item.id] = item;
      case DuplicatePolicy.replaceMoveToEnd:
        _list.removeAt(existingIdx);
        final adjustedIndex = existingIdx < index ? index - 1 : index;
        final clampedIndex = adjustedIndex.clamp(0, _list.length);
        _list.insert(clampedIndex, item);
        _map[item.id] = item;
        _rebuildIndex();
    }
  }

  User? removeById(String id) {
    final idx = _index[id];
    if (idx == null) return null;
    final removed = _list.removeAt(idx);
    _map.remove(id);
    _index.remove(id);
    _rebuildIndex();
    return removed;
  }

  User removeAt(int index) {
    final removed = _list.removeAt(index);
    _map.remove(removed.id);
    _index.remove(removed.id);
    _rebuildIndex();
    return removed;
  }

  bool moveIdTo(String id, int toIndex) {
    final from = _index[id];
    if (from == null || from == toIndex) return false;
    if (toIndex < 0 || toIndex >= _list.length) return false;
    final item = _list.removeAt(from);
    _list.insert(toIndex, item);
    _rebuildIndex();
    return true;
  }

  void sortById() {
    _list.sort((a, b) => a.id.compareTo(b.id));
    _rebuildIndex();
  }

  void setAt(int index, User newItem) {
    final old = _list[index];
    final oldId = old.id;
    final newId = newItem.id;
    if (oldId == newId) {
      _list[index] = newItem;
      _map[newId] = newItem;
      return;
    }

    _map.remove(oldId);
    _index.remove(oldId);
    final existingIdx = _index[newId];
    if (existingIdx != null) {
      _map.remove(newId);
      _index.remove(newId);
      if (index > existingIdx) {
        _list.removeAt(index);
        _list.removeAt(existingIdx);
      } else {
        _list.removeAt(existingIdx);
        _list.removeAt(index);
      }
      final insertIdx = (existingIdx < index ? index - 1 : index).clamp(
        0,
        _list.length,
      );
      _list.insert(insertIdx, newItem);
      _map[newId] = newItem;
      _rebuildIndex();
    } else {
      _list[index] = newItem;
      _map[newId] = newItem;
      _index[newId] = index;
    }
  }

  bool upsertKeepingPosition({required String oldId, required User newItem}) {
    final oldPos = _index[oldId];
    if (oldPos == null) return add(newItem);
    final newId = newItem.id;

    if (newId == oldId) {
      _list[oldPos] = newItem;
      _map[newId] = newItem;
      return true;
    }

    _map.remove(oldId);
    _index.remove(oldId);

    final existingIdx = _index[newId];
    if (existingIdx != null) {
      _map.remove(newId);
      _index.remove(newId);
      if (oldPos > existingIdx) {
        _list.removeAt(oldPos);
        _list.removeAt(existingIdx);
      } else {
        _list.removeAt(existingIdx);
        _list.removeAt(oldPos);
      }
      final insertPos = (existingIdx < oldPos ? oldPos - 1 : oldPos).clamp(
        0,
        _list.length,
      );
      _list.insert(insertPos, newItem);
      _map[newId] = newItem;
      _rebuildIndex();
    } else {
      _list[oldPos] = newItem;
      _map[newId] = newItem;
      _index[newId] = oldPos;
    }
    return true;
  }

  int removeWhere(bool Function(User item) test) {
    final indices = <int>[];
    for (var i = 0; i < _list.length; i++) {
      if (test(_list[i])) {
        indices.add(i);
      }
    }
    for (var i = indices.length - 1; i >= 0; i--) {
      final idx = indices[i];
      final removed = _list.removeAt(idx);
      _map.remove(removed.id);
      _index.remove(removed.id);
    }
    _rebuildIndex();
    return indices.length;
  }

  void _rebuildIndex() {
    _index.clear();
    for (var i = 0; i < _list.length; i++) {
      _index[_list[i].id] = i;
    }
  }
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
