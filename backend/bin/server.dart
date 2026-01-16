import 'dart:convert';
import 'dart:io';

import 'package:backend/repository.dart';
import 'package:backend/src/app.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

void _log(String level, String message,
    {Object? error, StackTrace? stack, Map<String, dynamic>? extra}) {
  final entry = {
    'severity': level,
    'message': message,
    if (error != null) 'error': error.toString(),
    if (stack != null) 'stackTrace': stack.toString(),
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    if (extra != null) ...extra,
  };
  print(jsonEncode(entry));
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  // Initialize Auth & Repository
  late final AutoRefreshingAuthClient client;
  try {
    client = await clientViaApplicationDefaultCredentials(scopes: [
      FirestoreApi.datastoreScope,
    ]);
  } catch (e) {
    _log('CRITICAL',
        'Failed to obtain credentials. For local development, run: gcloud auth application-default login');
    exit(1);
  }
  final firestoreApi = FirestoreApi(client);

  final projectId = Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
      Platform.environment['PROJECT_ID'];
  if (projectId == null || projectId.isEmpty) {
    _log('CRITICAL',
        'GOOGLE_CLOUD_PROJECT environment variable is NOT set. Failing fast.');
    exit(1);
  }

  final repo = TodoRepository(firestoreApi, projectId);

  // Serve static files from /app/public (Docker) or ../frontend/build/web (Local)
  var staticPath = '../frontend/build/web';
  if (FileSystemEntity.isDirectorySync('/app/public')) {
    staticPath = '/app/public';
  }

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(createHandler(repo, staticPath: staticPath));

  final port = int.parse(
    Platform.environment['PORT'] ?? ApiConstants.defaultPort.toString(),
  );
  final server = await serve(handler, ip, port);
  _log('INFO', 'Server listening on port ${server.port}');
}
