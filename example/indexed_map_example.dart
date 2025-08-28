import 'package:indexed_map/indexed_map.dart';

// Example models for different use cases
class User implements MapIndexable<String> {
  final String id;
  final String name;
  final int age;
  final DateTime lastActive;

  User(this.id, this.name, {this.age = 0, DateTime? lastActive})
    : lastActive = lastActive ?? DateTime.now();

  @override
  String get indexId => id;

  @override
  String toString() => 'User($id, $name, age: $age)';
}

class Message implements MapIndexable<String> {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;

  Message(this.id, this.content, this.senderId, {DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  String get indexId => id;

  @override
  String toString() => 'Message($id, from: $senderId, "$content")';
}

class Product implements MapIndexable<int> {
  final int id;
  final String name;
  final double price;
  final String category;

  Product(this.id, this.name, this.price, this.category);

  @override
  int get indexId => id;

  @override
  String toString() =>
      'Product($id, $name, \$${price.toStringAsFixed(2)}, $category)';
}

void main() {
  print('=== IndexedMap Examples ===\n');

  // Example 1: Basic usage with users
  basicUsageExample();

  // Example 2: Chat message management
  chatMessageExample();

  // Example 3: Product catalog with sorting
  productCatalogExample();

  // Example 4: User activity tracking
  userActivityExample();

  // Example 5: Different duplicate policies
  duplicatePolicyExamples();

  // Example 6: Performance demonstration
  performanceExample();
}

void basicUsageExample() {
  print('=== 1. Basic Usage Example ===');

  final users = IndexedMap<User, String>();

  // Add users
  users.add(User('u1', 'Alice', age: 25));
  users.add(User('u2', 'Bob', age: 30));
  users.add(User('u3', 'Carol', age: 28));

  print('Added ${users.length} users');

  // O(1) lookup by ID
  final alice = users.getById('u1');
  print('Found user: $alice');

  // O(1) indexed access
  final firstUser = users[0];
  print('First user: $firstUser');

  // Insert at specific position
  users.insertAt(1, User('u4', 'David', age: 32));
  print('After inserting David at position 1:');
  for (int i = 0; i < users.length; i++) {
    print('  [$i] ${users[i]}');
  }

  // Move user to different position
  users.moveIdTo('u1', 3); // Move Alice to end
  print('\nAfter moving Alice to position 3:');
  for (int i = 0; i < users.length; i++) {
    print('  [$i] ${users[i]}');
  }

  // Update user in place
  users[0] = User('u2', 'Bobby', age: 31); // Update Bob
  print('\nAfter updating Bob:');
  print('  ${users.getById("u2")}');

  print('');
}

void chatMessageExample() {
  print('=== 2. Chat Message Management ===');

  final messages = IndexedMap<Message, String>();

  // Add messages in chronological order
  messages.add(Message('msg1', 'Hello everyone!', 'alice'));
  messages.add(Message('msg2', 'Hi Alice!', 'bob'));
  messages.add(Message('msg3', 'How is everyone doing?', 'carol'));
  messages.add(Message('msg4', 'Great, thanks!', 'alice'));

  print('Chat history (${messages.length} messages):');
  for (int i = 0; i < messages.length; i++) {
    print('  [$i] ${messages[i]}');
  }

  // Quick lookup by message ID for editing/reactions
  final msg2 = messages.getById('msg2');
  print('\nFound message to edit: $msg2');

  // Edit message in place (keeps same position)
  messages[1] = Message('msg2', 'Hi Alice! How are you?', 'bob');
  print('After editing: ${messages[1]}');

  // Insert a delayed message that arrived out of order
  messages.insertAt(1, Message('msg5', 'Good morning!', 'david'));

  print('\nAfter inserting delayed message:');
  for (int i = 0; i < messages.length; i++) {
    print('  [$i] ${messages[i]}');
  }

  // Remove a message
  final removed = messages.removeById('msg3');
  print('\nRemoved message: $removed');
  print('Remaining messages: ${messages.length}');

  print('');
}

void productCatalogExample() {
  print('=== 3. Product Catalog with Sorting ===');

  final catalog = IndexedMap<Product, int>();

  // Add products
  catalog.add(Product(1, 'Laptop', 999.99, 'Electronics'));
  catalog.add(Product(2, 'Coffee Mug', 12.99, 'Kitchen'));
  catalog.add(Product(3, 'Desk Chair', 149.99, 'Furniture'));
  catalog.add(Product(4, 'Mouse', 29.99, 'Electronics'));
  catalog.add(Product(5, 'Table Lamp', 79.99, 'Furniture'));

  print('Original catalog order:');
  for (int i = 0; i < catalog.length; i++) {
    print('  [$i] ${catalog[i]}');
  }

  // Sort by price (low to high)
  catalog.sortBy((a, b) => a.price.compareTo(b.price));
  print('\nSorted by price (low to high):');
  for (int i = 0; i < catalog.length; i++) {
    print('  [$i] ${catalog[i]}');
  }

  // ID lookup still works after sorting
  final laptop = catalog.getById(1);
  print('\nLaptop after sorting: $laptop');
  print('Laptop is now at position: ${catalog.indexOfId(1)}');

  // Sort by category, then by name
  catalog.sortBy((a, b) {
    final categoryCompare = a.category.compareTo(b.category);
    if (categoryCompare != 0) return categoryCompare;
    return a.name.compareTo(b.name);
  });

  print('\nSorted by category, then name:');
  for (int i = 0; i < catalog.length; i++) {
    print('  [$i] ${catalog[i]}');
  }

  print('');
}

void userActivityExample() {
  print('=== 4. User Activity Tracking ===');

  // Use replaceMoveToEnd policy to track recent activity
  final activeUsers = IndexedMap<User, String>(
    duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
  );

  // Add users as they become active
  activeUsers.add(User('alice', 'Alice'));
  activeUsers.add(User('bob', 'Bob'));
  activeUsers.add(User('carol', 'Carol'));
  activeUsers.add(User('david', 'David'));

  print('Initial activity order:');
  printUserActivity(activeUsers);

  // Alice becomes active again (moves to end)
  activeUsers.add(User('alice', 'Alice', age: 25));
  print('\nAfter Alice becomes active:');
  printUserActivity(activeUsers);

  // Bob becomes active
  activeUsers.add(User('bob', 'Bob', age: 30));
  print('\nAfter Bob becomes active:');
  printUserActivity(activeUsers);

  // Check specific user's position
  print('\nAlice is at position: ${activeUsers.indexOfId("alice")}');
  print('Most recently active user: ${activeUsers.last}');

  print('');
}

void duplicatePolicyExamples() {
  print('=== 5. Duplicate Policy Examples ===');

  // Policy 1: Ignore duplicates
  print('Policy: IGNORE');
  final ignoreMap = IndexedMap<User, String>(
    duplicatePolicy: DuplicatePolicy.ignore,
  );
  ignoreMap.add(User('u1', 'Alice', age: 25));
  ignoreMap.add(User('u2', 'Bob', age: 30));
  print('Before duplicate: ${ignoreMap.toList()}');

  final added = ignoreMap.add(User('u1', 'Alice Updated', age: 26));
  print('Added duplicate: $added');
  print('After duplicate: ${ignoreMap.toList()}');
  print('Alice\'s age: ${ignoreMap.getById("u1")?.age}'); // Still 25

  // Policy 2: Replace and keep position
  print('\nPolicy: REPLACE_KEEP_POSITION');
  final replaceMap = IndexedMap<User, String>(
    duplicatePolicy: DuplicatePolicy.replaceKeepPosition,
  );
  replaceMap.add(User('u1', 'Alice', age: 25));
  replaceMap.add(User('u2', 'Bob', age: 30));
  replaceMap.add(User('u3', 'Carol', age: 28));
  print('Before duplicate: ${replaceMap.toList()}');

  replaceMap.add(User('u2', 'Bobby', age: 31));
  print('After duplicate: ${replaceMap.toList()}');
  print('Bob is at position: ${replaceMap.indexOfId("u2")}'); // Still 1

  // Policy 3: Replace and move to end
  print('\nPolicy: REPLACE_MOVE_TO_END');
  final moveMap = IndexedMap<User, String>(
    duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
  );
  moveMap.add(User('u1', 'Alice', age: 25));
  moveMap.add(User('u2', 'Bob', age: 30));
  moveMap.add(User('u3', 'Carol', age: 28));
  print('Before duplicate: ${moveMap.toList()}');

  moveMap.add(User('u2', 'Bobby', age: 31));
  print('After duplicate: ${moveMap.toList()}');
  print('Bob is now at position: ${moveMap.indexOfId("u2")}'); // Now 2

  print('');
}

void performanceExample() {
  print('=== 6. Performance Demonstration ===');

  final map = IndexedMap<User, String>();
  final stopwatch = Stopwatch();

  // Add 10,000 users
  stopwatch.start();
  for (int i = 0; i < 10000; i++) {
    map.add(User('user_$i', 'User $i', age: 20 + (i % 50)));
  }
  stopwatch.stop();
  print('Added 10,000 users in ${stopwatch.elapsedMilliseconds}ms');

  // Test O(1) lookup performance
  stopwatch.reset();
  stopwatch.start();
  for (int i = 0; i < 1000; i++) {
    final randomId = 'user_${i * 10}';
    final user = map.getById(randomId);
    assert(user != null);
  }
  stopwatch.stop();
  print('1,000 random lookups in ${stopwatch.elapsedMilliseconds}ms');

  // Test O(1) indexed access performance
  stopwatch.reset();
  stopwatch.start();
  for (int i = 0; i < 1000; i++) {
    final randomIndex = i * 10;
    final user = map[randomIndex];
    assert(user.id == 'user_$randomIndex');
  }
  stopwatch.stop();
  print('1,000 random index accesses in ${stopwatch.elapsedMilliseconds}ms');

  // Test sorting performance
  stopwatch.reset();
  stopwatch.start();
  map.sortBy((a, b) => a.age.compareTo(b.age));
  stopwatch.stop();
  print('Sorted 10,000 users by age in ${stopwatch.elapsedMilliseconds}ms');

  // Verify sorting worked
  print('First user after sorting: ${map[0]}');
  print('Last user after sorting: ${map[map.length - 1]}');

  // Test that IDs still work after sorting
  stopwatch.reset();
  stopwatch.start();
  final _ = map.getById('user_5000'); // Lookup for timing only
  stopwatch.stop();
  print('Lookup after sorting: ${stopwatch.elapsedMicroseconds}μs');
  print('Found user_5000 at position: ${map.indexOfId("user_5000")}');

  print('');
}

void printUserActivity(IndexedMap<User, String> users) {
  print('  Activity order (most recent last):');
  for (int i = 0; i < users.length; i++) {
    final user = users[i];
    print('    [$i] ${user.name}');
  }
}
