class DatabaseException implements Exception {
  final String message;
  final dynamic cause;

  DatabaseException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'DatabaseException: $message\nCause: $cause';
    }
    return 'DatabaseException: $message';
  }
} 