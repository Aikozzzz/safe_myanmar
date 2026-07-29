import 'dart:async';

import 'package:flutter/material.dart';

class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    required this.label,
    required this.progressLabel,
    required this.cancelledLabel,
    required this.semanticsHint,
    required this.accessibleLabel,
    required this.onConfirmed,
    required this.onAccessibleConfirm,
    this.enabled = true,
    this.duration = const Duration(seconds: 3),
    super.key,
  });

  final String label;
  final String Function(int percent) progressLabel;
  final String cancelledLabel;
  final String semanticsHint;
  final String accessibleLabel;
  final Future<void> Function() onConfirmed;
  final Future<void> Function() onAccessibleConfirm;
  final bool enabled;
  final Duration duration;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _cancelledTimer;
  bool _holding = false;
  bool _completed = false;
  bool _showCancelled = false;
  int? _pointer;
  Offset? _pointerOrigin;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed) {
          _completed = true;
          _holding = false;
          unawaited(_confirm());
        }
      });
  }

  @override
  void didUpdateWidget(HoldToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!widget.enabled && oldWidget.enabled) _cancel(showFeedback: false);
  }

  @override
  void dispose() {
    _cancelledTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start(PointerDownEvent event) {
    if (!widget.enabled || _holding || _pointer != null) return;
    _cancelledTimer?.cancel();
    _pointer = event.pointer;
    _pointerOrigin = event.position;
    setState(() {
      _holding = true;
      _completed = false;
      _showCancelled = false;
    });
    _controller.forward(from: 0);
  }

  void _move(PointerMoveEvent event) {
    final origin = _pointerOrigin;
    if (_pointer != event.pointer || origin == null) return;
    if ((event.position - origin).distance > 18) {
      _pointer = null;
      _pointerOrigin = null;
      if (_holding && !_completed) _cancel(showFeedback: true);
    }
  }

  void _release(PointerEvent event) {
    if (_pointer != event.pointer) return;
    _pointer = null;
    _pointerOrigin = null;
    if (_holding && !_completed) _cancel(showFeedback: true);
  }

  void _cancel({required bool showFeedback}) {
    _controller.stop();
    _controller.value = 0;
    if (!mounted) return;
    setState(() {
      _holding = false;
      _completed = false;
      _showCancelled = showFeedback;
    });
    _cancelledTimer?.cancel();
    if (showFeedback) {
      _cancelledTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showCancelled = false);
      });
    }
  }

  Future<void> _confirm() async {
    await widget.onConfirmed();
    if (!mounted) return;
    _controller.value = 0;
    setState(() {
      _completed = false;
      _showCancelled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.label,
          hint: widget.semanticsHint,
          onTap: widget.enabled ? widget.onAccessibleConfirm : null,
          child: ExcludeSemantics(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: widget.enabled ? _start : null,
              onPointerMove: widget.enabled ? _move : null,
              onPointerUp: widget.enabled ? _release : null,
              onPointerCancel: widget.enabled ? _release : null,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? colors.errorContainer
                        : colors.surfaceContainerHighest,
                    border: Border.all(
                      color: widget.enabled ? colors.error : colors.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _holding
                            ? widget.progressLabel(
                                (_controller.value * 100).round(),
                              )
                            : _showCancelled
                            ? widget.cancelledLabel
                            : widget.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 8,
                        color: colors.error,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: widget.enabled ? widget.onAccessibleConfirm : null,
          icon: const Icon(Icons.accessibility_new),
          label: Text(widget.accessibleLabel),
        ),
      ],
    );
  }
}
