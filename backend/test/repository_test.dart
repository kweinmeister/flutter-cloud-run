import 'package:backend/repository.dart';
import 'package:backend/src/api_error.dart';
import 'package:backend/src/firestore_utils.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

class MockFirestoreApi extends Mock implements FirestoreApi {}

class MockProjectsResource extends Mock implements ProjectsResource {}

class MockProjectsDatabasesResource extends Mock
    implements ProjectsDatabasesResource {}

class MockProjectsDatabasesDocumentsResource extends Mock
    implements ProjectsDatabasesDocumentsResource {}

void main() {
  late MockFirestoreApi mockApi;
  late MockProjectsResource mockProjects;
  late MockProjectsDatabasesResource mockDatabases;
  late MockProjectsDatabasesDocumentsResource mockDocuments;
  late TodoRepository repo;
  const projectId = 'test-project';

  setUp(() {
    mockApi = MockFirestoreApi();
    mockProjects = MockProjectsResource();
    mockDatabases = MockProjectsDatabasesResource();
    mockDocuments = MockProjectsDatabasesDocumentsResource();

    when(() => mockApi.projects).thenReturn(mockProjects);
    when(() => mockProjects.databases).thenReturn(mockDatabases);
    when(() => mockDatabases.documents).thenReturn(mockDocuments);

    repo = TodoRepository(mockApi, projectId);
  });

  group('TodoRepository', () {
    test('listTodos calls firestore and maps results', () async {
      final response = ListDocumentsResponse(
        documents: [
          Document(
            name: 'projects/$projectId/databases/(default)/documents/todos/1',
            fields: {
              'title': Value(stringValue: 'Task 1'),
              'isDone': Value(booleanValue: false),
              'created_at': Value(timestampValue: '2024-01-01T00:00:00Z'),
            },
          ),
        ],
        nextPageToken: 'token-123',
      );

      when(
        () => mockDocuments.list(
          any(),
          any(),
          orderBy: any(named: 'orderBy'),
          pageSize: any(named: 'pageSize'),
          pageToken: any(named: 'pageToken'),
        ),
      ).thenAnswer((_) async => response);

      final result = await repo.listTodos();

      expect(result.items, hasLength(1));
      expect(result.items[0].id, equals('1'));
      expect(result.items[0].title, equals('Task 1'));
      expect(result.nextPageToken, equals('token-123'));
    });

    test('createTodo calls firestore with server timestamp', () async {
      final item = TodoItem(
        title: 'New Task',
        id: '',
        createdAt: DateTime.now(),
      );
      final createdDoc = Document(
        name: 'projects/$projectId/databases/(default)/documents/todos/new-id',
        fields: {
          'title': Value(stringValue: 'New Task'),
          'isDone': Value(booleanValue: false),
          'created_at': Value(timestampValue: '2024-01-01T00:00:00Z'),
        },
      );

      // Register fallback for Document class
      registerFallbackValue(Document());

      when(
        () => mockDocuments.createDocument(
          any(),
          any(),
          any(),
          documentId: any(named: 'documentId'),
        ),
      ).thenAnswer((_) async => createdDoc);

      final result = await repo.createTodo(item);

      expect(result.id, equals('new-id'));
      expect(result.title, equals('New Task'));
    });

    test('updateTodo calls firestore patch', () async {
      final item = TodoItem(
        id: '1',
        title: 'Updated',
        isDone: true,
        createdAt: DateTime.utc(2024, 1, 1),
      );

      when(
        () => mockDocuments.patch(
          any(),
          any(),
          updateMask_fieldPaths: any(named: 'updateMask_fieldPaths'),
        ),
      ).thenAnswer((_) async => Document());

      await repo.updateTodo(item);

      verify(
        () => mockDocuments.patch(
          any(),
          any(),
          updateMask_fieldPaths: any(named: 'updateMask_fieldPaths'),
        ),
      ).called(1);
    });

    test('deleteTodo handles success', () async {
      when(() => mockDocuments.delete(any())).thenAnswer((_) async => Empty());

      await repo.deleteTodo('1');

      verify(() => mockDocuments.delete(any())).called(1);
    });

    test('deleteTodo throws NotFoundError on 404', () async {
      when(
        () => mockDocuments.delete(any()),
      ).thenThrow(DetailedApiRequestError(404, 'Not Found'));

      expect(() => repo.deleteTodo('1'), throwsA(isA<NotFoundError>()));
    });
  });

  group('Firestore Utility Extensions', () {
    test('roundtrip conversion preserves data', () {
      final original = {
        'string': 'value',
        'int': 42,
        'bool': true,
        'date': DateTime.utc(2024, 1, 1),
      };

      final fields = toFirestoreFields(original);
      final restored = fields.toPlainMap();

      expect(restored['string'], equals(original['string']));
      expect(restored['int'], equals(original['int']));
      expect(restored['bool'], equals(original['bool']));
      expect(
        restored['date'],
        equals((original['date'] as DateTime).toUtc().toIso8601String()),
      );
    });
  });
}
