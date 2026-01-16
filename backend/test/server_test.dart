import 'dart:convert';

import 'package:backend/repository.dart';
import 'package:backend/src/api_error.dart';
import 'package:backend/src/app.dart';
import 'package:shelf/shelf.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

// Mock repository for testing
class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late MockTodoRepository repo;
  late Handler handler;

  setUp(() {
    repo = MockTodoRepository();
    handler = createHandler(repo);
  });

  group('Health Check Endpoint', () {
    test('GET /health returns OK', () async {
      final request = Request('GET', Uri.parse('http://localhost/health'));
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(await response.readAsString(), equals('OK'));
    });
  });

  group('GET /api/todos', () {
    test('returns empty list when no todos', () async {
      when(
        () => repo.listTodos(pageToken: any(named: 'pageToken')),
      ).thenAnswer((_) async => (items: <TodoItem>[], nextPageToken: null));

      final request = Request(
        'GET',
        Uri.parse('http://localhost${ApiConstants.todosPath}'),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString());
      expect(body['items'], isEmpty);
      expect(body['nextPageToken'], isNull);
    });

    test('returns list of todos', () async {
      final todos = [
        TodoItem(
          id: '1',
          title: 'Test',
          createdAt: DateTime.now(),
          isDone: false,
        ),
        TodoItem(
          id: '2',
          title: 'Test 2',
          createdAt: DateTime.now(),
          isDone: true,
        ),
      ];
      when(
        () => repo.listTodos(pageToken: any(named: 'pageToken')),
      ).thenAnswer((_) async => (items: todos, nextPageToken: null));

      final request = Request(
        'GET',
        Uri.parse('http://localhost${ApiConstants.todosPath}'),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString());
      expect(body['items'], hasLength(2));
      expect(body['items'][0]['title'], equals('Test'));
    });
  });

  group('POST /api/todos', () {
    test('creates todo successfully', () async {
      final input = TodoItem(
        id: '',
        title: 'New task',
        createdAt: DateTime.now(),
      );
      final output = input.copyWith(id: 'gen-1');

      // We need to register a fallback for TodoItem to use any()
      registerFallbackValue(input);

      when(() => repo.createTodo(any())).thenAnswer((_) async => output);

      final request = Request(
        'POST',
        Uri.parse('http://localhost${ApiConstants.todosPath}'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(input.toJson()),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString());
      expect(body['id'], equals('gen-1'));
    });

    test('rejects body too large', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost${ApiConstants.todosPath}'),
        headers: {'content-type': 'application/json'},
        body: 'a' * 100001,
      );
      final response = await handler(request);
      expect(response.statusCode, equals(400));
    });
  });

  group('PATCH /api/todos/:id', () {
    test('updates existing todo', () async {
      final input = TodoItem(
        id: '1',
        title: 'Updated',
        createdAt: DateTime.now(),
      );
      registerFallbackValue(input);

      when(() => repo.updateTodo(any())).thenAnswer((_) async => {});

      final request = Request(
        'PATCH',
        Uri.parse('http://localhost${ApiConstants.todosPath}/1'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(input.toJson()),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      verify(() => repo.updateTodo(any())).called(1);
    });
  });

  group('DELETE /api/todos/:id', () {
    test('deletes existing todo', () async {
      when(() => repo.deleteTodo('1')).thenAnswer((_) async => {});

      final request = Request(
        'DELETE',
        Uri.parse('http://localhost${ApiConstants.todosPath}/1'),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      verify(() => repo.deleteTodo('1')).called(1);
    });
  });

  group('API Error Responses', () {
    test('InternalServerError returns 500', () {
      final error = InternalServerError('Error');
      expect(error.statusCode, equals(500));
    });
  });
}
