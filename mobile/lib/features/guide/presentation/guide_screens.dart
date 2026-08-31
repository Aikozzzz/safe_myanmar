import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/safe_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../application/guide_state.dart';
import '../application/providers.dart';
import '../domain/emergency_article.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(guideControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.guideTitle)),
      body: SafeArea(
        child: SafeContent(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OfflineBanner(text: strings.guideOfflineVerifiedLabel),
              const SizedBox(height: 12),
              Text(
                strings.guideIntroduction,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _GuideQuickActions(
                heading: strings.guideQuickActionsHeading,
                actions: [
                  _GuideAction(
                    key: const Key('guide-quick-action-earthquake'),
                    label: strings.guideActionEarthquake,
                    icon: Icons.vibration,
                    onPressed: () =>
                        _openArticle(context, 'earthquake-drop-cover-hold'),
                  ),
                  _GuideAction(
                    key: const Key('guide-quick-action-flood'),
                    label: strings.guideActionFlood,
                    icon: Icons.flood,
                    onPressed: () => _openArticle(context, 'flood-avoidance'),
                  ),
                  _GuideAction(
                    key: const Key('guide-quick-action-fire'),
                    label: strings.guideActionFire,
                    icon: Icons.local_fire_department_outlined,
                    onPressed: () => _openArticle(context, 'fire-escape'),
                  ),
                  _GuideAction(
                    key: const Key('guide-quick-action-first-aid'),
                    label: strings.guideActionFirstAid,
                    icon: Icons.medical_services_outlined,
                    onPressed: () =>
                        _openArticle(context, 'first-aid-assessment'),
                  ),
                  _GuideAction(
                    key: const Key('guide-quick-action-map'),
                    label: strings.guideActionMap,
                    icon: Icons.map_outlined,
                    onPressed: () => context.go('/map'),
                  ),
                  _GuideAction(
                    key: const Key('guide-quick-action-sos'),
                    label: strings.guideActionSos,
                    icon: Icons.sos,
                    onPressed: () => context.go('/sos'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GuideNextSteps(
                heading: strings.guideNextStepsHeading,
                actions: [
                  _GuideAction(
                    key: const Key('guide-next-step-map'),
                    label: strings.guideNextStepMap,
                    icon: Icons.map_outlined,
                    onPressed: () => context.go('/map'),
                  ),
                  _GuideAction(
                    key: const Key('guide-next-step-sos'),
                    label: strings.guideNextStepSos,
                    icon: Icons.sos,
                    onPressed: () => context.go('/sos'),
                  ),
                  _GuideAction(
                    key: const Key('guide-next-step-assistant'),
                    label: strings.guideNextStepAssistant,
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => context.push('/guide/assistant'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: strings.guideSearchLabel,
                  hintText: strings.guideSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: strings.guideSearchAction,
                    onPressed: () => ref
                        .read(guideControllerProvider.notifier)
                        .search(_searchController.text),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
                onSubmitted: (value) =>
                    ref.read(guideControllerProvider.notifier).search(value),
              ),
              const SizedBox(height: 12),
              Text(
                strings.guideCategories,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryChip(
                    label: strings.guideCategoryAll,
                    selected: state.category == null,
                    onSelected: () => ref
                        .read(guideControllerProvider.notifier)
                        .selectCategory(null),
                  ),
                  for (final category in _categories)
                    _CategoryChip(
                      label: _categoryLabel(strings, category),
                      selected: state.category == category,
                      onSelected: () => ref
                          .read(guideControllerProvider.notifier)
                          .selectCategory(category),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              switch (state.phase) {
                GuidePhase.loading => Semantics(
                  label: strings.guideLoading,
                  liveRegion: true,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                GuidePhase.empty => _StatusCard(
                  icon: Icons.search_off,
                  text: strings.guideNoResults,
                ),
                GuidePhase.error => _StatusCard(
                  icon: Icons.storage_outlined,
                  text: strings.guideStorageError,
                  action: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(guideControllerProvider.notifier).retry(),
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.retry),
                  ),
                ),
                GuidePhase.data => Column(
                  children: [
                    for (final article in state.articles) ...[
                      _ArticleCard(article: article),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

void _openArticle(BuildContext context, String articleId) {
  context.push('/guide/article/${Uri.encodeComponent(articleId)}');
}

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final burmese = Localizations.localeOf(context).languageCode == 'my';
    return Scaffold(
      appBar: AppBar(title: Text(strings.guideArticleTitle)),
      body: SafeArea(
        child: FutureBuilder<EmergencyArticle?>(
          future: ref.read(emergencyGuideRepositoryProvider).getById(articleId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: Semantics(
                  label: strings.guideLoading,
                  liveRegion: true,
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            final article = snapshot.data;
            if (snapshot.hasError || article == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    strings.guideArticleUnavailable,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  article.titleForLanguage(burmese: burmese),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),
                Text(article.answerForLanguage(burmese: burmese)),
                const SizedBox(height: 20),
                ArticleSourceCard(article: article),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ArticleSourceCard extends StatelessWidget {
  const ArticleSourceCard({required this.article, super.key});

  final EmergencyArticle article;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sourceDate = article.sourceUpdatedAt;
    return Semantics(
      container: true,
      label: strings.guideSourceSemantics(
        article.sourceName,
        article.contentVersion,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.guideApprovedSource,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.guideSourceName(article.sourceName)),
              Text(strings.guideContentVersion(article.contentVersion)),
              Text(
                strings.guideReviewedDate(
                  DateFormat.yMMMd(locale).format(article.reviewedAt),
                ),
              ),
              if (sourceDate != null)
                Text(
                  strings.guideSourceDate(
                    DateFormat.yMMMd(locale).format(sourceDate),
                  ),
                ),
              const SizedBox(height: 8),
              SelectableText(article.sourceUrl),
              const SizedBox(height: 8),
              Text(strings.guideContentWarning),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final EmergencyArticle article;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final burmese = Localizations.localeOf(context).languageCode == 'my';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push('/guide/article/${Uri.encodeComponent(article.id)}'),
        child: Semantics(
          button: true,
          hint: strings.guideOpenArticleHint,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Icon(_categoryIcon(article.category))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.titleForLanguage(burmese: burmese),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(strings.guideSourceName(article.sourceName)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _GuideAction {
  const _GuideAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final Key key;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _GuideQuickActions extends StatelessWidget {
  const _GuideQuickActions({required this.heading, required this.actions});

  final String heading;
  final List<_GuideAction> actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(heading, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final action in actions)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ActionChip(
                key: action.key,
                avatar: Icon(action.icon, size: 20),
                label: Text(action.label),
                onPressed: action.onPressed,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
        ],
      ),
    ],
  );
}

class _GuideNextSteps extends StatelessWidget {
  const _GuideNextSteps({required this.heading, required this.actions});

  final String heading;
  final List<_GuideAction> actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(heading, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final action in actions)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                key: action.key,
                onPressed: action.onPressed,
                icon: Icon(action.icon, size: 20),
                label: Text(action.label),
              ),
            ),
        ],
      ),
    ],
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: text,
    child: Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.offline_bolt_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

const _categories = ['earthquake', 'flood', 'fire', 'first_aid'];

String _categoryLabel(AppLocalizations strings, String category) =>
    switch (category) {
      'earthquake' => strings.guideCategoryEarthquake,
      'flood' => strings.guideCategoryFlood,
      'fire' => strings.guideCategoryFire,
      'first_aid' => strings.guideCategoryFirstAid,
      _ => category,
    };

IconData _categoryIcon(String category) => switch (category) {
  'earthquake' => Icons.vibration,
  'flood' => Icons.flood,
  'fire' => Icons.local_fire_department_outlined,
  'first_aid' => Icons.medical_services_outlined,
  _ => Icons.menu_book_outlined,
};
