import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/emergency_article.dart';
import 'guide_state.dart';
import 'providers.dart';

final class GuideController extends Notifier<GuideState> {
  late EmergencyGuideRepository _repository;
  var _disposed = false;

  @override
  GuideState build() {
    _repository = ref.watch(emergencyGuideRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(() => _load(query: '', category: null)));
    return GuideState(
      phase: GuidePhase.loading,
      articles: const [],
      query: '',
      category: null,
    );
  }

  Future<void> search(String query) =>
      _load(query: query, category: state.category);

  Future<void> selectCategory(String? category) =>
      _load(query: state.query, category: category);

  Future<void> retry() => _load(query: state.query, category: state.category);

  Future<void> _load({required String query, required String? category}) async {
    state = GuideState(
      phase: GuidePhase.loading,
      articles: state.articles,
      query: query,
      category: category,
    );
    try {
      final articles = await _repository.search(
        query: query,
        category: category,
      );
      if (_disposed) return;
      state = GuideState(
        phase: articles.isEmpty ? GuidePhase.empty : GuidePhase.data,
        articles: articles,
        query: query,
        category: category,
      );
    } catch (_) {
      if (_disposed) return;
      state = GuideState(
        phase: GuidePhase.error,
        articles: const [],
        query: query,
        category: category,
      );
    }
  }
}
