import 'package:flutter/material.dart';

import '../../app/theme/safe_tokens.dart';

class SafeContent extends StatelessWidget {
  const SafeContent({
    required this.child,
    this.maxWidth = SafeContentWidth.readable,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class SafeStatusCard extends StatelessWidget {
  const SafeStatusCard({
    required this.icon,
    required this.message,
    this.title,
    this.action,
    this.emphasized = false,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Card(
        elevation: emphasized ? SafeElevation.raised : SafeElevation.card,
        color: emphasized ? colors.secondaryContainer : null,
        shape: const RoundedRectangleBorder(borderRadius: SafeRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(SafeSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: emphasized ? colors.onSecondaryContainer : null,
              ),
              const SizedBox(width: SafeSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: SafeSpacing.xs),
                    ],
                    Text(message),
                    if (action != null) ...[
                      const SizedBox(height: SafeSpacing.md),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SafePageHeader extends StatelessWidget {
  const SafePageHeader({required this.title, this.description, super.key});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (description != null) ...[
          const SizedBox(height: SafeSpacing.sm),
          Text(description!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
    );
  }
}
