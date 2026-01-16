import 'dart:convert';

/// Standardized API error response
class ApiError {
  final String code;
  final String message;
  final int? statusCode;

  ApiError({required this.code, required this.message, this.statusCode});

  String toJson() => jsonEncode({
    'error': {'code': code, 'message': message},
  });

  @override
  String toString() => '$code: $message';
}

// Common API errors
class ValidationError extends ApiError {
  ValidationError(String message)
    : super(code: 'VALIDATION_ERROR', message: message, statusCode: 400);
}

class NotFoundError extends ApiError {
  NotFoundError(String message)
    : super(code: 'NOT_FOUND', message: message, statusCode: 404);
}

class ResourceExistsError extends ApiError {
  ResourceExistsError(String message)
    : super(code: 'RESOURCE_EXISTS', message: message, statusCode: 409);
}

class InternalServerError extends ApiError {
  InternalServerError(String message)
    : super(code: 'INTERNAL_ERROR', message: message, statusCode: 500);
}

class RateLimitError extends ApiError {
  RateLimitError()
    : super(
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests. Please try again later.',
        statusCode: 429,
      );
}
