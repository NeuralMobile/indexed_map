/// A high-performance hybrid data structure that combines the benefits of both
/// Map and List in a single container.
///
/// IndexedMap provides O(1) lookup by ID while maintaining ordered/indexed
/// access to elements. It's ideal for scenarios where you need both fast
/// lookups and ordered iteration, such as:
/// - User lists with fast lookup by ID
/// - Message/chat histories with chronological order
/// - Caching with insertion order preservation
/// - Any collection where both random access and ordered iteration are needed
///
/// Key features:
/// - O(1) lookup by ID via internal Map
/// - O(1) indexed access via internal List
/// - Configurable duplicate handling policies
/// - Ordered iteration maintaining insertion/move order
/// - In-place sorting without losing ID associations
/// - Memory-efficient wrapper-based internal storage
library;

export 'src/indexed_map.dart';
