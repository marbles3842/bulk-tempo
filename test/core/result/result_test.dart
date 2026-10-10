import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.success', () {
    test('isSuccess is true and isFailure is false', () {
      const result = Result<String, AppFailure>.success('hello');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('dataOrNull returns payload and failureOrNull returns null', () {
      const result = Result<int, AppFailure>.success(42);

      expect(result.dataOrNull, equals(42));
      expect(result.failureOrNull, isNull);
    });

    test('when invokes success callback and returns its result', () {
      const result = Result<String, AppFailure>.success('data');

      final value = result.when(
        success: (data) => 'success: $data',
        failure: (failure) => 'failure: ${failure.message}',
      );

      expect(value, equals('success: data'));
    });

    test('equality and hashCode work as expected', () {
      const result1 = Result<String, AppFailure>.success('value');
      const result2 = Result<String, AppFailure>.success('value');
      const result3 = Result<String, AppFailure>.success('different');

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1, isNot(equals(result3)));
    });

    test('toString contains success and data', () {
      const result = Result<String, AppFailure>.success('info');

      expect(result.toString(), contains('Result.success(info)'));
    });
  });

  group('Result.failure', () {
    test('isSuccess is false and isFailure is true', () {
      const failure = NetworkFailure('No internet');
      const result = Result<String, AppFailure>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    test(
      'dataOrNull returns null and failureOrNull returns failure payload',
      () {
        const failure = ServerFailure('Internal server error', statusCode: 500);
        const result = Result<String, AppFailure>.failure(failure);

        expect(result.dataOrNull, isNull);
        expect(result.failureOrNull, equals(failure));
      },
    );

    test('when invokes failure callback and returns its result', () {
      const failure = AuthFailure('Invalid credentials');
      const result = Result<String, AppFailure>.failure(failure);

      final value = result.when(
        success: (data) => 'success: $data',
        failure: (failure) => 'failure: ${failure.message}',
      );

      expect(value, equals('failure: Invalid credentials'));
    });

    test('equality and hashCode work as expected', () {
      const failure1 = NetworkFailure('offline');
      const failure2 = NetworkFailure('offline');
      const failure3 = NetworkFailure('timeout');

      const result1 = Result<int, AppFailure>.failure(failure1);
      const result2 = Result<int, AppFailure>.failure(failure2);
      const result3 = Result<int, AppFailure>.failure(failure3);

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1, isNot(equals(result3)));
    });

    test('toString contains failure and failure details', () {
      const failure = ValidationFailure('Invalid input');
      const result = Result<String, AppFailure>.failure(failure);

      expect(result.toString(), contains('Result.failure'));
      expect(result.toString(), contains('ValidationFailure'));
    });
  });
}
