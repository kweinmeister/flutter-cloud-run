import 'package:googleapis/firestore/v1.dart';

extension FirestoreValueExtension on Value {
  dynamic get autoValue => switch (this) {
    Value(stringValue: final s?) => s,
    Value(booleanValue: final b?) => b,
    Value(integerValue: final i?) => int.parse(i),
    Value(doubleValue: final d?) => d,
    Value(timestampValue: final t?) => t,
    _ => null,
  };
}

extension FirestoreMapExtension on Map<String, Value> {
  Map<String, dynamic> toPlainMap() => map((k, v) => MapEntry(k, v.autoValue));
}

Value toFirestoreValue(dynamic value) => switch (value) {
  final String s => Value(stringValue: s),
  final bool b => Value(booleanValue: b),
  final int i => Value(integerValue: i.toString()),
  final double d => Value(doubleValue: d),
  final DateTime dt => Value(timestampValue: dt.toUtc().toIso8601String()),
  _ => Value(),
};

Map<String, Value> toFirestoreFields(Map<String, dynamic> map) =>
    map.map((k, v) => MapEntry(k, toFirestoreValue(v)));
