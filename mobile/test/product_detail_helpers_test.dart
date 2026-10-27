import 'package:flutter_test/flutter_test.dart';
import 'package:vortex_app/presentation/screens/products/product_detail_screen.dart';

void main() {
  group('formatMeasure', () {
    test('shows a whole number without a decimal tail', () {
      expect(formatMeasure('250.0'), '250');
      expect(formatMeasure(250), '250');
    });

    test('keeps a real fraction', () {
      expect(formatMeasure('1.5'), '1.5');
    });

    test('treats nothing, blank and zero as "not measured"', () {
      expect(formatMeasure(null), isNull);
      expect(formatMeasure(''), isNull);
      expect(formatMeasure('   '), isNull);
      expect(formatMeasure(0), isNull);
      expect(formatMeasure('0.00'), isNull);
      expect(formatMeasure(-3), isNull);
    });

    test('passes through text the shop typed itself', () {
      expect(formatMeasure('500 g'), '500 g');
    });
  });

  group('formatDimensions', () {
    test('joins the three sides', () {
      expect(
        formatDimensions({'length': 20, 'width': 10, 'height': 5}),
        '20 × 10 × 5',
      );
    });

    test('leaves out the sides that were never measured', () {
      expect(
        formatDimensions({'length': 20, 'width': 0, 'height': null}),
        '20',
      );
    });

    test('nothing to show when no side was measured', () {
      expect(formatDimensions({'length': 0, 'width': 0, 'height': 0}), isNull);
      expect(formatDimensions(null), isNull);
      expect(formatDimensions('20x10'), isNull);
    });
  });

  group('initialsOfName', () {
    test('uses the first letter of the first two words', () {
      expect(initialsOfName('Ahmad Karimi'), 'AK');
      expect(initialsOfName('Sara'), 'S');
    });

    test('copes with extra spaces and empty names', () {
      expect(initialsOfName('  Ahmad   Karimi  '), 'AK');
      expect(initialsOfName(''), '?');
      expect(initialsOfName('   '), '?');
    });
  });

  group('firstImageUrlOf', () {
    test('finds the url whichever key the API used', () {
      expect(firstImageUrlOf([{'path': 'https://x.test/a.png'}]),
          'https://x.test/a.png');
      expect(firstImageUrlOf([{'url': 'https://x.test/b.png'}]),
          'https://x.test/b.png');
      expect(firstImageUrlOf(['https://x.test/c.png']), 'https://x.test/c.png');
    });

    test('skips empty entries and reports none when there is no picture', () {
      expect(
        firstImageUrlOf([{'path': ''}, {'url': 'https://x.test/d.png'}]),
        'https://x.test/d.png',
      );
      expect(firstImageUrlOf([]), isNull);
      expect(firstImageUrlOf([{'path': '  '}]), isNull);
    });
  });
}
