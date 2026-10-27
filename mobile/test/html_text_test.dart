import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortex_app/presentation/widgets/html_text.dart';

void main() {
  group('parseRichHtml', () {
    test('a plain-text description still shows, untouched', () {
      final blocks = parseRichHtml('Just a sentence.');
      expect(blocks, hasLength(1));
      expect(blocks.single.kind, RichHtmlBlockKind.paragraph);
      expect(blocks.single.text, 'Just a sentence.');
    });

    test('an empty description produces nothing to draw', () {
      expect(parseRichHtml(''), isEmpty);
      expect(parseRichHtml('   '), isEmpty);
      expect(parseRichHtml('<p></p>'), isEmpty);
    });

    test('paragraph tags never reach the customer as text', () {
      final blocks = parseRichHtml('<p>Great shoes</p><p>Second line</p>');
      expect(blocks.map((b) => b.text), ['Great shoes', 'Second line']);
      for (final block in blocks) {
        expect(block.text, isNot(contains('<')));
        expect(block.text, isNot(contains('p>')));
      }
    });

    test('bold and italic become styles, not visible tags', () {
      final blocks = parseRichHtml(
        '<p>A <strong>bold</strong> and <em>italic</em> line.</p>',
      );
      final spans = blocks.single.spans;
      expect(blocks.single.text, 'A bold and italic line.');
      expect(spans.firstWhere((s) => s.text == 'bold').bold, isTrue);
      expect(spans.firstWhere((s) => s.text == 'italic').italic, isTrue);
      expect(spans.firstWhere((s) => s.text == 'A ').bold, isFalse);
    });

    test('strikethrough and underline survive', () {
      final blocks = parseRichHtml('<p><s>old</s> <u>new</u></p>');
      final spans = blocks.single.spans;
      expect(spans.firstWhere((s) => s.text == 'old').strike, isTrue);
      expect(spans.firstWhere((s) => s.text == 'new').underline, isTrue);
    });

    test('headings keep their level', () {
      final blocks = parseRichHtml('<h2>Key features</h2><p>Body</p>');
      expect(blocks.first.kind, RichHtmlBlockKind.heading);
      expect(blocks.first.headingLevel, 2);
      expect(blocks.first.text, 'Key features');
      expect(blocks.last.kind, RichHtmlBlockKind.paragraph);
    });

    test('bullet lists get bullets', () {
      final blocks = parseRichHtml('<ul><li>First</li><li>Second</li></ul>');
      expect(blocks, hasLength(2));
      expect(blocks.every((b) => b.kind == RichHtmlBlockKind.listItem), isTrue);
      expect(blocks.map((b) => b.marker), ['•', '•']);
      expect(blocks.map((b) => b.text), ['First', 'Second']);
    });

    test('numbered lists count up', () {
      final blocks = parseRichHtml('<ol><li>One</li><li>Two</li><li>Three</li></ol>');
      expect(blocks.map((b) => b.marker), ['1.', '2.', '3.']);
    });

    test('a nested list is indented', () {
      final blocks = parseRichHtml(
        '<ul><li>Outer</li><ul><li>Inner</li></ul></ul>',
      );
      expect(blocks.map((b) => b.text), ['Outer', 'Inner']);
      expect(blocks.first.depth, 0);
      expect(blocks.last.depth, 1);
    });

    test('quotes, dividers and images become their own blocks', () {
      final blocks = parseRichHtml(
        '<blockquote>Quoted</blockquote><hr><img src="https://x.test/a.png">',
      );
      expect(blocks[0].kind, RichHtmlBlockKind.quote);
      expect(blocks[0].text, 'Quoted');
      expect(blocks[1].kind, RichHtmlBlockKind.divider);
      expect(blocks[2].kind, RichHtmlBlockKind.image);
      expect(blocks[2].imageUrl, 'https://x.test/a.png');
    });

    test('links keep their address', () {
      final blocks = parseRichHtml(
        '<p>See <a href="https://shop.test/size">the size guide</a></p>',
      );
      final link = blocks.single.spans.firstWhere((s) => s.href != null);
      expect(link.text, 'the size guide');
      expect(link.href, 'https://shop.test/size');
    });

    test('centred text is centred, and right aligns to the end so RTL mirrors',
        () {
      expect(
        parseRichHtml('<p style="text-align: center">Mid</p>').single.align,
        TextAlign.center,
      );
      expect(
        parseRichHtml('<p style="text-align: right">End</p>').single.align,
        TextAlign.end,
      );
      expect(parseRichHtml('<p>Plain</p>').single.align, TextAlign.start);
    });

    test('a line break inside a paragraph is kept', () {
      final blocks = parseRichHtml('<p>One<br>Two</p>');
      expect(blocks.single.text, 'One\nTwo');
    });

    test('indentation between tags does not become stray spaces', () {
      final blocks = parseRichHtml('<p>\n    Spaced out\n</p>');
      expect(blocks.single.text, 'Spaced out');
    });

    test('an unknown tag contributes its text, never the tag itself', () {
      final blocks = parseRichHtml(
        '<p>Tea <span class="x">and</span> <marquee>coffee</marquee></p>',
      );
      expect(blocks.single.text, 'Tea and coffee');
      expect(blocks.single.text, isNot(contains('<')));
    });

    test('escaped characters read as the real character', () {
      final blocks = parseRichHtml('<p>Tea &amp; Coffee &#39;blend&#39; 30&deg;</p>');
      expect(blocks.single.text, "Tea & Coffee 'blend' 30°");
    });
  });

  group('decodeHtmlEntities', () {
    test('handles named, decimal and hex forms', () {
      expect(decodeHtmlEntities('a &amp; b'), 'a & b');
      expect(decodeHtmlEntities('&#39;q&#39;'), "'q'");
      expect(decodeHtmlEntities('&#x27;q&#x27;'), "'q'");
    });

    test('leaves something it does not know alone', () {
      expect(decodeHtmlEntities('&notareal;'), '&notareal;');
    });
  });

  group('HtmlText widget', () {
    testWidgets('shows the words and none of the tags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HtmlText(
              html: '<h3>Features</h3><ul><li>Waterproof</li></ul>'
                  '<p>Made of <strong>leather</strong>.</p>',
              baseStyle: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      expect(find.text('Features'), findsOneWidget);
      expect(find.text('•'), findsOneWidget);
      expect(find.textContaining('<'), findsNothing);
      expect(find.textContaining('</p>'), findsNothing);
    });

    testWidgets('clipped variant renders one text block', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HtmlText(
              html: '<p>Line one</p><p>Line two</p>',
              baseStyle: TextStyle(fontSize: 13),
              maxLines: 2,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 2);
      expect(text.textSpan!.toPlainText(), 'Line one\nLine two');
    });
  });
}
