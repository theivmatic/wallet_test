import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';
import '../../helpers/test_get_it.dart';

void main() {
  group('CardIssuePage', () {
    Future<void> tearDownWidget(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('renders page', (tester) async {
      await testWithGetIt(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CardIssuePage(cardId: 'card_1'),
          ),
        );

        expect(find.text('Issue card'), findsOneWidget);

        await tearDownWidget(tester);
      });
    });

    testWidgets('BLoC is taken from GetIt', (tester) async {
      await testWithGetIt(() async {
        final blocFromGetIt = GetIt.instance<CardIssueBloc>();

        await tester.pumpWidget(
          const MaterialApp(
            home: CardIssuePage(cardId: 'card_1'),
          ),
        );

        expect(blocFromGetIt.isClosed, isFalse);

        await tearDownWidget(tester);
      });
    });

    testWidgets('ICardIssuer is taken from GetIt', (tester) async {
      await testWithGetIt(() async {
        final issuerFromGetIt = GetIt.instance<ICardIssuer>();

        await tester.pumpWidget(
          const MaterialApp(
            home: CardIssuePage(cardId: 'card_1'),
          ),
        );

        expect(issuerFromGetIt, isA<DevCardIssuer>());

        await tearDownWidget(tester);
      });
    });

    testWidgets('dispose closes BLoC and calls cancelPending once',
        (tester) async {
      await testWithGetIt(() async {
        final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;
        final bloc = CardIssueBloc(issuer: issuer);

        GetIt.instance.unregister<CardIssueBloc>();
        GetIt.instance.registerSingleton<CardIssueBloc>(bloc);

        await tester.pumpWidget(
          const MaterialApp(
            home: CardIssuePage(cardId: 'card_1'),
          ),
        );

        await tearDownWidget(tester);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        expect(issuer.cancelCalls, 1);
        expect(bloc.isClosed, isTrue);
      });
    });
  });
}
