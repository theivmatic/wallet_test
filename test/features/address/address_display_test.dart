import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/address/address_display.dart';

void main() {
  group('formatAddressForCell', () {
    test('short address is unchanged', () {
      expect(
        formatAddressForCell('0x1234', 1.0),
        '0x1234',
      );
    });

    test('long address with 0x is shortened as 6 + 4', () {
      expect(
        formatAddressForCell(
          '0x1234567890abcdef1234567890abcdef12345678',
          1.0,
        ),
        '0x123456…5678',
      );
    });

    test('textScaleFactor >= 1.6 shortens as 4 + 4', () {
      expect(
        formatAddressForCell(
          '0x1234567890abcdef1234567890abcdef12345678',
          2.0,
        ),
        '0x1234…5678',
      );
    });

    test('address without 0x is also shortened', () {
      expect(
        formatAddressForCell(
          '1234567890abcdef1234567890abcdef12345678',
          1.0,
        ),
        '123456…5678',
      );
    });

    test('0x prefix is preserved', () {
      final result = formatAddressForCell(
        '0x1234567890abcdef1234567890abcdef12345678',
        1.0,
      );

      expect(result.startsWith('0x'), isTrue);
    });
  });
}
