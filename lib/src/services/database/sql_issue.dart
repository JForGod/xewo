enum SqlIssueType {
  syntax,
  performance,
  security,
  bestPractice,
}

class SqlIssue {
  final SqlIssueType type;
  final String message;
  final String suggestion;

  SqlIssue({
    required this.type,
    required this.message,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'message': message,
      'suggestion': suggestion,
    };
  }
} 