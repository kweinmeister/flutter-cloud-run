import 'package:backend/src/firestore_utils.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreValueExtension', () {
    test('autoValue returns string from stringValue', () {
      final value = Value(stringValue: 'test');
      expect(value.autoValue, equals('test'));
    });

    test('autoValue returns bool from booleanValue', () {
      final value = Value(booleanValue: true);
      expect(value.autoValue, equals(true));
    });

    test('autoValue returns int from integerValue', () {
      final value = Value(integerValue: '42');
      expect(value.autoValue, equals(42));
    });

    test('autoValue returns double from doubleValue', () {
      final value = Value(doubleValue: 3.14);
      expect(value.autoValue, equals(3.14));
    });

    test('autoValue returns timestamp from timestampValue', () {
      final timestamp = '2024-01-01T00:00:00Z';
      final value = Value(timestampValue: timestamp);
      expect(value.autoValue, equals(timestamp));
    });

    test('autoValue returns null for empty Value', () {
      final value = Value();
      expect(value.autoValue, isNull);
    });
  });

  group('FirestoreMapExtension', () {
    test('toPlainMap converts all supported types', () {
      final firestoreMap = {
        'str': Value(stringValue: 'hello'),
        'num': Value(integerValue: '123'),
        'bool': Value(booleanValue: true),
        'double': Value(doubleValue: 2.5),
      };

      final plainMap = firestoreMap.toPlainMap();

      expect(plainMap['str'], equals('hello'));
      expect(plainMap['num'], equals(123));
      expect(plainMap['bool'], equals(true));
      expect(plainMap['double'], equals(2.5));
    });

    test('toPlainMap handles null values', () {
      final firestoreMap = {
        'null': Value(),
        'str': Value(stringValue: 'test'),
      };

      final plainMap = firestoreMap.toPlainMap();

      expect(plainMap['null'], isNull);
      expect(plainMap['str'], equals('test'));
    });
  });

  group('toFirestoreValue', () {
    test('converts String to stringValue', () {
      final value = toFirestoreValue('test');
      expect(value.stringValue, equals('test'));
    });

    test('converts bool to booleanValue', () {
      final value = toFirestoreValue(true);
      expect(value.booleanValue, equals(true));
    });

    test('converts int to integerValue', () {
      final value = toFirestoreValue(42);
      expect(value.integerValue, equals('42'));
    });

    test('converts double to doubleValue', () {
      final value = toFirestoreValue(3.14);
      expect(value.doubleValue, equals(3.14));
    });

    test('converts DateTime to timestampValue', () {
      final dt = DateTime.utc(2024, 1, 1, 12, 0, 0);
      final value = toFirestoreValue(dt);
      expect(value.timestampValue, equals('2024-01-01T12:00:00.000Z'));
    });

    test('returns empty Value for unsupported type', () {
      final value = toFirestoreValue([1, 2, 3]); // List not supported
      expect(value.stringValue, isNull);
      expect(value.integerValue, isNull);
    });
  });

  group('toFirestoreFields', () {
    test('converts map with all supported types', () {
      final plainMap = {
        'title': 'Test Todo',
        'isDone': false,
        'count': 5,
        'rating': 4.5,
        'created_at': DateTime.utc(2024, 1, 1),
      };

      final firestoreFields = toFirestoreFields(plainMap);

      expect(firestoreFields['title']?.stringValue, equals('Test Todo'));
      expect(firestoreFields['isDone']?.booleanValue, equals(false));
      expect(firestoreFields['count']?.integerValue, equals('5'));
      expect(firestoreFields['rating']?.doubleValue, equals(4.5));
      expect(firestoreFields['created_at']?.timestampValue, isNotNull);
    });

    test('handles empty map', () {
      final firestoreFields = toFirestoreFields({});
      expect(firestoreFields, isEmpty);
    });

    test('roundtrip conversion preserves data', () {
      final original = {
        'name': 'John',
        'age': 30,
        'active': true,
      };

      final firestoreFields = toFirestoreFields(original);
      final converted = firestoreFields.toPlainMap();

      expect(converted['name'], equals(original['name']));
      expect(converted['age'], equals(original['age']));
      expect(converted['active'], equals(original['active']));
    });
  });
}
