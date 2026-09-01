final class EmergencyArticle {
  EmergencyArticle({
    required this.id,
    required this.contentVersion,
    required this.category,
    required this.titleEn,
    required this.titleMy,
    required this.questionEn,
    required this.questionMy,
    required this.answerEn,
    required this.answerMy,
    required List<String> keywords,
    required this.sourceName,
    required this.sourceUrl,
    required this.sourceUpdatedAt,
    required this.reviewedAt,
  }) : keywords = List.unmodifiable(keywords);

  final String id;
  final int contentVersion;
  final String category;
  final String titleEn;
  final String titleMy;
  final String questionEn;
  final String questionMy;
  final String answerEn;
  final String answerMy;
  final List<String> keywords;
  final String sourceName;
  final String sourceUrl;
  final DateTime? sourceUpdatedAt;
  final DateTime reviewedAt;

  String titleForLanguage({required bool burmese}) =>
      burmese && titleMy.trim().isNotEmpty ? titleMy : titleEn;

  String questionForLanguage({required bool burmese}) =>
      burmese && questionMy.trim().isNotEmpty ? questionMy : questionEn;

  String answerForLanguage({required bool burmese}) =>
      burmese && answerMy.trim().isNotEmpty ? answerMy : answerEn;
}

abstract interface class EmergencyGuideRepository {
  Future<List<EmergencyArticle>> search({String query, String? category});
  Future<EmergencyArticle?> getById(String id);
}
