import 'package:backend/src/api_error.dart';
import 'package:backend/src/firestore_utils.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:shared/shared.dart';

/// Repository for managing Todo items in Google Cloud Firestore.
///
/// All operations enforce server-side ID generation and timestamps to ensure
/// data consistency and prevent client-side manipulation.
class TodoRepository {
  final FirestoreApi _api;
  final String _projectId;

  String get _parentPath =>
      'projects/$_projectId/databases/(default)/documents';
  String get _collectionPath => '$_parentPath/todos';

  TodoRepository(this._api, this._projectId);

  /// Lists all todos with optional pagination support.
  ///
  /// Returns a record containing:
  /// - `items`: List of [TodoItem] objects
  /// - `nextPageToken`: Optional token for fetching the next page
  ///
  /// Example:
  /// ```dart
  /// final (:items, :nextPageToken) = await repo.listTodos();
  /// if (nextPageToken != null) {
  ///   final moreItems = await repo.listTodos(pageToken: nextPageToken);
  /// }
  /// ```
  Future<({List<TodoItem> items, String? nextPageToken})> listTodos({
    String? pageToken,
  }) async {
    final response = await _api.projects.databases.documents.list(
      _parentPath,
      'todos',
      orderBy: ApiConstants.todoOrderBy,
      pageSize: ApiConstants.defaultPageSize,
      pageToken: pageToken,
    );
    final items = response.documents?.map(_mapDocument).toList() ?? [];
    return (items: items, nextPageToken: response.nextPageToken);
  }

  /// Creates a new todo item with server-generated ID and timestamp.
  ///
  /// The client-provided `id` and `createdAt` fields are ignored.
  /// The server generates a unique ID and sets the creation timestamp.
  ///
  /// Returns the created [TodoItem] with server-assigned values.
  Future<TodoItem> createTodo(TodoItem item) async {
    // 1. Enforce Server Time and ignore incoming ID
    final serverTime = DateTime.now().toUtc();
    final fields = toFirestoreFields({
      'title': item.title,
      'isDone': item.isDone,
      'created_at': serverTime,
    });

    // 2. Let Firestore generate the ID (pass null for documentId)
    final response = await _api.projects.databases.documents.createDocument(
      Document(fields: fields),
      _parentPath,
      'todos',
      documentId: null, // Force auto-ID generation on server
    );
    return _mapDocument(response);
  }

  /// Deletes a todo item by ID.
  ///
  /// Throws [NotFoundError] if the todo doesn't exist.
  Future<void> deleteTodo(String id) async {
    try {
      await _api.projects.databases.documents.delete('$_collectionPath/$id');
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        throw NotFoundError('Todo with ID "$id" not found');
      }
      rethrow;
    }
  }

  /// Updates an existing todo item.
  ///
  /// Only the `title` and `isDone` fields are updated.
  /// The `id` and `createdAt` fields cannot be modified.
  Future<void> updateTodo(TodoItem item) async {
    final fields = toFirestoreFields({
      'title': item.title,
      'isDone': item.isDone,
    });
    await _api.projects.databases.documents.patch(
      Document(fields: fields),
      '$_collectionPath/${item.id}',
      updateMask_fieldPaths: ['title', 'isDone'],
    );
  }

  TodoItem _mapDocument(Document doc) {
    final name = doc.name;
    if (name == null || name.isEmpty) {
      throw Exception('Document missing name field');
    }

    final plainMap = (doc.fields ?? {}).toPlainMap();
    plainMap['id'] = name.split('/').last;

    return TodoItem.fromJson(plainMap);
  }
}
