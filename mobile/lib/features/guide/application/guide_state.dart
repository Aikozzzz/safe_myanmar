import '../domain/emergency_article.dart';

enum GuidePhase { loading, data, empty, error }

final class GuideState {
  GuideState({
    required this.phase,
    required List<EmergencyArticle> articles,
    required this.query,
    required this.category,
  }) : articles = List.unmodifiable(articles);

  final GuidePhase phase;
  final List<EmergencyArticle> articles;
  final String query;
  final String? category;
}
