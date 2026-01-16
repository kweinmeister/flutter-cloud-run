// Shared Constants for both Backend and Frontend
class ApiConstants {
  static const String todosPath = '/api/todos';
  static const String todoOrderBy = 'created_at desc';
  static const int maxTitleLength = 255;
  static const int defaultPageSize = 50;

  // Local development default
  static const int defaultPort = 8080;
  static const String localBackendUrl = 'http://localhost:$defaultPort';
}

// UI Constants for Frontend
class UiConstants {
  static const double maxContentWidth = 700.0;
  static const Duration hoverAnimationDuration = Duration(milliseconds: 200);
  static const Duration stateAnimationDuration = Duration(milliseconds: 300);
  static const double hintOpacity = 0.5;
  static const int requestTimeoutSeconds = 30;
}
