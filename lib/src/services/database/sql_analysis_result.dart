class SqlAnalysisResult {
  final List<String> issues;
  final String? executionPlan;
  final Map<String, dynamic> statistics;
  final List<String> suggestions;

  SqlAnalysisResult({
    required this.issues,
    this.executionPlan,
    required this.statistics,
    required this.suggestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'issues': issues,
      'execution_plan': executionPlan,
      'statistics': statistics,
      'suggestions': suggestions,
    };
  }
} 