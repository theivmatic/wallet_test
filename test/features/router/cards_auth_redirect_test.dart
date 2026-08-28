import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  group('cardsAuthRedirect', () {
    test('unauthed /cards/card_1/issue?step=2 redirects to onboarding', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/cards/card_1/issue?step=2'),
          false,
        ),
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );
    });

    test('authed /onboarding?next=... redirects to deep link', () {
      expect(
        cardsAuthRedirect(
          Uri.parse(
            '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
          ),
          true,
        ),
        '/cards/card_1/issue?step=2',
      );
    });

    test('authed /onboarding?next=evil.com redirects to /cards', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/onboarding?next=https%3A%2F%2Fevil.com'),
          true,
        ),
        '/cards',
      );
    });

    test('unauthed /onboarding returns null', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/onboarding'),
          false,
        ),
        isNull,
      );
    });

    test('authed /cards returns null', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/cards'),
          true,
        ),
        isNull,
      );
    });
  });
}
