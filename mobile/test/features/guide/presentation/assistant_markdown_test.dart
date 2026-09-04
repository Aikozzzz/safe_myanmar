import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/guide/presentation/assistant_markdown.dart';

void main() {
  testWidgets('renders supported Markdown without raw syntax', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssistantFormattedText(
            text:
                '# Immediate steps\n\n**Move now** and use `Drop, cover, hold`.\n\n- Stay calm\n- Follow local instructions\n1. Contact authorized help',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('# Immediate steps'), findsNothing);
    expect(find.textContaining('**Move now**'), findsNothing);
    expect(find.textContaining('`Drop, cover, hold`'), findsNothing);
    expect(find.byType(RichText), findsWidgets);
    final renderedText = find
        .byType(RichText)
        .evaluate()
        .map((element) => (element.widget as RichText).text.toPlainText())
        .join('\n');
    expect(renderedText, contains('Immediate steps'));
    expect(renderedText, contains('Move now'));
    expect(renderedText, contains('Drop, cover, hold'));
    expect(renderedText, contains('• Stay calm'));
    expect(renderedText, contains('1. Contact authorized help'));
  });

  testWidgets('typing text exposes the complete answer to semantics', (
    tester,
  ) async {
    const answer = '**Move now**\n- Follow local instructions';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AssistantTypingText(text: answer)),
      ),
    );
    await tester.pump();

    expect(tester.getSemantics(find.byType(AssistantTypingText)).label, answer);
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('**Move now**'), findsNothing);
  });
}
