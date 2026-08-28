import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';
import '../../helpers/test_get_it.dart';

void main() {
  group('AddressTile', () {
    const address =
        '0x1234567890abcdef1234567890abcdef12345678';
    const network = 'Ethereum';

    Future<void> pumpAddressTile(
      WidgetTester tester, {
      double textScaleFactor = 1.0,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: const Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        ),
      );
    }

    Future<void> tearDownWidget(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('renders widget', (tester) async {
      await testWithGetIt(() async {
        await pumpAddressTile(tester);
        await tester.pump();

        expect(find.text(network), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsOneWidget);

        await tearDownWidget(tester);
      });
    });

    testWidgets('has no overflow at textScaleFactor 2.0', (tester) async {
      await testWithGetIt(() async {
        await pumpAddressTile(tester, textScaleFactor: 2.0);
        await tester.pump();

        expect(tester.takeException(), isNull);

        await tearDownWidget(tester);
      });
    });

    testWidgets('copy button calls IAddressRepository.copyAddress',
        (tester) async {
      await testWithGetIt(() async {
        final repository =
            GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;

        await pumpAddressTile(tester);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(repository.copyCalls, 1);
        expect(repository.lastAddress, address);

        await tearDownWidget(tester);
      });
    });

    testWidgets('shows copied state on success', (tester) async {
      await testWithGetIt(() async {
        await pumpAddressTile(tester);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byIcon(Icons.check), findsOneWidget);

        await tearDownWidget(tester);
      });
    });

    testWidgets('shows error state on failure', (tester) async {
      await testWithGetIt(() async {
        final repository =
            GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;
        repository.shouldFail = true;

        await pumpAddressTile(tester);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        await tearDownWidget(tester);
      });
    });

    testWidgets('resets state after 1500ms', (tester) async {
      await testWithGetIt(() async {
        await pumpAddressTile(tester);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1500));

        expect(find.byIcon(Icons.copy), findsOneWidget);

        await tearDownWidget(tester);
      });
    });

    testWidgets('closes BLoC after dispose', (tester) async {
      await testWithGetIt(() async {
        final repository = GetIt.instance<IAddressRepository>();
        final bloc = AddressTileBloc(repository: repository);

        GetIt.instance.unregister<AddressTileBloc>();
        GetIt.instance.registerSingleton<AddressTileBloc>(bloc);

        await pumpAddressTile(tester);
        await tester.pump();

        await tearDownWidget(tester);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        expect(bloc.isClosed, isTrue);
      });
    });
  });
}
