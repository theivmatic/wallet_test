import 'package:dio/dio.dart';

import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required ApiClient api,
    required ITransferRepository repository,
  })  : _api = api,
        _repository = repository;

  final ApiClient _api;
  final ITransferRepository _repository;

  static const _maxAttempts = 3;
  static const _retryDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 500),
  ];

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      if (cancelToken?.isCancelled ?? false) {
        throw const CancelException();
      }

      try {
        final response = await _api.dio.get(
          '/v1/transfers/${transfer.txHash}/status',
          options: Options(
            headers: {
              'Idempotency-Key':
                  '${transfer.network.toLowerCase()}:${transfer.txHash}',
            },
          ),
          cancelToken: cancelToken,
        );

        final status = TransferStatus.fromName(
          response.data['status'] as String? ?? 'unknown',
        );

        try {
          await _repository.applyStatus(
            transfer,
            status,
            DateTime.now(),
          );
        } catch (_) {
          throw const TransferSyncException(code: 'localPersistenceFailed');
        }

        return status;
      } on DioException catch (error) {
        if (error.type == DioExceptionType.cancel) {
          throw const CancelException();
        }

        final canRetry = _shouldRetry(error) && attempt < _maxAttempts - 1;

        if (!canRetry) {
          throw _mapException(error);
        }

        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }

    throw const TransferSyncException(code: 'network');
  }

  bool _shouldRetry(DioException error) {
    if (_isRetryableType(error.type)) {
      return true;
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      return statusCode == 408 || statusCode == 429 || statusCode == 503;
    }

    return false;
  }

  bool _isRetryableType(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.connectionError ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout;
  }

  TransferSyncException _mapException(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      return _mapHttpStatus(error.response?.statusCode);
    }

    return const TransferSyncException(code: 'network');
  }

  TransferSyncException _mapHttpStatus(int? statusCode) {
    switch (statusCode) {
      case 401:
        return const TransferSyncException(code: 'unauthorized');
      case 404:
        return const TransferSyncException(code: 'notFound');
      case 409:
        return const TransferSyncException(code: 'conflict');
      case 408:
      case 429:
        return const TransferSyncException(code: 'rateLimited');
      case 503:
        return const TransferSyncException(code: 'serverUnavailable');
      case 500:
        return const TransferSyncException(code: 'internal');
      default:
        return const TransferSyncException(code: 'network');
    }
  }
}
