import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';
import '../../fakes/fake_http_client_adapter.dart';

void main() {
  const transfer = Transfer(
    id: 'tx_1',
    network: 'Ethereum',
    txHash: '0x1234abcd',
  );

  TransferStatusSyncService buildService({
    required FakeHttpClientAdapter adapter,
    InMemoryTransferRepository? repository,
  }) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;

    return TransferStatusSyncService(
      api: ApiClient(dio: dio),
      repository: repository ?? InMemoryTransferRepository(),
    );
  }

  group('TransferStatusSyncService', () {
    test('429 then 200: 2 HTTP calls, DB updated once, confirmed', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(200, body: {'status': 'confirmed'}),
      ]);
      final repository = InMemoryTransferRepository();
      final service = buildService(
        adapter: adapter,
        repository: repository,
      );

      final status = await service.sync(transfer);

      expect(adapter.calls.length, 2);
      expect(repository.applyCalls, 1);
      expect(status, TransferStatus.confirmed);
    });

    test('401: 1 HTTP call, no retry, DB not updated, unauthorized', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(401),
      ]);
      final repository = InMemoryTransferRepository();
      final service = buildService(
        adapter: adapter,
        repository: repository,
      );

      await expectLater(
        service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (error) => error.code,
            'code',
            'unauthorized',
          ),
        ),
      );

      expect(adapter.calls.length, 1);
      expect(repository.applyCalls, 0);
    });

    test('500: 1 HTTP call, no retry, internal', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(500),
      ]);
      final repository = InMemoryTransferRepository();
      final service = buildService(
        adapter: adapter,
        repository: repository,
      );

      await expectLater(
        service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (error) => error.code,
            'code',
            'internal',
          ),
        ),
      );

      expect(adapter.calls.length, 1);
      expect(repository.applyCalls, 0);
    });

    test('429 x3: 3 HTTP calls, rateLimited', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(429),
        HttpOutcome(429),
      ]);
      final repository = InMemoryTransferRepository();
      final service = buildService(
        adapter: adapter,
        repository: repository,
      );

      await expectLater(
        service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (error) => error.code,
            'code',
            'rateLimited',
          ),
        ),
      );

      expect(adapter.calls.length, 3);
      expect(repository.applyCalls, 0);
    });

    test('200 but DB fails: localPersistenceFailed, no success', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200, body: {'status': 'confirmed'}),
      ]);
      final repository = InMemoryTransferRepository()..shouldFail = true;
      final service = buildService(
        adapter: adapter,
        repository: repository,
      );

      await expectLater(
        service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (error) => error.code,
            'code',
            'localPersistenceFailed',
          ),
        ),
      );

      expect(repository.applyCalls, 1);
    });

    test('Idempotency-Key header is present with lowercase network', () async {
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200, body: {'status': 'confirmed'}),
      ]);
      final service = buildService(adapter: adapter);

      await service.sync(transfer);

      expect(adapter.calls.single.headers['Idempotency-Key'],
          'ethereum:0x1234abcd');
    });
  });
}
