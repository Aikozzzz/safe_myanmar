import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/assistant_controller.dart';
import '../application/providers.dart';
import '../domain/intent_classifier.dart';
import '../domain/sos_text_extractor.dart';
import 'guide_screens.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(assistantControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.assistantTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _AssistantNotice(
                    icon: Icons.offline_bolt_outlined,
                    text: strings.assistantDeterministicActive,
                  ),
                  const SizedBox(height: 8),
                  _CapabilityBanner(state: state),
                  const SizedBox(height: 12),
                  Text(
                    strings.assistantSuggestedQuestions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final suggestion in [
                        strings.assistantSuggestionEarthquake,
                        strings.assistantSuggestionTrapped,
                        strings.assistantSuggestionFirstAid,
                        strings.assistantSuggestionFlood,
                      ])
                        ActionChip(
                          label: Text(suggestion),
                          onPressed: () => _send(suggestion),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final message in state.messages) ...[
                    _MessageCard(message: message),
                    const SizedBox(height: 12),
                  ],
                  if (state.isLoading)
                    Semantics(
                      label: strings.assistantSearching,
                      liveRegion: true,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Material(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 500,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          labelText: strings.assistantInputLabel,
                          hintText: strings.assistantInputHint,
                        ),
                        onSubmitted: state.isLoading ? null : _send,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: strings.assistantSend,
                      onPressed: state.isLoading
                          ? null
                          : () => _send(_inputController.text),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(String value) async {
    if (value.trim().isEmpty) return;
    _inputController.clear();
    await ref.read(assistantControllerProvider.notifier).send(value);
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(message.text!),
          ),
        ),
      );
    }
    final result = message.result!;
    final article = message.article;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.assistantVerifiedAnswer,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (article != null) ...[
                Text(article.answerEn),
                const Divider(height: 24),
                Text(article.answerMy),
                const SizedBox(height: 12),
                if (message.localRewording case final rewording?) ...[
                  _LocalRewordingCard(text: rewording),
                  const SizedBox(height: 12),
                ],
                ArticleSourceCard(article: article),
              ] else if (message.gemmaAnswer case final answer?) ...[
                Text(
                  strings.assistantGemmaAnswerTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(answer),
              ] else
                Text(_replyText(strings, message.replyKind!)),
              const SizedBox(height: 10),
              Text(
                _responseEngineText(strings, message.responseEngine!),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                strings.assistantConfidence(
                  (result.confidence * 100).round(),
                  _classifierExplanation(
                    strings,
                    result,
                    message.responseEngine!,
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (message.sosDraft case final draft?) ...[
                const SizedBox(height: 12),
                _SosDraftCard(draft: draft),
              ],
              if (result.intent == EmergencyIntent.trappedPerson ||
                  result.intent == EmergencyIntent.sendSos) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.go('/sos'),
                  icon: const Icon(Icons.sos),
                  label: Text(strings.assistantReviewSos),
                ),
              ],
              if (result.intent == EmergencyIntent.safeRoute ||
                  result.intent == EmergencyIntent.findShelter) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.go('/map'),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(strings.assistantOpenMap),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CapabilityBanner extends StatelessWidget {
  const _CapabilityBanner({required this.state});

  final AssistantState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final onnx = _onnxStatusText(strings, state.onnxStatus);
    final gemma = _gemmaStatusText(strings, state.gemmaStatus);
    return Semantics(
      container: true,
      label: '$onnx $gemma',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CapabilityRow(icon: Icons.account_tree_outlined, text: onnx),
              const SizedBox(height: 8),
              _CapabilityRow(icon: Icons.notes_outlined, text: gemma),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class _LocalRewordingCard extends StatelessWidget {
  const _LocalRewordingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: strings.assistantLocalRewordingSemantics(text),
      child: Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.assistantLocalRewordingTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(text),
              const SizedBox(height: 8),
              Text(
                strings.assistantLocalRewordingWarning,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosDraftCard extends StatelessWidget {
  const _SosDraftCard({required this.draft});

  final SosTextDraft draft;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.assistantSosDraftTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (draft.incident != null)
              Text(strings.assistantDraftIncident(draft.incident!)),
            if (draft.status != null)
              Text(strings.assistantDraftStatus(draft.status!)),
            if (draft.injury != null)
              Text(strings.assistantDraftInjury(draft.injury!)),
            if (draft.locationPhrase != null)
              Text(strings.assistantDraftLocation(draft.locationPhrase!)),
            if (draft.batteryPercent != null)
              Text(strings.assistantDraftBattery(draft.batteryPercent!)),
            const SizedBox(height: 6),
            Text(strings.assistantSosDraftWarning),
          ],
        ),
      ),
    );
  }
}

class _AssistantNotice extends StatelessWidget {
  const _AssistantNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

String _replyText(AppLocalizations strings, AssistantReplyKind kind) =>
    switch (kind) {
      AssistantReplyKind.mapAction => strings.assistantMapResponse,
      AssistantReplyKind.sosAction => strings.assistantSosResponse,
      AssistantReplyKind.missingPerson => strings.assistantMissingResponse,
      AssistantReplyKind.reportDamage => strings.assistantDamageResponse,
      AssistantReplyKind.unknown => strings.assistantUnknownResponse,
      AssistantReplyKind.unavailable => strings.assistantUnavailableResponse,
      AssistantReplyKind.article => strings.assistantUnavailableResponse,
    };

String _classifierExplanation(
  AppLocalizations strings,
  IntentResult result,
  AssistantResponseEngine engine,
) {
  if (engine == AssistantResponseEngine.gemma) {
    return strings.assistantClassifierGemma;
  }
  if (engine == AssistantResponseEngine.onnx) {
    return strings.assistantClassifierOnnx;
  }
  if (result.matchedTerms.isEmpty) return strings.assistantClassifierNoMatch;
  if (result.intent == EmergencyIntent.unknown) {
    return strings.assistantClassifierLowConfidence;
  }
  return strings.assistantClassifierMatched(result.matchedTerms.join(', '));
}

String _responseEngineText(
  AppLocalizations strings,
  AssistantResponseEngine engine,
) => switch (engine) {
  AssistantResponseEngine.deterministic => strings.assistantEngineDeterministic,
  AssistantResponseEngine.onnx => strings.assistantEngineOnnx,
  AssistantResponseEngine.gemma => strings.assistantEngineGemma,
};

String _onnxStatusText(
  AppLocalizations strings,
  AssistantCapabilityStatus status,
) => switch (status) {
  AssistantCapabilityStatus.checking => strings.assistantOnnxChecking,
  AssistantCapabilityStatus.available => strings.assistantOnnxAvailable,
  AssistantCapabilityStatus.unavailable => strings.assistantOnnxUnavailable,
};

String _gemmaStatusText(
  AppLocalizations strings,
  AssistantCapabilityStatus status,
) => switch (status) {
  AssistantCapabilityStatus.checking => strings.assistantGemmaChecking,
  AssistantCapabilityStatus.available => strings.assistantGemmaAvailable,
  AssistantCapabilityStatus.unavailable => strings.assistantGemmaUnavailable,
};
