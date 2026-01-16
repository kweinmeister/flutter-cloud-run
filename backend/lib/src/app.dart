import 'dart:convert';
import 'dart:io';

import 'package:backend/repository.dart';
import 'package:backend/src/api_error.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shared/shared.dart';

/// Creates the main shelf handler for the application.
Handler createHandler(TodoRepository repo, {String? staticPath}) {
  final router = Router()
    ..get('/health', _healthCheck)
    ..get(ApiConstants.todosPath, (Request req) => _listTodos(req, repo))
    ..post(ApiConstants.todosPath, (Request req) => _createTodo(req, repo))
    ..delete('${ApiConstants.todosPath}/<id>',
        (Request req, String id) => _deleteTodo(req, id, repo))
    ..patch('${ApiConstants.todosPath}/<id>',
        (Request req, String id) => _updateTodo(req, id, repo));

  // Create static handler if directory exists
  Handler? staticHandler;
  if (staticPath != null && FileSystemEntity.isDirectorySync(staticPath)) {
    staticHandler = createStaticHandler(
      staticPath,
      defaultDocument: 'index.html',
      useHeaderBytesForContentType: true,
    );
  }

  return Pipeline()
      .addMiddleware(_errorHandler())
      .addMiddleware(_contentTypeGuard())
      .addMiddleware(_corsMiddleware())
      .addHandler(Cascade()
          .add(staticHandler != null
              ? Pipeline()
                  .addMiddleware(_staticCacheMiddleware())
                  .addHandler(staticHandler)
              : (Request req) => Response.notFound(null))
          .add(router.call)
          .handler);
}

Future<Response> _healthCheck(Request req) async {
  return Response.ok('OK');
}

Future<Response> _listTodos(Request req, TodoRepository repo) async {
  final pageToken = req.url.queryParameters['pageToken'];
  final (:items, :nextPageToken) = await repo.listTodos(pageToken: pageToken);

  return _jsonResponse({
    'items': items.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  });
}

Future<Response> _createTodo(Request req, TodoRepository repo) async {
  final item = await _parseAndValidateBody(req);
  final created = await repo.createTodo(item);
  return _jsonResponse(created.toJson());
}

Future<Response> _deleteTodo(Request req, String id, TodoRepository repo) async {
  await repo.deleteTodo(id);
  return Response.ok(null);
}

Future<Response> _updateTodo(Request req, String id, TodoRepository repo) async {
  final item = await _parseAndValidateBody(req, matchId: id);
  await repo.updateTodo(item.copyWith(id: id));
  return Response.ok(null);
}

Future<TodoItem> _parseAndValidateBody(Request req, {String? matchId}) async {
  final bodyText = await req.readAsString();

  if (bodyText.length > 100000) {
    throw ValidationError('Request body too large');
  }

  try {
    final json = jsonDecode(bodyText) as Map<String, dynamic>;
    final item = TodoItem.fromJson(json);

    if (matchId != null && item.id.isNotEmpty && item.id != matchId) {
      throw ValidationError('ID mismatch: URL and body IDs must match');
    }

    final error = item.validate();
    if (error != null) throw ValidationError(error);

    return item.copyWith(title: item.sanitizedTitle);
  } on FormatException {
    throw ValidationError('Invalid JSON format');
  }
}

Response _jsonResponse(dynamic data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Response _errorResponse(ApiError error) {
  return Response(
    error.statusCode ?? 500,
    body: error.toJson(),
    headers: {'content-type': 'application/json'},
  );
}

Middleware _corsMiddleware() {
  const corsAllowMethods = 'GET, POST, PUT, DELETE, PATCH, OPTIONS';
  const corsAllowHeaders = 'Origin, Content-Type';

  String determineAllowedOrigin(String? requestOrigin) {
    final envOrigin = Platform.environment['ALLOWED_ORIGIN'];
    if (envOrigin != null && envOrigin.isNotEmpty) return envOrigin;
    if (requestOrigin != null && requestOrigin.contains('localhost')) {
      return requestOrigin;
    }
    return '*';
  }

  return createMiddleware(
    requestHandler: (request) {
      final requestOrigin = request.headers['origin'];
      final allowedOrigin = determineAllowedOrigin(requestOrigin);

      final corsHeaders = {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': corsAllowMethods,
        'Access-Control-Allow-Headers': corsAllowHeaders,
      };

      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      return null;
    },
    responseHandler: (response) {
      final allowedOrigin = determineAllowedOrigin(null);
      return response.change(headers: {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': corsAllowMethods,
        'Access-Control-Allow-Headers': corsAllowHeaders,
      });
    },
  );
}

Middleware _staticCacheMiddleware() {
  const coopHeaders = {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
  };

  return createMiddleware(
    responseHandler: (response) {
      if (response.statusCode != 200) return response;
      final contentType = response.headers['content-type'] ?? '';

      if (contentType.contains('text/html')) {
        return response.change(headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          ...coopHeaders,
        });
      }

      return response.change(headers: {
        'Cache-Control': 'public, max-age=604800',
        ...coopHeaders,
      });
    },
  );
}

Middleware _contentTypeGuard() {
  return createMiddleware(
    requestHandler: (request) {
      if (request.method == 'POST' ||
          request.method == 'PATCH' ||
          request.method == 'PUT') {
        final contentType = request.headers['content-type'];
        if (request.url.path.startsWith('/api/')) {
          if (contentType == null ||
              !contentType.contains('application/json')) {
            return _errorResponse(
                ValidationError('Content-Type must be application/json'));
          }
        }
      }
      return null;
    },
  );
}

Middleware _errorHandler() {
  return (innerHandler) {
    return (request) async {
      try {
        return await innerHandler(request);
      } on ApiError catch (e) {
        return _errorResponse(e);
      } catch (e) {
        return _errorResponse(
            InternalServerError('An unexpected error occurred'));
      }
    };
  };
}
