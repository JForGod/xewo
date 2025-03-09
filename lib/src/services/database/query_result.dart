class QueryResult {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final int affectedRows;
  final Duration executionTime;

  QueryResult({
    required this.columns,
    required this.rows,
    required this.affectedRows,
    required this.executionTime,
  });

  factory QueryResult.fromMaps(
    List<Map<String, dynamic>> maps, 
    Duration executionTime, 
    {int? affectedRows}
  ) {
    if (maps.isEmpty) {
      return QueryResult(
        columns: [],
        rows: [],
        affectedRows: affectedRows ?? 0,
        executionTime: executionTime,
      );
    }

    final columns = maps.first.keys.toList();
    final rows = maps.map((map) => columns.map((col) => map[col]).toList()).toList();

    return QueryResult(
      columns: columns,
      rows: rows,
      affectedRows: affectedRows ?? maps.length,
      executionTime: executionTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'columns': columns,
      'rows': rows,
      'affectedRows': affectedRows,
      'executionTime': executionTime.inMicroseconds,
    };
  }
} 