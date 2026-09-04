import 'package:flutter/material.dart';

class AssistantFormattedText extends StatelessWidget {
  const AssistantFormattedText({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => _AssistantMarkdownView(text: text);
}

class AssistantTypingText extends StatefulWidget {
  const AssistantTypingText({required this.text, super.key});

  final String text;

  @override
  State<AssistantTypingText> createState() => _AssistantTypingTextState();
}

class _AssistantTypingTextState extends State<AssistantTypingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late _AssistantMarkdownDocument _document;
  var _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _document = _AssistantMarkdownDocument.parse(widget.text);
    _controller = AnimationController(
      vsync: this,
      duration: _typingDuration(widget.text),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationStarted) return;
    _animationStarted = true;
    if (widget.text.isEmpty || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AssistantTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    _document = _AssistantMarkdownDocument.parse(widget.text);
    _controller
      ..duration = _typingDuration(widget.text)
      ..reset();
    if (widget.text.isEmpty || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: widget.text,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final totalCharacters = _document.hasFormatting
              ? _document.totalCharacters
              : widget.text.length;
          final visibleCharacters = (totalCharacters * _controller.value)
              .round();
          if (!_document.hasFormatting) {
            return Text(_visiblePlainText(widget.text, visibleCharacters));
          }
          return _AssistantDocumentView(
            document: _document,
            visibleCharacters: visibleCharacters,
          );
        },
      ),
    ),
  );
}

class _AssistantMarkdownDocument {
  const _AssistantMarkdownDocument._({
    required this.blocks,
    required this.hasFormatting,
  });

  final List<_MarkdownBlock> blocks;
  final bool hasFormatting;

  int get totalCharacters =>
      blocks.fold<int>(0, (total, block) => total + block.characterCount);

  factory _AssistantMarkdownDocument.parse(String source) {
    final blocks = <_MarkdownBlock>[];
    var hasFormatting = false;
    final lines = source
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line.trim());
      if (heading != null) {
        blocks.add(
          _MarkdownBlock(
            kind: _MarkdownBlockKind.heading,
            headingLevel: heading.group(1)!.length,
            spans: _parseInline(heading.group(2)!).spans,
          ),
        );
        hasFormatting = true;
        continue;
      }
      final unordered = RegExp(r'^[-*]\s+(.+)$').firstMatch(line.trim());
      if (unordered != null) {
        final parsed = _parseInline(unordered.group(1)!);
        blocks.add(
          _MarkdownBlock(
            kind: _MarkdownBlockKind.unordered,
            prefix: '• ',
            spans: parsed.spans,
          ),
        );
        hasFormatting = true;
        continue;
      }
      final ordered = RegExp(r'^(\d+)[.)]\s+(.+)$').firstMatch(line.trim());
      if (ordered != null) {
        final parsed = _parseInline(ordered.group(2)!);
        blocks.add(
          _MarkdownBlock(
            kind: _MarkdownBlockKind.ordered,
            prefix: '${ordered.group(1)}. ',
            spans: parsed.spans,
          ),
        );
        hasFormatting = true;
        continue;
      }
      final parsed = _parseInline(line);
      blocks.add(
        _MarkdownBlock(kind: _MarkdownBlockKind.paragraph, spans: parsed.spans),
      );
      hasFormatting = hasFormatting || parsed.hasFormatting;
    }
    return _AssistantMarkdownDocument._(
      blocks: List.unmodifiable(blocks),
      hasFormatting: hasFormatting,
    );
  }
}

class _AssistantMarkdownView extends StatelessWidget {
  const _AssistantMarkdownView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final document = _AssistantMarkdownDocument.parse(text);
    if (!document.hasFormatting) return Text(text);
    return _AssistantDocumentView(document: document);
  }
}

class _AssistantDocumentView extends StatelessWidget {
  const _AssistantDocumentView({
    required this.document,
    this.visibleCharacters,
  });

  final _AssistantMarkdownDocument document;
  final int? visibleCharacters;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var consumed = 0;
    for (final block in document.blocks) {
      final visible = visibleCharacters == null
          ? block.characterCount
          : (visibleCharacters! - consumed)
                .clamp(0, block.characterCount)
                .toInt();
      consumed += block.characterCount;
      if (visible == 0) continue;
      children.add(
        _MarkdownBlockView(block: block, visibleCharacters: visible),
      );
      children.add(const SizedBox(height: 8));
    }
    if (children.isNotEmpty) children.removeLast();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _MarkdownBlockView extends StatelessWidget {
  const _MarkdownBlockView({
    required this.block,
    required this.visibleCharacters,
  });

  final _MarkdownBlock block;
  final int visibleCharacters;

  @override
  Widget build(BuildContext context) {
    var remaining = visibleCharacters;
    var prefix = '';
    if (block.prefix.isNotEmpty) {
      final prefixLength = remaining.clamp(0, block.prefix.length).toInt();
      prefix = block.prefix.substring(0, prefixLength);
      remaining -= prefixLength;
    }
    final spans = <TextSpan>[];
    if (prefix.isNotEmpty) spans.add(TextSpan(text: prefix));
    for (final span in block.spans) {
      if (remaining <= 0) break;
      final length = remaining.clamp(0, span.text.length).toInt();
      if (length > 0) {
        spans.add(
          TextSpan(
            text: span.text.substring(0, length),
            style: _spanStyle(span.style),
          ),
        );
      }
      remaining -= length;
    }
    final baseStyle = switch (block.kind) {
      _MarkdownBlockKind.heading => switch (block.headingLevel) {
        1 => Theme.of(context).textTheme.titleLarge,
        2 => Theme.of(context).textTheme.titleMedium,
        _ => Theme.of(context).textTheme.titleSmall,
      },
      _ => DefaultTextStyle.of(context).style,
    };
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

enum _MarkdownBlockKind { paragraph, heading, unordered, ordered }

final class _MarkdownBlock {
  const _MarkdownBlock({
    required this.kind,
    required this.spans,
    this.prefix = '',
    this.headingLevel = 0,
  });

  final _MarkdownBlockKind kind;
  final List<_MarkdownSpan> spans;
  final String prefix;
  final int headingLevel;

  int get characterCount =>
      prefix.length + spans.fold(0, (total, span) => total + span.text.length);
}

final class _MarkdownSpan {
  const _MarkdownSpan(this.text, this.style);

  final String text;
  final _InlineStyle style;
}

final class _InlineParseResult {
  const _InlineParseResult(this.spans, this.hasFormatting);

  final List<_MarkdownSpan> spans;
  final bool hasFormatting;
}

final class _InlineStyle {
  const _InlineStyle({
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.link = false,
  });

  final bool bold;
  final bool italic;
  final bool code;
  final bool link;

  _InlineStyle copyWith({bool? bold, bool? italic, bool? code, bool? link}) =>
      _InlineStyle(
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        code: code ?? this.code,
        link: link ?? this.link,
      );
}

_InlineParseResult _parseInline(
  String source, {
  _InlineStyle style = const _InlineStyle(),
}) {
  final spans = <_MarkdownSpan>[];
  var hasFormatting = false;
  var index = 0;
  var plainStart = 0;

  void addPlain(String value) {
    if (value.isNotEmpty) spans.add(_MarkdownSpan(value, style));
  }

  void flushPlain(int end) {
    addPlain(source.substring(plainStart, end));
    plainStart = end;
  }

  while (index < source.length) {
    final marker =
        source.startsWith('**', index) || source.startsWith('__', index)
        ? source.substring(index, index + 2)
        : null;
    if (marker != null) {
      final close = source.indexOf(marker, index + 2);
      if (close > index + 2) {
        flushPlain(index);
        final nested = _parseInline(
          source.substring(index + 2, close),
          style: style.copyWith(bold: true),
        );
        spans.addAll(nested.spans);
        hasFormatting = true;
        index = close + 2;
        plainStart = index;
        continue;
      }
    }
    if (source[index] == '*' || source[index] == '_') {
      final marker = source[index];
      final close = source.indexOf(marker, index + 1);
      if (close > index + 1) {
        flushPlain(index);
        final nested = _parseInline(
          source.substring(index + 1, close),
          style: style.copyWith(italic: true),
        );
        spans.addAll(nested.spans);
        hasFormatting = true;
        index = close + 1;
        plainStart = index;
        continue;
      }
    }
    if (source[index] == '`') {
      final close = source.indexOf('`', index + 1);
      if (close > index + 1) {
        flushPlain(index);
        spans.add(
          _MarkdownSpan(
            source.substring(index + 1, close),
            style.copyWith(code: true),
          ),
        );
        hasFormatting = true;
        index = close + 1;
        plainStart = index;
        continue;
      }
    }
    if (source[index] == '[') {
      final labelEnd = source.indexOf('](', index + 1);
      final urlEnd = labelEnd < 0 ? -1 : source.indexOf(')', labelEnd + 2);
      if (labelEnd > index + 1 && urlEnd > labelEnd + 2) {
        flushPlain(index);
        final nested = _parseInline(
          source.substring(index + 1, labelEnd),
          style: style.copyWith(link: true),
        );
        spans.addAll(nested.spans);
        hasFormatting = true;
        index = urlEnd + 1;
        plainStart = index;
        continue;
      }
    }
    index++;
  }
  flushPlain(source.length);
  return _InlineParseResult(spans, hasFormatting);
}

TextStyle _spanStyle(_InlineStyle style) => TextStyle(
  fontWeight: style.bold ? FontWeight.bold : null,
  fontStyle: style.italic ? FontStyle.italic : null,
  fontFamily: style.code ? 'monospace' : null,
  backgroundColor: style.code ? const Color(0x14000000) : null,
  decoration: style.link ? TextDecoration.underline : null,
);

Duration _typingDuration(String text) =>
    Duration(milliseconds: (text.length * 18).clamp(450, 2200).toInt());

String _visiblePlainText(String text, int visibleCharacters) {
  return text.substring(0, visibleCharacters.clamp(0, text.length).toInt());
}
