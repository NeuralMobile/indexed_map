import 'package:indexed_map/indexed_map.dart';

/// Advanced examples demonstrating complex real-world scenarios
/// for the IndexedMap package.

// Models for advanced examples
class Task implements MapIndexable<String> {
  final String id;
  final String title;
  final int priority; // 1 = highest, 5 = lowest
  final bool completed;
  final DateTime dueDate;
  final List<String> tags;

  Task(
    this.id,
    this.title, {
    this.priority = 3,
    this.completed = false,
    DateTime? dueDate,
    this.tags = const [],
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7));

  @override
  String get indexId => id;

  Task copyWith({
    String? title,
    int? priority,
    bool? completed,
    DateTime? dueDate,
    List<String>? tags,
  }) {
    return Task(
      id,
      title ?? this.title,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() =>
      'Task($id, "$title", priority: $priority, completed: $completed)';
}

class GamePlayer implements MapIndexable<String> {
  final String id;
  final String name;
  final int score;
  final int level;
  final DateTime lastActive;

  GamePlayer(
    this.id,
    this.name, {
    this.score = 0,
    this.level = 1,
    DateTime? lastActive,
  }) : lastActive = lastActive ?? DateTime.now();

  @override
  String get indexId => id;

  GamePlayer copyWith({
    String? name,
    int? score,
    int? level,
    DateTime? lastActive,
  }) {
    return GamePlayer(
      id,
      name ?? this.name,
      score: score ?? this.score,
      level: level ?? this.level,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  String toString() => 'Player($id, $name, score: $score, level: $level)';
}

class Document implements MapIndexable<String> {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime created;
  final DateTime lastModified;
  final List<String> collaborators;

  Document(
    this.id,
    this.title,
    this.content,
    this.author, {
    DateTime? created,
    DateTime? lastModified,
    this.collaborators = const [],
  }) : created = created ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();

  @override
  String get indexId => id;

  Document copyWith({
    String? title,
    String? content,
    String? author,
    DateTime? lastModified,
    List<String>? collaborators,
  }) {
    return Document(
      id,
      title ?? this.title,
      content ?? this.content,
      author ?? this.author,
      created: created,
      lastModified: lastModified ?? DateTime.now(),
      collaborators: collaborators ?? this.collaborators,
    );
  }

  @override
  String toString() => 'Document($id, "$title", by $author)';
}

void main() {
  print('=== Advanced IndexedMap Examples ===\n');

  // Example 1: Task Management System
  taskManagementExample();

  // Example 2: Real-time Leaderboard
  leaderboardExample();

  // Example 3: Document Collaboration System
  documentCollaborationExample();

  // Example 4: Undo/Redo System
  undoRedoExample();

  // Example 5: Multi-level Caching
  multiLevelCacheExample();

  // Example 6: Event Timeline Management
  eventTimelineExample();
}

void taskManagementExample() {
  print('=== 1. Advanced Task Management System ===');

  final tasks = IndexedMap<Task, String>();

  // Add various tasks
  tasks.add(
    Task('t1', 'Review pull request', priority: 1, tags: ['urgent', 'code']),
  );
  tasks.add(Task('t2', 'Write documentation', priority: 3, tags: ['docs']));
  tasks.add(
    Task('t3', 'Fix critical bug', priority: 1, tags: ['urgent', 'bug']),
  );
  tasks.add(Task('t4', 'Plan sprint', priority: 2, tags: ['planning']));
  tasks.add(Task('t5', 'Code cleanup', priority: 4, tags: ['maintenance']));

  print('Initial tasks:');
  printTasks(tasks);

  // Complete a task
  final taskToComplete = tasks.getById('t1');
  if (taskToComplete != null) {
    final completedTask = taskToComplete.copyWith(completed: true);
    tasks[tasks.indexOfId('t1')] = completedTask;
  }

  // Sort by priority (urgent first), then by completion status
  tasks.sortBy((a, b) {
    if (a.completed != b.completed) {
      return a.completed ? 1 : -1; // Incomplete tasks first
    }
    return a.priority.compareTo(b.priority); // Lower number = higher priority
  });

  print('\nAfter completing task t1 and sorting by priority:');
  printTasks(tasks);

  // Add urgent task that should go to the top
  final urgentTask = Task(
    't6',
    'Security hotfix',
    priority: 1,
    tags: ['urgent', 'security'],
  );
  tasks.add(urgentTask);

  // Re-sort to put urgent task at the top
  tasks.sortBy((a, b) {
    if (a.completed != b.completed) {
      return a.completed ? 1 : -1;
    }
    return a.priority.compareTo(b.priority);
  });

  print('\nAfter adding urgent security task:');
  printTasks(tasks);

  // Filter incomplete urgent tasks
  final urgentIncomplete = tasks
      .where((task) => !task.completed && task.tags.contains('urgent'))
      .toList();

  print('\nUrgent incomplete tasks: ${urgentIncomplete.length}');
  for (final task in urgentIncomplete) {
    print('  - ${task.title} (${task.id})');
  }

  print('');
}

void leaderboardExample() {
  print('=== 2. Real-time Game Leaderboard ===');

  // Use replaceMoveToEnd to track recent activity
  final leaderboard = IndexedMap<GamePlayer, String>(
    duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
  );

  // Initial players
  leaderboard.add(GamePlayer('p1', 'Alice', score: 1500, level: 10));
  leaderboard.add(GamePlayer('p2', 'Bob', score: 1200, level: 8));
  leaderboard.add(GamePlayer('p3', 'Carol', score: 1800, level: 12));
  leaderboard.add(GamePlayer('p4', 'Dave', score: 900, level: 6));

  print('Initial leaderboard (by activity):');
  printLeaderboard(leaderboard);

  // Simulate gameplay - Alice scores points
  simulatePlayerUpdate(leaderboard, 'p1', scoreIncrease: 300);
  print('\nAfter Alice scores 300 points:');
  printLeaderboard(leaderboard);

  // Bob levels up and scores
  simulatePlayerUpdate(leaderboard, 'p2', scoreIncrease: 500, levelIncrease: 2);
  print('\nAfter Bob levels up and scores:');
  printLeaderboard(leaderboard);

  // Sort by score (high to low) for competitive ranking
  leaderboard.sortBy((a, b) => b.score.compareTo(a.score));
  print('\nLeaderboard sorted by score:');
  printRankedLeaderboard(leaderboard);

  // Carol makes a big play
  simulatePlayerUpdate(leaderboard, 'p3', scoreIncrease: 800);

  // Show both activity order and score ranking
  print('\nAfter Carol\'s big play:');
  print('Recent Activity Order:');
  for (int i = 0; i < leaderboard.length; i++) {
    final player = leaderboard[i];
    print(
      '  ${i + 1}. ${player.name} (most recent: ${player.id == "p3" ? "just now" : "earlier"})',
    );
  }

  // Re-sort by score for final ranking
  leaderboard.sortBy((a, b) => b.score.compareTo(a.score));
  print('\nFinal Score Ranking:');
  printRankedLeaderboard(leaderboard);

  print('');
}

void documentCollaborationExample() {
  print('=== 3. Document Collaboration System ===');

  final documents = IndexedMap<Document, String>(
    duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
  );

  // Create initial documents
  documents.add(
    Document('d1', 'Project Proposal', 'Initial draft...', 'alice'),
  );
  documents.add(
    Document('d2', 'Technical Specs', 'System architecture...', 'bob'),
  );
  documents.add(
    Document('d3', 'User Guide', 'How to use the system...', 'carol'),
  );

  print('Initial documents:');
  printDocuments(documents);

  // Alice edits a document (moves to "recently modified")
  final doc1 = documents.getById('d1');
  if (doc1 != null) {
    final updatedDoc = doc1.copyWith(
      content: 'Updated project proposal with feedback...',
      collaborators: ['bob', 'carol'],
    );
    documents.add(updatedDoc); // Moves to end due to policy
  }

  print('\nAfter Alice updates project proposal:');
  printDocuments(documents);

  // Carol creates a new document
  documents.add(
    Document('d4', 'Meeting Notes', 'Sprint planning notes...', 'carol'),
  );

  // Bob edits technical specs
  final doc2 = documents.getById('d2');
  if (doc2 != null) {
    final updatedDoc = doc2.copyWith(
      content: 'Detailed technical specifications...',
      collaborators: ['alice'],
    );
    documents.add(updatedDoc);
  }

  print('\nAfter new document and Bob\'s edit:');
  printDocuments(documents);

  // Sort by creation date for archival view
  documents.sortBy((a, b) => a.created.compareTo(b.created));
  print('\nDocuments sorted by creation date:');
  printDocuments(documents);

  // Find documents by author
  final bobDocs = documents.where((doc) => doc.author == 'bob').toList();
  print('\nDocuments by Bob: ${bobDocs.length}');
  for (final doc in bobDocs) {
    print('  - ${doc.title} (${doc.id})');
  }

  print('');
}

void undoRedoExample() {
  print('=== 4. Undo/Redo System Implementation ===');

  // Simulate a simple text editor with undo/redo
  final versions = IndexedMap<DocumentVersion, int>();
  var currentVersionId = 0;
  var currentPosition = -1;

  void saveVersion(String content, String action) {
    currentVersionId++;
    final version = DocumentVersion(currentVersionId, content, action);

    // Remove any versions after current position (for new branch)
    while (versions.length > currentPosition + 1) {
      versions.removeAt(versions.length - 1);
    }

    versions.add(version);
    currentPosition = versions.length - 1;
    print('Saved: $action -> "$content" (v$currentVersionId)');
  }

  String? undo() {
    if (currentPosition > 0) {
      currentPosition--;
      final version = versions[currentPosition];
      print(
        'Undo to: ${version.action} -> "${version.content}" (v${version.id})',
      );
      return version.content;
    }
    print('Nothing to undo');
    return null;
  }

  String? redo() {
    if (currentPosition < versions.length - 1) {
      currentPosition++;
      final version = versions[currentPosition];
      print(
        'Redo to: ${version.action} -> "${version.content}" (v${version.id})',
      );
      return version.content;
    }
    print('Nothing to redo');
    return null;
  }

  // Simulate editing
  saveVersion('', 'Initial');
  saveVersion('Hello', 'Type "Hello"');
  saveVersion('Hello World', 'Type " World"');
  saveVersion('Hello Beautiful World', 'Insert "Beautiful "');

  print('\nUndo operations:');
  undo(); // Back to "Hello World"
  undo(); // Back to "Hello"

  print('\nRedo operations:');
  redo(); // Forward to "Hello World"

  print('\nNew edit (creates branch):');
  saveVersion('Hello Universe', 'Replace "World" with "Universe"');

  print('\nTrying to redo (should fail):');
  redo();

  print('\nVersion history:');
  for (int i = 0; i < versions.length; i++) {
    final version = versions[i];
    final marker = i == currentPosition ? ' <-- CURRENT' : '';
    print('  v${version.id}: ${version.action} -> "${version.content}"$marker');
  }

  print('');
}

void multiLevelCacheExample() {
  print('=== 5. Multi-level Caching System ===');

  final l1Cache = IndexedMap<CacheEntry, String>(
    duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
  );
  final l2Cache = IndexedMap<CacheEntry, String>(
    duplicatePolicy: DuplicatePolicy.replaceMoveToEnd,
  );

  const maxL1Size = 3;
  const maxL2Size = 5;

  T? getCached<T>(String key) {
    // Check L1 first
    final l1Entry = l1Cache.getById(key);
    if (l1Entry != null) {
      // Move to end (most recently used)
      l1Cache.add(l1Entry);
      print('L1 HIT: $key');
      return l1Entry.value as T;
    }

    // Check L2
    final l2Entry = l2Cache.getById(key);
    if (l2Entry != null) {
      // Promote to L1
      l1Cache.add(l2Entry);
      l2Cache.removeById(key);

      // Evict from L1 if needed
      while (l1Cache.length > maxL1Size) {
        final evicted = l1Cache.removeAt(0);
        l2Cache.add(evicted);
      }

      print('L2 HIT: $key (promoted to L1)');
      return l2Entry.value as T;
    }

    print('MISS: $key');
    return null;
  }

  void putCache<T>(String key, T value) {
    final entry = CacheEntry(key, value);

    // Add to L1
    l1Cache.add(entry);

    // Evict from L1 if needed
    while (l1Cache.length > maxL1Size) {
      final evicted = l1Cache.removeAt(0);
      l2Cache.add(evicted);

      // Evict from L2 if needed
      while (l2Cache.length > maxL2Size) {
        l2Cache.removeAt(0);
      }
    }

    print('STORE: $key');
  }

  void printCacheState() {
    print('L1 Cache (${l1Cache.length}/$maxL1Size):');
    for (int i = 0; i < l1Cache.length; i++) {
      print('  [$i] ${l1Cache[i].key}');
    }
    print('L2 Cache (${l2Cache.length}/$maxL2Size):');
    for (int i = 0; i < l2Cache.length; i++) {
      print('  [$i] ${l2Cache[i].key}');
    }
    print('');
  }

  // Simulate cache operations
  putCache('user:1', 'Alice');
  putCache('user:2', 'Bob');
  putCache('user:3', 'Carol');
  printCacheState();

  putCache('user:4', 'Dave'); // Should evict user:1 to L2
  printCacheState();

  getCached('user:1'); // Should promote from L2 to L1
  printCacheState();

  putCache('user:5', 'Eve');
  putCache('user:6', 'Frank'); // Should cause multiple evictions
  printCacheState();

  print('');
}

void eventTimelineExample() {
  print('=== 6. Event Timeline Management ===');

  final timeline = IndexedMap<Event, String>();

  // Add events (not necessarily in chronological order)
  timeline.add(Event('e1', 'User Login', DateTime(2024, 1, 1, 10, 0)));
  timeline.add(Event('e2', 'File Upload', DateTime(2024, 1, 1, 10, 30)));
  timeline.add(Event('e3', 'Data Export', DateTime(2024, 1, 1, 11, 0)));
  timeline.add(Event('e4', 'User Logout', DateTime(2024, 1, 1, 12, 0)));

  print('Events in addition order:');
  printTimeline(timeline);

  // Sort chronologically
  timeline.sortBy((a, b) => a.timestamp.compareTo(b.timestamp));
  print('\nEvents in chronological order:');
  printTimeline(timeline);

  // Insert a late-arriving event
  final lateEvent = Event('e5', 'Error Occurred', DateTime(2024, 1, 1, 10, 45));
  timeline.add(lateEvent);

  // Re-sort to maintain chronological order
  timeline.sortBy((a, b) => a.timestamp.compareTo(b.timestamp));
  print('\nAfter inserting late-arriving event:');
  printTimeline(timeline);

  // Update an event description
  final eventToUpdate = timeline.getById('e5');
  if (eventToUpdate != null) {
    final updatedEvent = eventToUpdate.copyWith(
      description: 'Critical Error - System Recovered',
    );
    timeline[timeline.indexOfId('e5')] = updatedEvent;
  }

  print('\nAfter updating error event:');
  printTimeline(timeline);

  // Find events in a time range
  final startTime = DateTime(2024, 1, 1, 10, 30);
  final endTime = DateTime(2024, 1, 1, 11, 30);

  final eventsInRange = timeline
      .where(
        (event) =>
            event.timestamp.isAfter(startTime) ||
            event.timestamp.isAtSameMomentAs(startTime),
      )
      .where((event) => event.timestamp.isBefore(endTime))
      .toList();

  print(
    '\nEvents between ${formatTime(startTime)} and ${formatTime(endTime)}:',
  );
  for (final event in eventsInRange) {
    print('  ${formatTime(event.timestamp)}: ${event.description}');
  }

  print('');
}

// Helper functions and classes

void printTasks(IndexedMap<Task, String> tasks) {
  for (int i = 0; i < tasks.length; i++) {
    final task = tasks[i];
    final status = task.completed ? '✓' : '○';
    final urgentMark = task.tags.contains('urgent') ? '🔥' : '';
    print('  [$i] $status ${task.title} (P${task.priority}) $urgentMark');
  }
}

void printLeaderboard(IndexedMap<GamePlayer, String> leaderboard) {
  for (int i = 0; i < leaderboard.length; i++) {
    final player = leaderboard[i];
    print(
      '  [${i + 1}] ${player.name}: ${player.score} pts (Level ${player.level})',
    );
  }
}

void printRankedLeaderboard(IndexedMap<GamePlayer, String> leaderboard) {
  for (int i = 0; i < leaderboard.length; i++) {
    final player = leaderboard[i];
    final rank = i + 1;
    final medal = rank == 1
        ? '🥇'
        : rank == 2
        ? '🥈'
        : rank == 3
        ? '🥉'
        : '';
    print(
      '  $rank. $medal ${player.name}: ${player.score} pts (Level ${player.level})',
    );
  }
}

void printDocuments(IndexedMap<Document, String> documents) {
  for (int i = 0; i < documents.length; i++) {
    final doc = documents[i];
    final collabText = doc.collaborators.isNotEmpty
        ? ' (collaborators: ${doc.collaborators.join(", ")})'
        : '';
    print('  [$i] "${doc.title}" by ${doc.author}$collabText');
  }
}

void printTimeline(IndexedMap<Event, String> timeline) {
  for (int i = 0; i < timeline.length; i++) {
    final event = timeline[i];
    print('  [$i] ${formatTime(event.timestamp)}: ${event.description}');
  }
}

void simulatePlayerUpdate(
  IndexedMap<GamePlayer, String> leaderboard,
  String playerId, {
  int scoreIncrease = 0,
  int levelIncrease = 0,
}) {
  final player = leaderboard.getById(playerId);
  if (player != null) {
    final updatedPlayer = player.copyWith(
      score: player.score + scoreIncrease,
      level: player.level + levelIncrease,
      lastActive: DateTime.now(),
    );
    leaderboard.add(updatedPlayer); // Will move to end due to policy
  }
}

String formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
}

// Additional helper classes

class DocumentVersion implements MapIndexable<int> {
  final int id;
  final String content;
  final String action;
  final DateTime timestamp;

  DocumentVersion(this.id, this.content, this.action)
    : timestamp = DateTime.now();

  @override
  int get indexId => id;
}

class CacheEntry implements MapIndexable<String> {
  final String key;
  final dynamic value;
  final DateTime accessTime;

  CacheEntry(this.key, this.value) : accessTime = DateTime.now();

  @override
  String get indexId => key;
}

class Event implements MapIndexable<String> {
  final String id;
  final String description;
  final DateTime timestamp;

  Event(this.id, this.description, this.timestamp);

  @override
  String get indexId => id;

  Event copyWith({String? description, DateTime? timestamp}) {
    return Event(
      id,
      description ?? this.description,
      timestamp ?? this.timestamp,
    );
  }
}
