import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/repositories/gain_target_repository.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_gain_target_repository.dart';
import '../../../../test_helpers/mocks.dart';

void main() {
  late FakeGainTargetRepository fakeRepository;
  late MockGainTargetRepository mockRepository;
  const testUserId = 'user-123';

  setUpAll(() {
    registerFallbackValue(
      const GainTargetEntity(minWeeklyGainKg: 0.1, maxWeeklyGainKg: 0.2),
    );
  });

  setUp(() {
    fakeRepository = FakeGainTargetRepository();
    mockRepository = MockGainTargetRepository();
  });

  ProviderContainer createContainer({
    GainTargetRepository? repository,
    String? userId = testUserId,
  }) {
    final fakeAuthRepo = FakeAuthRepository(
      initialUser: userId != null
          ? UserEntity(id: userId, email: '$userId@example.com')
          : null,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        gainTargetRepositoryProvider.overrideWithValue(
          repository ?? fakeRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(fakeAuthRepo.dispose);
    return container;
  }

  group('GainTargetViewModel initial load', () {
    test(
      'initial load success with null (No target set, blank fields)',
      () async {
        final container = createContainer();
        final viewModel = container.read(gainTargetViewModelProvider.notifier);

        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.savedTarget, isNull);

        await viewModel.loadTarget();

        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.savedTarget, isNull);
        expect(viewModel.state.hasSavedTarget, isFalse);
        expect(viewModel.state.minInput, isEmpty);
        expect(viewModel.state.maxInput, isEmpty);
        expect(viewModel.state.summaryText, equals('No target set'));
        expect(viewModel.state.isDirty, isFalse);
        expect(viewModel.state.errorMessage, isNull);
      },
    );

    test(
      'initial load success with existing target (prefilled fields)',
      () async {
        const existing = GainTargetEntity(
          minWeeklyGainKg: 0.15,
          maxWeeklyGainKg: 0.25,
        );
        fakeRepository.seedTarget(testUserId, existing);

        final container = createContainer();
        final viewModel = container.read(gainTargetViewModelProvider.notifier);

        await viewModel.loadTarget();

        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.savedTarget, equals(existing));
        expect(viewModel.state.hasSavedTarget, isTrue);
        expect(viewModel.state.minInput, equals('0.15'));
        expect(viewModel.state.maxInput, equals('0.25'));
        expect(viewModel.state.summaryText, equals('0.15–0.25 kg/week'));
        expect(viewModel.state.isDirty, isFalse);
      },
    );

    test('initial load failure sets errorMessage and allows retry', () async {
      fakeRepository.getFailure = const NetworkFailure('Connection timed out');

      final container = createContainer();
      final viewModel = container.read(gainTargetViewModelProvider.notifier);

      await viewModel.loadTarget();

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.savedTarget, isNull);
      expect(viewModel.state.errorMessage, equals('Connection timed out'));

      // Retry after resolving failure
      fakeRepository.getFailure = null;
      const target = GainTargetEntity(
        minWeeklyGainKg: 0.20,
        maxWeeklyGainKg: 0.30,
      );
      fakeRepository.seedTarget(testUserId, target);

      await viewModel.loadTarget(showLoading: true);

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.errorMessage, isNull);
      expect(viewModel.state.savedTarget, equals(target));
      expect(viewModel.state.minInput, equals('0.20'));
      expect(viewModel.state.maxInput, equals('0.30'));
    });
  });

  group('GainTargetViewModel refresh & dirty draft', () {
    test(
      'refresh with dirty draft preserves draft text while updating savedTarget',
      () async {
        const initial = GainTargetEntity(
          minWeeklyGainKg: 0.15,
          maxWeeklyGainKg: 0.25,
        );
        fakeRepository.seedTarget(testUserId, initial);

        final container = createContainer();
        final viewModel = container.read(gainTargetViewModelProvider.notifier);
        await viewModel.loadTarget();

        // User starts editing
        viewModel.updateMinInput('0.18');
        expect(viewModel.state.isDirty, isTrue);
        expect(viewModel.state.minInput, equals('0.18'));

        // Server updates target in background
        const updated = GainTargetEntity(
          minWeeklyGainKg: 0.20,
          maxWeeklyGainKg: 0.35,
        );
        fakeRepository.seedTarget(testUserId, updated);

        // Explicit refresh
        await viewModel.loadTarget(showLoading: false, isRefresh: true);

        expect(viewModel.state.savedTarget, equals(updated));
        expect(viewModel.state.isDirty, isTrue);
        // Edited input is preserved
        expect(viewModel.state.minInput, equals('0.18'));
        expect(viewModel.state.maxInput, equals('0.25'));
      },
    );

    test(
      'refresh failure preserves existing savedTarget and dirty draft',
      () async {
        const initial = GainTargetEntity(
          minWeeklyGainKg: 0.15,
          maxWeeklyGainKg: 0.25,
        );
        fakeRepository.seedTarget(testUserId, initial);

        final container = createContainer();
        final viewModel = container.read(gainTargetViewModelProvider.notifier);
        await viewModel.loadTarget();

        viewModel.updateMinInput('0.22');
        fakeRepository.getFailure = const NetworkFailure('Failed to refresh');

        await viewModel.loadTarget(showLoading: false, isRefresh: true);

        expect(viewModel.state.savedTarget, equals(initial));
        expect(viewModel.state.minInput, equals('0.22'));
        expect(viewModel.state.isDirty, isTrue);
        expect(
          viewModel.state.refreshErrorMessage,
          equals('Failed to refresh'),
        );
        expect(viewModel.state.errorMessage, isNull);
      },
    );
  });

  group('GainTargetViewModel input updates and validation', () {
    test('updateMinInput and updateMaxInput flag dirty and compute errors', () {
      final container = createContainer();
      final viewModel = container.read(gainTargetViewModelProvider.notifier);

      viewModel.updateMinInput('0.30');
      expect(viewModel.state.minInput, equals('0.30'));
      expect(viewModel.state.isDirty, isTrue);
      expect(viewModel.state.minError, isNull);

      // maxInput is smaller than minInput -> rangeError
      viewModel.updateMaxInput('0.20');
      expect(viewModel.state.maxInput, equals('0.20'));
      expect(viewModel.state.isDirty, isTrue);
      expect(
        viewModel.state.rangeError,
        equals('Maximum gain rate must be greater than minimum gain rate'),
      );
      expect(
        viewModel.state.effectiveMaxError,
        equals('Maximum gain rate must be greater than minimum gain rate'),
      );

      // Fix maxInput
      viewModel.updateMaxInput('0.40');
      expect(viewModel.state.rangeError, isNull);
      expect(viewModel.state.effectiveMaxError, isNull);
    });

    test('saveTarget rejects invalid inputs and sets field errors', () async {
      final container = createContainer();
      final viewModel = container.read(gainTargetViewModelProvider.notifier);

      // Empty inputs
      await viewModel.saveTarget();
      expect(
        viewModel.state.minError,
        equals('Please enter a minimum gain rate'),
      );
      expect(
        viewModel.state.maxError,
        equals('Please enter a maximum gain rate'),
      );
      expect(viewModel.state.isSubmitting, isFalse);

      // Negative min
      viewModel.updateMinInput('-0.10');
      viewModel.updateMaxInput('0.20');
      await viewModel.saveTarget();
      expect(
        viewModel.state.minError,
        equals('Minimum gain rate must be greater than 0 kg/week'),
      );
    });
  });

  group('GainTargetViewModel save lifecycle', () {
    test(
      'save success updates savedTarget, clears dirty, shows successMessage',
      () async {
        final container = createContainer();
        final viewModel = container.read(gainTargetViewModelProvider.notifier);

        viewModel.updateMinInput('0.15');
        viewModel.updateMaxInput('0.25');

        await viewModel.saveTarget();

        const expected = GainTargetEntity(
          minWeeklyGainKg: 0.15,
          maxWeeklyGainKg: 0.25,
        );
        expect(viewModel.state.savedTarget, equals(expected));
        expect(viewModel.state.isDirty, isFalse);
        expect(viewModel.state.isSubmitting, isFalse);
        expect(viewModel.state.pendingTarget, isNull);
        expect(
          viewModel.state.successMessage,
          equals('Weekly gain target saved successfully'),
        );
        expect(fakeRepository.getTargetForUser(testUserId), equals(expected));
      },
    );

    test(
      'save failure preserves input for retry and sets saveErrorMessage',
      () async {
        fakeRepository.saveFailure = const ServerFailure(
          'Database write rejected',
        );

        final container = createContainer();
        final viewModel = container.read(gainTargetViewModelProvider.notifier);

        viewModel.updateMinInput('0.20');
        viewModel.updateMaxInput('0.30');

        await viewModel.saveTarget();

        expect(viewModel.state.isSubmitting, isFalse);
        expect(viewModel.state.pendingTarget, isNull);
        expect(viewModel.state.savedTarget, isNull);
        expect(viewModel.state.minInput, equals('0.20'));
        expect(viewModel.state.maxInput, equals('0.30'));
        expect(
          viewModel.state.saveErrorMessage,
          equals('Database write rejected'),
        );
      },
    );

    test('duplicate save while isSubmitting is ignored', () async {
      final completer = Completer<Result<GainTargetEntity, AppFailure>>();
      when(
        () => mockRepository.saveGainTarget(
          userId: any(named: 'userId'),
          target: any(named: 'target'),
        ),
      ).thenAnswer((_) => completer.future);

      final container = createContainer(repository: mockRepository);
      final viewModel = container.read(gainTargetViewModelProvider.notifier);

      viewModel.updateMinInput('0.15');
      viewModel.updateMaxInput('0.25');

      // First submit
      final future1 = viewModel.saveTarget();
      expect(viewModel.state.isSubmitting, isTrue);

      // Duplicate submit
      final future2 = viewModel.saveTarget();
      expect(viewModel.state.isSubmitting, isTrue);

      verify(
        () => mockRepository.saveGainTarget(
          userId: testUserId,
          target: const GainTargetEntity(
            minWeeklyGainKg: 0.15,
            maxWeeklyGainKg: 0.25,
          ),
        ),
      ).called(1);

      completer.complete(
        const Result.success(
          GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
        ),
      );
      await future1;
      await future2;
      expect(viewModel.state.isSubmitting, isFalse);
    });

    test(
      'saveTarget resets isRefreshing and isLoading to false while in flight',
      () async {
        final refreshCompleter =
            Completer<Result<GainTargetEntity?, AppFailure>>();
        final saveCompleter = Completer<Result<GainTargetEntity, AppFailure>>();

        when(
          () => mockRepository.getGainTarget(userId: any(named: 'userId')),
        ).thenAnswer((_) => refreshCompleter.future);
        when(
          () => mockRepository.saveGainTarget(
            userId: any(named: 'userId'),
            target: any(named: 'target'),
          ),
        ).thenAnswer((_) => saveCompleter.future);

        final container = createContainer(repository: mockRepository);
        final viewModel = container.read(gainTargetViewModelProvider.notifier);

        // Start in-flight refresh
        final refreshFuture = viewModel.loadTarget(isRefresh: true);
        expect(viewModel.state.isRefreshing, isTrue);

        viewModel.updateMinInput('0.15');
        viewModel.updateMaxInput('0.25');

        // Start save while refresh is in flight
        final saveFuture = viewModel.saveTarget();
        expect(viewModel.state.isSubmitting, isTrue);
        expect(viewModel.state.isRefreshing, isFalse);
        expect(viewModel.state.isLoading, isFalse);

        // Complete refresh (should be discarded due to generation/isSubmitting)
        refreshCompleter.complete(const Result.success(null));
        await refreshFuture;
        expect(viewModel.state.isRefreshing, isFalse);

        // Complete save
        saveCompleter.complete(
          const Result.success(
            GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
          ),
        );
        await saveFuture;
        expect(viewModel.state.isSubmitting, isFalse);
        expect(viewModel.state.isRefreshing, isFalse);
      },
    );

    test(
      'controlled Completer verifies pending write lifecycle and read suppression',
      () async {
        final saveCompleter = Completer<Result<GainTargetEntity, AppFailure>>();
        when(
          () => mockRepository.saveGainTarget(
            userId: any(named: 'userId'),
            target: any(named: 'target'),
          ),
        ).thenAnswer((_) => saveCompleter.future);

        final container = createContainer(repository: mockRepository);
        final viewModel = container.read(gainTargetViewModelProvider.notifier);

        viewModel.updateMinInput('0.15');
        viewModel.updateMaxInput('0.25');

        final saveFuture = viewModel.saveTarget();
        expect(viewModel.state.isSubmitting, isTrue);
        expect(viewModel.state.pendingTarget, isNotNull);

        // Attempting to loadTarget while write is pending is suppressed
        await viewModel.loadTarget();
        verifyNever(
          () => mockRepository.getGainTarget(userId: any(named: 'userId')),
        );

        // Finish pending save
        saveCompleter.complete(
          const Result.success(
            GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
          ),
        );
        await saveFuture;

        expect(viewModel.state.isSubmitting, isFalse);
        expect(viewModel.state.pendingTarget, isNull);
        expect(viewModel.state.savedTarget, isNotNull);
      },
    );
  });

  group('GainTargetViewModel account switch & discard', () {
    test('account switch resets state and isolates user targets', () async {
      const user1Target = GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      );
      fakeRepository.seedTarget('user-1', user1Target);

      final container = createContainer(userId: 'user-1');
      final viewModel = container.read(gainTargetViewModelProvider.notifier);
      await viewModel.loadTarget();
      expect(viewModel.state.savedTarget, equals(user1Target));

      // Switch to user-2
      viewModel.onUserChanged('user-2');
      expect(viewModel.state.userId, equals('user-2'));
      expect(viewModel.state.savedTarget, isNull);
      expect(viewModel.state.minInput, isEmpty);
      expect(viewModel.state.maxInput, isEmpty);
      expect(viewModel.state.isDirty, isFalse);
    });

    test(
      'in-flight save does not commit if user changes before completion',
      () async {
        final saveCompleter = Completer<Result<GainTargetEntity, AppFailure>>();
        when(
          () => mockRepository.saveGainTarget(
            userId: any(named: 'userId'),
            target: any(named: 'target'),
          ),
        ).thenAnswer((_) => saveCompleter.future);

        final container = createContainer(
          repository: mockRepository,
          userId: 'user-1',
        );
        final viewModel = container.read(gainTargetViewModelProvider.notifier);
        viewModel.updateMinInput('0.15');
        viewModel.updateMaxInput('0.25');

        final saveFuture = viewModel.saveTarget();
        expect(viewModel.state.isSubmitting, isTrue);

        // Switch user while write is in flight
        viewModel.onUserChanged('user-2');

        // Complete original write
        saveCompleter.complete(
          const Result.success(
            GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
          ),
        );
        await saveFuture;

        // User 2 state must NOT have user 1's saved target or success message
        expect(viewModel.state.userId, equals('user-2'));
        expect(viewModel.state.savedTarget, isNull);
        expect(viewModel.state.successMessage, isNull);
        expect(viewModel.state.isSubmitting, isFalse);
      },
    );

    test('discardDraft resets dirty input back to savedTarget', () async {
      const saved = GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      );
      fakeRepository.seedTarget(testUserId, saved);

      final container = createContainer();
      final viewModel = container.read(gainTargetViewModelProvider.notifier);
      await viewModel.loadTarget();

      viewModel.updateMinInput('0.99');
      viewModel.updateMaxInput('1.99');
      expect(viewModel.state.isDirty, isTrue);

      viewModel.discardDraft();
      expect(viewModel.state.isDirty, isFalse);
      expect(viewModel.state.minInput, equals('0.15'));
      expect(viewModel.state.maxInput, equals('0.25'));
    });

    test('discardDraft does not discard if save is pending', () async {
      final completer = Completer<Result<GainTargetEntity, AppFailure>>();
      when(
        () => mockRepository.saveGainTarget(
          userId: any(named: 'userId'),
          target: any(named: 'target'),
        ),
      ).thenAnswer((_) => completer.future);

      final container = createContainer(repository: mockRepository);
      final viewModel = container.read(gainTargetViewModelProvider.notifier);
      viewModel.updateMinInput('0.15');
      viewModel.updateMaxInput('0.25');

      final future = viewModel.saveTarget();
      expect(viewModel.state.isSubmitting, isTrue);

      // Attempt discard while submitting
      viewModel.discardDraft();
      expect(viewModel.state.isSubmitting, isTrue);
      expect(viewModel.state.pendingTarget, isNotNull);

      completer.complete(
        const Result.success(
          GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
        ),
      );
      await future;
    });

    test('clearMessages clears all transient feedback', () {
      final container = createContainer();
      final viewModel = container.read(gainTargetViewModelProvider.notifier);
      viewModel.state = viewModel.state.copyWith(
        successMessage: 'Saved',
        saveErrorMessage: 'Error',
        refreshErrorMessage: 'Refresh error',
      );

      viewModel.clearMessages();
      expect(viewModel.state.successMessage, isNull);
      expect(viewModel.state.saveErrorMessage, isNull);
      expect(viewModel.state.refreshErrorMessage, isNull);
    });
  });
}
