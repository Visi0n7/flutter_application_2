class AnalysisResult {
  final String code;
  final double estimatedHours;
  final double complexityScore;
  final double maintainabilityIndex;
  final int cyclomaticComplexity;
  final int numFunctions;
  final double commentQualityScore;
  final bool usesHardcodedDirs;
  final String summaryComplexity;
  final String summarySupportability;
  final String summaryComments;
  final String summaryStructure;
  final String summaryPaths;
  final double refEstimatedHours;
  final double refComplexityScore;
  final double refMaintainabilityIndex;
  final double refCommentQualityScore;

  AnalysisResult({
    required this.code,
    required this.estimatedHours,
    required this.complexityScore,
    required this.maintainabilityIndex,
    required this.cyclomaticComplexity,
    required this.numFunctions,
    required this.commentQualityScore,
    required this.usesHardcodedDirs,
    required this.summaryComplexity,
    required this.summarySupportability,
    required this.summaryComments,
    required this.summaryStructure,
    required this.summaryPaths,
    required this.refEstimatedHours,
    required this.refComplexityScore,
    required this.refMaintainabilityIndex,
    required this.refCommentQualityScore,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      code: json['code'],
      estimatedHours: json['estimated_hours'].toDouble(),
      complexityScore: json['complexity_score'].toDouble(),
      maintainabilityIndex: json['maintainability_index'].toDouble(),
      cyclomaticComplexity: json['cyclomatic_complexity'],
      numFunctions: json['num_functions'],
      commentQualityScore: json['comment_quality_score'].toDouble(),
      usesHardcodedDirs: json['uses_hardcoded_dirs'],
      summaryComplexity: json['summary_complexity'],
      summarySupportability: json['summary_supportability'],
      summaryComments: json['summary_comments'],
      summaryStructure: json['summary_structure'],
      summaryPaths: json['summary_paths'],

      // ✅ добавь эталонные значения вручную:
      refEstimatedHours: 8.0,
      refComplexityScore: 50.0,
      refMaintainabilityIndex: 70.0,
      refCommentQualityScore: 60.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'estimated_hours': estimatedHours,
      'complexity_score': complexityScore,
      'maintainability_index': maintainabilityIndex,
      'cyclomatic_complexity': cyclomaticComplexity,
      'num_functions': numFunctions,
      'comment_quality_score': commentQualityScore,
      'uses_hardcoded_dirs': usesHardcodedDirs,
      'summary_complexity': summaryComplexity,
      'summary_supportability': summarySupportability,
      'summary_comments': summaryComments,
      'summary_structure': summaryStructure,
      'summary_paths': summaryPaths,
    };
  }
}
