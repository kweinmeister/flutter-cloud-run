import 'dart:convert';
import 'dart:io';

import 'package:backend/repository.dart';
import 'package:backend/src/app.dart';
import 'package:google_cloud/google_cloud.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shared/shared.dart';

enum LogLevel { info, warning, error, critical }

void _log(
  LogLevel level,
  String message, {
  Object? error,
  StackTrace? stack,
  Map<String, dynamic>? extra,
}) {
  final entry = {
    'severity': level.name,
    'message': message,
    if (error != null) 'error': error.toString(),
    if (stack != null) 'stackTrace': stack.toString(),
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    if (extra != null) ...extra,
  };
  print(jsonEncode(entry));
}

void main(List<String> args) async {
  try {
    final ip = InternetAddress.anyIPv4;

    // Initialize Auth & Repository
    late final AutoRefreshingAuthClient client;
    try {
      client = await clientViaApplicationDefaultCredentials(
        scopes: [FirestoreApi.datastoreScope],
      );
    } catch (e) {
      _log(
        LogLevel.critical,
        'Failed to obtain credentials. For local development, run: gcloud auth application-default login',
      );
      exit(1);
    }

    final firestoreApi = FirestoreApi(client);

    late final String projectId;
    try {
      projectId = await computeProjectId();
    } catch (e) {
      _log(
        LogLevel.critical,
        'Failed to detect Google Cloud Project ID. '
        'Ensure GOOGLE_CLOUD_PROJECT environment variable is set locally, '
        'or that the service account has access to the Metadata Server on Cloud Run.',
        error: e,
      );
      exit(1);
    }

    final repo = TodoRepository(firestoreApi, projectId);

    // Serve static files from /app/public (Docker) or ../frontend/build/web (Local)
    // For OS-only deployment, we'll place it in 'public' relative to the executable
    var staticPath = '../frontend/build/web';
    if (FileSystemEntity.isDirectorySync('public')) {
      staticPath = 'public';
    } else if (FileSystemEntity.isDirectorySync('/app/public')) {
      staticPath = '/app/public';
    }

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(createHandler(repo, staticPath: staticPath));

    final port = int.parse(
      Platform.environment['PORT'] ?? ApiConstants.defaultPort.toString(),
    );
    final server = await serve(handler, ip, port);
    _log(LogLevel.info, 'Server listening on port ${server.port}');
  } catch (e, s) {
    _log(LogLevel.critical, 'Server failed to start.', error: e, stack: s);
    exit(1);
  }
}
