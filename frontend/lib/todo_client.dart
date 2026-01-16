import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';
import 'package:flutter/foundation.dart';

/// Response from the todos API containing items and pagination token.
class TodosResponse {
  final List<TodoItem> items;
  final String? nextPageToken;

  TodosResponse(this.items, this.nextPageToken);
}

/// HTTP client for interacting with the Todo API.
///
/// Automatically configures the backend URL based on build mode:
/// - Release mode: Uses same-origin (served from backend)
/// - Debug mode: Uses [ApiConstants.localBackendUrl] (http://localhost:8080)
class TodoClient {
  final http.Client _client;

  TodoClient({http.Client? client}) : _client = client ?? http.Client();

  /// Closes the underlying HTTP client.
  void close() => _client.close();

  String get _baseUrl {
    if (kReleaseMode) return '';
    return ApiConstants.localBackendUrl;
  }

  Uri get _baseUri => Uri.parse('$_baseUrl${ApiConstants.todosPath}');

  Future<T> _requestJson<T>(
    Future<http.Response> Function() call,
    T Function(dynamic json) fromJson,
  ) async {
    final response = await call().timeout(
      const Duration(seconds: UiConstants.requestTimeoutSeconds),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return fromJson(jsonDecode(response.body));
    }

    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMessage =
          (errorBody['error'] as Map<String, dynamic>)['message'] as String;
      throw Exception('Request failed: $errorMessage');
    } catch (_) {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }

  Future<void> _requestVoid(Future<http.Response> Function() call) async {
    final response = await call().timeout(
      const Duration(seconds: UiConstants.requestTimeoutSeconds),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMessage =
          (errorBody['error'] as Map<String, dynamic>)['message'] as String;
      throw Exception('Request failed: $errorMessage');
    } catch (_) {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }

  /// Fetches todos with optional pagination.
  ///
  /// Pass [pageToken] to fetch the next page of results.
  /// Returns [TodosResponse] containing items and optional next page token.
  Future<TodosResponse> fetchTodos({String? pageToken}) => _requestJson(
    () {
      var uri = _baseUri;
      if (pageToken != null) {
        uri = uri.replace(queryParameters: {'pageToken': pageToken});
      }
      return _client.get(uri);
    },
    (json) {
      final data = json as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextPageToken = data['nextPageToken'] as String?;
      return TodosResponse(items, nextPageToken);
    },
  );

  /// Creates a new todo item.
  ///
  /// The server will generate the ID and timestamp, ignoring client values.
  /// Returns the created [TodoItem] with server-assigned ID.
  Future<TodoItem> createTodo(TodoItem item) => _requestJson(
    () => _client.post(
      _baseUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    ),
    (json) => TodoItem.fromJson(json as Map<String, dynamic>),
  );

  /// Updates an existing todo item.
  ///
  /// The [item.id] must match an existing todo.
  Future<void> updateTodo(TodoItem item) => _requestVoid(
    () => _client.patch(
      Uri.parse('$_baseUri/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    ),
  );

  /// Deletes a todo item by ID.
  Future<void> deleteTodo(String id) =>
      _requestVoid(() => _client.delete(Uri.parse('$_baseUri/$id')));
}
