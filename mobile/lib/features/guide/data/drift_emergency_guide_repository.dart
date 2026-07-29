import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/emergency_article.dart';
import '../domain/text_normalizer.dart';

final class DriftEmergencyGuideRepository implements EmergencyGuideRepository {
  DriftEmergencyGuideRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<EmergencyArticle>> search({
    String query = '',
    String? category,
  }) async {
    final select = _database.select(_database.emergencyArticles)
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    final rows = await select.get();
    final terms = normalizeEmergencyText(query).tokens.toSet();
    return rows
        .map(_toDomain)
        .where((article) {
          if (category != null && article.category != category) return false;
          if (terms.isEmpty) return true;
          final searchable = normalizeEmergencyText(
            [
              article.titleEn,
              article.titleMy,
              article.questionEn,
              article.questionMy,
              ...article.keywords,
            ].join(' '),
          ).tokens.toSet();
          return terms.every(searchable.contains);
        })
        .toList(growable: false);
  }

  @override
  Future<EmergencyArticle?> getById(String id) async {
    final query = _database.select(_database.emergencyArticles)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  EmergencyArticle _toDomain(EmergencyArticleRow row) => EmergencyArticle(
    id: row.id,
    contentVersion: row.contentVersion,
    category: row.category,
    titleEn: row.titleEn,
    titleMy: row.titleMy,
    questionEn: row.questionEn,
    questionMy: row.questionMy,
    answerEn: row.answerEn,
    answerMy: row.answerMy,
    keywords: row.keywords.split('|'),
    sourceName: row.sourceName,
    sourceUrl: row.sourceUrl,
    sourceUpdatedAt: row.sourceUpdatedAt == null
        ? null
        : _utc(row.sourceUpdatedAt!),
    reviewedAt: _utc(row.reviewedAt),
  );

  DateTime _utc(int microseconds) =>
      DateTime.fromMicrosecondsSinceEpoch(microseconds, isUtc: true);
}
