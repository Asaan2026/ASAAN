import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the formatted text a shop owner typed in the dashboard.
///
/// Product descriptions are written in a rich-text editor on the web
/// dashboard, so what the API returns is HTML: paragraphs, headings, bold,
/// italic, lists, quotes, links and images. Put that string into a plain
/// [Text] widget and the customer reads the tags themselves
/// ("&lt;p&gt;Great shoes&lt;/p&gt;"), which is the bug this widget exists to
/// prevent.
///
/// This is deliberately a small renderer rather than a third-party HTML
/// package: the set of tags is fixed by our own editor and by the server-side
/// filter in config/purifier.php, and the app handles payments, so it is worth
/// not pulling extra packages in for this.
///
/// Anything it does not recognise degrades to its text content, so an
/// unexpected tag can never leak into what the customer reads.
class HtmlText extends StatefulWidget {
  const HtmlText({
    super.key,
    required this.html,
    required this.baseStyle,
    this.linkColor,
    this.quoteColor,
    this.maxLines,
  });

  /// The HTML (or plain text) to show.
  final String html;

  /// Style for ordinary body text. Headings, quotes and code derive from it.
  final TextStyle baseStyle;

  final Color? linkColor;
  final Color? quoteColor;

  /// When set, everything is rendered as one block of text clipped to this
  /// many lines — for cards and list rows, where a heading or an image in the
  /// middle of a row would break the layout.
  final int? maxLines;

  @override
  State<HtmlText> createState() => _HtmlTextState();
}

class _HtmlTextState extends State<HtmlText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _linkRecognizer(String href) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () async {
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();

    final blocks = parseRichHtml(widget.html);

    if (widget.maxLines != null) {
      return Text.rich(
        TextSpan(
          children: _flatSpans(blocks),
          style: widget.baseStyle,
        ),
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final widgets = <Widget>[];
    for (final block in blocks) {
      final rendered = _buildBlock(block);
      if (rendered != null) widgets.add(rendered);
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// One run of text for the clipped variant: every block joined by newlines,
  /// so a bulleted list still reads as a list in a product card.
  List<InlineSpan> _flatSpans(List<RichHtmlBlock> blocks) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.kind == RichHtmlBlockKind.image ||
          block.kind == RichHtmlBlockKind.divider) {
        continue;
      }
      if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
      if (block.kind == RichHtmlBlockKind.listItem) {
        spans.add(TextSpan(text: '${block.marker}  '));
      }
      spans.addAll(_inlineSpans(block.spans, widget.baseStyle));
    }
    return spans;
  }

  Widget? _buildBlock(RichHtmlBlock block) {
    switch (block.kind) {
      case RichHtmlBlockKind.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: _mutedColor.withValues(alpha: 0.4)),
        );

      case RichHtmlBlockKind.image:
        final src = block.imageUrl ?? '';
        if (src.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              src,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );

      case RichHtmlBlockKind.heading:
        final scale = switch (block.headingLevel) {
          1 => 1.5,
          2 => 1.3,
          3 => 1.15,
          _ => 1.0,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text.rich(
            TextSpan(children: _inlineSpans(block.spans, widget.baseStyle)),
            textAlign: block.align,
            style: widget.baseStyle.copyWith(
              fontSize: (widget.baseStyle.fontSize ?? 14) * scale,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        );

      case RichHtmlBlockKind.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsetsDirectional.only(start: 12),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: _mutedColor, width: 3),
            ),
          ),
          child: Text.rich(
            TextSpan(children: _inlineSpans(block.spans, widget.baseStyle)),
            textAlign: block.align,
            style: widget.baseStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: widget.quoteColor ?? _mutedColor,
            ),
          ),
        );

      case RichHtmlBlockKind.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _mutedColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            block.spans.map((s) => s.text).join(),
            style: widget.baseStyle.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        );

      case RichHtmlBlockKind.listItem:
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: 16.0 * block.depth,
            bottom: 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(block.marker, style: widget.baseStyle),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _inlineSpans(block.spans, widget.baseStyle),
                  ),
                  style: widget.baseStyle,
                ),
              ),
            ],
          ),
        );

      case RichHtmlBlockKind.paragraph:
        if (block.spans.every((s) => s.text.trim().isEmpty)) return null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(children: _inlineSpans(block.spans, widget.baseStyle)),
            textAlign: block.align,
            style: widget.baseStyle,
          ),
        );
    }
  }

  Color get _mutedColor =>
      (widget.baseStyle.color ?? Colors.grey).withValues(alpha: 0.6);

  List<InlineSpan> _inlineSpans(List<RichHtmlSpan> spans, TextStyle base) {
    return spans.map((span) {
      var style = base.copyWith(
        fontWeight: span.bold ? FontWeight.bold : base.fontWeight,
        fontStyle: span.italic ? FontStyle.italic : base.fontStyle,
        decoration: TextDecoration.combine([
          if (span.underline || span.href != null) TextDecoration.underline,
          if (span.strike) TextDecoration.lineThrough,
        ]),
      );
      if (span.code) {
        style = style.copyWith(fontFamily: 'monospace');
      }
      if (span.href != null) {
        style = style.copyWith(
          color: widget.linkColor ?? Colors.blue.shade600,
        );
        return TextSpan(
          text: span.text,
          style: style,
          recognizer: _linkRecognizer(span.href!),
        );
      }
      return TextSpan(text: span.text, style: style);
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Parsing. Kept free of widgets so it can be unit-tested on its own.
// ---------------------------------------------------------------------------

enum RichHtmlBlockKind {
  paragraph,
  heading,
  listItem,
  quote,
  code,
  divider,
  image,
}

class RichHtmlSpan {
  const RichHtmlSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.href,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? href;
}

class RichHtmlBlock {
  RichHtmlBlock({
    required this.kind,
    this.spans = const [],
    this.headingLevel = 0,
    this.marker = '',
    this.depth = 0,
    this.align = TextAlign.start,
    this.imageUrl,
  });

  final RichHtmlBlockKind kind;
  final List<RichHtmlSpan> spans;
  final int headingLevel;
  final String marker;
  final int depth;
  final TextAlign align;
  final String? imageUrl;

  /// The visible text, with no tags. Handy in tests and for accessibility.
  String get text => spans.map((s) => s.text).join();
}

final _tagPattern = RegExp(r'<\s*(/?)\s*([a-zA-Z][a-zA-Z0-9]*)([^>]*)>');
final _attrPattern = RegExp(
  '([a-zA-Z-]+)\\s*=\\s*("([^"]*)"|\'([^\']*)\')',
);
final _whitespacePattern = RegExp(r'\s+');

/// Turns the dashboard's HTML into a list of blocks ready to render.
///
/// A string with no tags at all comes back as a single paragraph, so plain
/// text typed before the rich editor existed still shows correctly.
List<RichHtmlBlock> parseRichHtml(String html) {
  final source = html.trim();
  if (source.isEmpty) return const [];

  if (!source.contains('<')) {
    return [
      RichHtmlBlock(
        kind: RichHtmlBlockKind.paragraph,
        spans: [RichHtmlSpan(decodeHtmlEntities(source))],
      ),
    ];
  }

  final parser = _Parser(source);
  return parser.run();
}

class _ListContext {
  _ListContext(this.ordered);
  final bool ordered;
  int index = 0;
}

class _InlineState {
  _InlineState({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.href,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? href;

  _InlineState with_({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? code,
    String? href,
  }) {
    return _InlineState(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      href: href ?? this.href,
    );
  }
}

const _blockTags = {
  'p',
  'div',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'blockquote',
  'pre',
};

class _Parser {
  _Parser(this.source);

  final String source;

  final List<RichHtmlBlock> _blocks = [];
  final List<RichHtmlSpan> _buffer = [];
  final List<_ListContext> _lists = [];
  final List<_InlineState> _inline = [_InlineState()];

  RichHtmlBlockKind _kind = RichHtmlBlockKind.paragraph;
  int _headingLevel = 0;
  TextAlign _align = TextAlign.start;

  List<RichHtmlBlock> run() {
    var cursor = 0;
    for (final match in _tagPattern.allMatches(source)) {
      if (match.start > cursor) {
        _addText(source.substring(cursor, match.start));
      }
      cursor = match.end;

      final isClosing = match.group(1) == '/';
      final name = match.group(2)!.toLowerCase();
      final attrs = _parseAttributes(match.group(3) ?? '');

      if (isClosing) {
        _closeTag(name);
      } else {
        _openTag(name, attrs);
      }
    }
    if (cursor < source.length) {
      _addText(source.substring(cursor));
    }

    _flush();
    return _blocks;
  }

  void _openTag(String name, Map<String, String> attrs) {
    switch (name) {
      case 'br':
        _buffer.add(_span('\n'));
        return;

      case 'hr':
        _flush();
        _blocks.add(RichHtmlBlock(kind: RichHtmlBlockKind.divider));
        return;

      case 'img':
        _flush();
        _blocks.add(RichHtmlBlock(
          kind: RichHtmlBlockKind.image,
          imageUrl: attrs['src'],
        ));
        return;

      case 'ul':
      case 'ol':
        _flush();
        _lists.add(_ListContext(name == 'ol'));
        return;

      case 'b':
      case 'strong':
        _inline.add(_inline.last.with_(bold: true));
        return;
      case 'i':
      case 'em':
        _inline.add(_inline.last.with_(italic: true));
        return;
      case 'u':
        _inline.add(_inline.last.with_(underline: true));
        return;
      case 's':
      case 'del':
      case 'strike':
        _inline.add(_inline.last.with_(strike: true));
        return;
      case 'code':
        _inline.add(_inline.last.with_(code: true));
        return;
      case 'a':
        _inline.add(_inline.last.with_(href: attrs['href']));
        return;
    }

    if (_blockTags.contains(name)) {
      _flush();
      _align = _alignFrom(attrs['style']);
      switch (name) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          _kind = RichHtmlBlockKind.heading;
          _headingLevel = int.parse(name.substring(1));
        case 'li':
          _kind = RichHtmlBlockKind.listItem;
          if (_lists.isNotEmpty) _lists.last.index++;
        case 'blockquote':
          _kind = RichHtmlBlockKind.quote;
        case 'pre':
          _kind = RichHtmlBlockKind.code;
        default:
          _kind = RichHtmlBlockKind.paragraph;
      }
    }
    // Anything else (span, table cells, unknown tags) keeps the current block
    // and contributes only its text.
  }

  void _closeTag(String name) {
    switch (name) {
      case 'b':
      case 'strong':
      case 'i':
      case 'em':
      case 'u':
      case 's':
      case 'del':
      case 'strike':
      case 'code':
      case 'a':
        if (_inline.length > 1) _inline.removeLast();
        return;

      case 'ul':
      case 'ol':
        _flush();
        if (_lists.isNotEmpty) _lists.removeLast();
        return;
    }

    if (_blockTags.contains(name)) {
      _flush();
    }
  }

  void _addText(String raw) {
    if (raw.isEmpty) return;
    // Collapse the newlines and indentation the editor writes between tags;
    // inside <pre> they are the author's own formatting, so keep them.
    final text = _kind == RichHtmlBlockKind.code
        ? decodeHtmlEntities(raw)
        : decodeHtmlEntities(raw).replaceAll(_whitespacePattern, ' ');
    if (text.isEmpty) return;
    if (text.trim().isEmpty && _buffer.isEmpty) return;
    _buffer.add(_span(text));
  }

  RichHtmlSpan _span(String text) {
    final state = _inline.last;
    return RichHtmlSpan(
      text,
      bold: state.bold,
      italic: state.italic,
      underline: state.underline,
      strike: state.strike,
      code: state.code,
      href: state.href,
    );
  }

  void _flush() {
    if (_buffer.isNotEmpty) {
      final spans = _trimEdges(_buffer);
      if (spans.isNotEmpty) {
        final ordered = _lists.isNotEmpty && _lists.last.ordered;
        _blocks.add(RichHtmlBlock(
          kind: _kind,
          spans: spans,
          headingLevel: _headingLevel,
          align: _align,
          depth: _kind == RichHtmlBlockKind.listItem
              ? (_lists.length - 1).clamp(0, 6)
              : 0,
          marker: _kind == RichHtmlBlockKind.listItem
              ? (ordered ? '${_lists.last.index}.' : '\u2022')
              : '',
        ));
      }
      _buffer.clear();
    }
    _kind = RichHtmlBlockKind.paragraph;
    _headingLevel = 0;
    _align = TextAlign.start;
  }

  /// Drops the leading and trailing spaces a block picks up from indentation
  /// between tags, without touching the spaces between words.
  List<RichHtmlSpan> _trimEdges(List<RichHtmlSpan> spans) {
    final result = List<RichHtmlSpan>.from(spans);
    while (result.isNotEmpty && result.first.text.trim().isEmpty) {
      result.removeAt(0);
    }
    while (result.isNotEmpty && result.last.text.trim().isEmpty) {
      result.removeLast();
    }
    if (result.isEmpty) return result;

    result[0] = _copyWithText(result.first, result.first.text.trimLeft());
    result[result.length - 1] =
        _copyWithText(result.last, result.last.text.trimRight());
    return result;
  }

  RichHtmlSpan _copyWithText(RichHtmlSpan span, String text) {
    return RichHtmlSpan(
      text,
      bold: span.bold,
      italic: span.italic,
      underline: span.underline,
      strike: span.strike,
      code: span.code,
      href: span.href,
    );
  }

  TextAlign _alignFrom(String? style) {
    if (style == null) return TextAlign.start;
    final value = style.toLowerCase();
    if (!value.contains('text-align')) return TextAlign.start;
    if (value.contains('center')) return TextAlign.center;
    if (value.contains('justify')) return TextAlign.justify;
    // Deliberately TextAlign.end / TextAlign.start rather than right / left,
    // so a right-to-left language mirrors correctly.
    if (value.contains('right')) return TextAlign.end;
    if (value.contains('left')) return TextAlign.start;
    return TextAlign.start;
  }

  Map<String, String> _parseAttributes(String raw) {
    final attrs = <String, String>{};
    for (final match in _attrPattern.allMatches(raw)) {
      final name = match.group(1)!.toLowerCase();
      attrs[name] = decodeHtmlEntities(match.group(3) ?? match.group(4) ?? '');
    }
    return attrs;
  }
}

const _namedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': '\u00a0',
  'hellip': '\u2026',
  'mdash': '\u2014',
  'ndash': '\u2013',
  'rsquo': '\u2019',
  'lsquo': '\u2018',
  'rdquo': '\u201d',
  'ldquo': '\u201c',
  'times': '\u00d7',
  'euro': '\u20ac',
  'pound': '\u00a3',
  'copy': '\u00a9',
  'reg': '\u00ae',
  'trade': '\u2122',
  'deg': '\u00b0',
};

final _entityPattern = RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');

/// Turns `&amp;`, `&#39;` and friends back into the characters they stand for,
/// so a price like "Tea &amp; Coffee" does not read as "Tea &amp;amp; Coffee".
String decodeHtmlEntities(String input) {
  if (!input.contains('&')) return input;
  return input.replaceAllMapped(_entityPattern, (match) {
    final body = match.group(1)!;
    if (body.startsWith('#')) {
      final isHex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
      final digits = isHex ? body.substring(2) : body.substring(1);
      final code = int.tryParse(digits, radix: isHex ? 16 : 10);
      if (code == null || code <= 0 || code > 0x10FFFF) return match.group(0)!;
      return String.fromCharCode(code);
    }
    return _namedEntities[body.toLowerCase()] ?? match.group(0)!;
  });
}
