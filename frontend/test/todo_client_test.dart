import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';
import 'package:frontend/todo_client.dart';

void main() {
  group('TodosResponse', () {
    test('constructs with items and token', () {
      final items = [
        TodoItem(
          id: '1',
          title: 'Test',
          createdAt: DateTime.now(),
          isDone: false,
        ),
      ];
      final response = TodosResponse(items, 'token-123');

      expect(response.items, hasLength(1));
      expect(response.nextPageToken, equals('token-123'));
    });

    test('constructs with null token', () {
      final response = TodosResponse([], null);
      expect(response.nextPageToken, isNull);
    });
  });

  group('TodoClient Integration', () {
    test('fetchTodos uses injected client', () async {
      final client = MockClient((request) async {
        return http.Response('{"items": [], "nextPageToken": null}', 200);
      });
      final todoClient = TodoClient(client: client);
      final response = await todoClient.fetchTodos();
      expect(response.items, isEmpty);
    });

    test('createTodo uses injected client', () async {
      final item = TodoItem(id: '1', title: 'New', createdAt: DateTime.now());
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        return http.Response(jsonEncode(item.toJson()), 200);
      });
      final todoClient = TodoClient(client: client);
      final result = await todoClient.createTodo(item);
      expect(result.id, '1');
    });

    test('updateTodo uses injected client', () async {
      final item = TodoItem(
        id: '1',
        title: 'Updated',
        createdAt: DateTime.now(),
      );
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        return http.Response('', 200);
      });
      final todoClient = TodoClient(client: client);
      await todoClient.updateTodo(item);
    });

    test('deleteTodo uses injected client', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 200);
      });
      final todoClient = TodoClient(client: client);
      await todoClient.deleteTodo('1');
    });
  });
}

class MockClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) _handler;
  MockClient(this._handler);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request as http.Request);
    return http.StreamedResponse(
      Stream.fromIterable([response.bodyBytes]),
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
    );
  }
}
