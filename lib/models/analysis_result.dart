class AnalysisResult {
  final double estimatedHours;
  final String complexity;
  final String summary;
  final String code;

  AnalysisResult({
    required this.estimatedHours,
    required this.complexity,
    required this.summary,
    required this.code,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      estimatedHours: json['estimated_hours']?.toDouble() ?? 0.0,
      complexity: json['complexity'] ?? 'unknown',
      summary: json['summary'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimated_hours': estimatedHours,
      'complexity': complexity,
      'summary': summary,
      'code': code,
    };
  }
}
