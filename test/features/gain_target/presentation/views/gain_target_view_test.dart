import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_gain_target_repository.dart';
import '../../../../test_helpers/mocks.dart';
import '../../../../test_helpers/pump_app.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeGainTargetRepository fakeGainTargetRepository;
  late MockGainTargetRepository mockGainTargetRepository;
  const testUser = UserEntity(id: 'u1', email: 'user@example.com');

  setUpAll(() {
    registerFallbackValue(
      const GainTargetEntity(minWeeklyGainKg: 0.1, maxWeeklyGainKg: 0.2),
    );
  });

  setUp(() {
    fakeAuthRepository = FakeAuthRepository(initialUser: testUser);
    fakeGainTargetRepository = FakeGainTargetRepository();
    mockGainTargetRepository = MockGainTargetRepository();
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    fakeGainTargetRepository.reset();
  });

  Widget buildTestSubject({List<dynamic>? extraOverrides}) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(16.0), child: GainTargetView()),
      ),
    );
  }

  testWidgets(
    'renders "No target set", blank fields, example hints (0.15, 0.25)',
    (tester) async {
      await tester.pumpApp(
        buildTestSubject(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          gainTargetRepositoryProvider.overrideWithValue(
            fakeGainTargetRepository,
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly Gain Target'), findsOneWidget);
      expect(find.byKey(const Key('gain_target_summary')), findsOneWidget);
      expect(find.text('No target set'), findsOneWidget);

      final minFieldFinder = find.byKey(const Key('gain_target_min_field'));
      final maxFieldFinder = find.byKey(const Key('gain_target_max_field'));
      expect(minFieldFinder, findsOneWidget);
      expect(maxFieldFinder, findsOneWidget);

      final minField = tester.widget<AppTextField>(
        find.byType(AppTextField).at(0),
      );
      final maxField = tester.widget<AppTextField>(
        find.byType(AppTextField).at(1),
      );
      expect(minField.fieldKey, const Key('gain_target_min_field'));
      expect(minField.label, 'Minimum weekly gain');
      expect(minField.controller?.text, isEmpty);
      expect(minField.hint, equals('0.15'));
      expect(minField.suffixText, equals('kg/week'));
      expect(
        minField.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
      expect(minField.enabled, isTrue);
      expect(maxField.fieldKey, const Key('gain_target_max_field'));
      expect(maxField.label, 'Maximum weekly gain');
      expect(maxField.controller?.text, isEmpty);
      expect(maxField.hint, equals('0.25'));
      expect(maxField.suffixText, equals('kg/week'));
      expect(maxField.enabled, isTrue);

      expect(find.byKey(const Key('gain_target_save_button')), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(find.byKey(const Key('gain_target_save_button')))
            .isEnabled,
        isTrue,
      );
      expect(
        find.byKey(const Key('gain_target_refresh_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'entering valid values and tapping save updates summary and shows SnackBar',
    (tester) async {
      await tester.pumpApp(
        buildTestSubject(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          gainTargetRepositoryProvider.overrideWithValue(
            fakeGainTargetRepository,
          ),
        ],
      );
      await tester.pumpAndSettle();

      // Enter valid numbers
      await tester.enterText(
        find.byKey(const Key('gain_target_min_field')),
        '0.15',
      );
      await tester.enterText(
        find.byKey(const Key('gain_target_max_field')),
        '0.25',
      );
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.byKey(const Key('gain_target_save_button')));
      await tester.pumpAndSettle();

      // Expect confirmed summary
      expect(find.text('0.15–0.25 kg/week'), findsOneWidget);
      // User-facing feedback message remains stable across platform adapters.
      expect(
        find.text('Weekly gain target saved successfully'),
        findsOneWidget,
      );

      // Verify repository updated
      expect(
        fakeGainTargetRepository.getTargetForUser(testUser.id),
        equals(
          const GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
        ),
      );
    },
  );

  testWidgets('formats both saved gain bounds in Polish with two decimals', (
    tester,
  ) async {
    fakeGainTargetRepository.seedTarget(
      testUser.id,
      const GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.2),
    );
    await tester.pumpApp(
      buildTestSubject(),
      locale: const Locale('pl'),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        gainTargetRepositoryProvider.overrideWithValue(
          fakeGainTargetRepository,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('0,15–0,20 kg/tydz.'), findsOneWidget);
  });

  testWidgets('entering invalid values shows validation errors', (
    tester,
  ) async {
    await tester.pumpApp(
      buildTestSubject(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        gainTargetRepositoryProvider.overrideWithValue(
          fakeGainTargetRepository,
        ),
      ],
    );
    await tester.pumpAndSettle();

    // Min greater than max
    await tester.enterText(
      find.byKey(const Key('gain_target_min_field')),
      '0.30',
    );
    await tester.enterText(
      find.byKey(const Key('gain_target_max_field')),
      '0.20',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gain_target_save_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Maximum gain rate must be greater than minimum gain rate'),
      findsOneWidget,
    );
    // Nothing saved to repo
    expect(fakeGainTargetRepository.getTargetForUser(testUser.id), isNull);
  });

  testWidgets('shows pending indicator when isSubmitting is true', (
    tester,
  ) async {
    final saveCompleter = Completer<Result<GainTargetEntity, AppFailure>>();
    when(
      () =>
          mockGainTargetRepository.getGainTarget(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const Result.success(null));

    when(
      () => mockGainTargetRepository.saveGainTarget(
        userId: any(named: 'userId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer((_) => saveCompleter.future);

    await tester.pumpApp(
      buildTestSubject(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        gainTargetRepositoryProvider.overrideWithValue(
          mockGainTargetRepository,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('gain_target_min_field')),
      '0.15',
    );
    await tester.enterText(
      find.byKey(const Key('gain_target_max_field')),
      '0.25',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gain_target_save_button')));
    await tester.pump();

    // Pending indicator appears
    expect(
      find.byKey(const Key('gain_target_pending_indicator')),
      findsOneWidget,
    );
    expect(find.text('Waiting for server confirmation'), findsOneWidget);

    // Save button disabled
    final saveBtn = tester.widget<AppButton>(
      find.byKey(const Key('gain_target_save_button')),
    );
    expect(saveBtn.isEnabled, isFalse);
    expect(
      tester.widget<AppTextField>(find.byType(AppTextField).at(0)).enabled,
      isFalse,
    );
    expect(
      tester.widget<AppTextField>(find.byType(AppTextField).at(1)).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('gain_target_refresh_button')),
          )
          .onPressed,
      isNull,
    );

    // Complete save
    saveCompleter.complete(
      const Result.success(
        GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('gain_target_pending_indicator')),
      findsNothing,
    );
    expect(find.text('0.15–0.25 kg/week'), findsOneWidget);
  });

  testWidgets('retry button on load failure', (tester) async {
    fakeGainTargetRepository.getFailure = const ServerFailure(
      'Database connection failed',
    );

    await tester.pumpApp(
      buildTestSubject(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        gainTargetRepositoryProvider.overrideWithValue(
          fakeGainTargetRepository,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Database connection failed'), findsOneWidget);
    expect(find.byKey(const Key('gain_target_retry_button')), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('gain_target_retry_button')))
          .label,
      'Retry',
    );
    expect(find.byKey(const Key('gain_target_summary')), findsNothing);

    // Resolve failure and tap retry
    fakeGainTargetRepository.getFailure = null;
    fakeGainTargetRepository.seedTarget(
      testUser.id,
      const GainTargetEntity(minWeeklyGainKg: 0.20, maxWeeklyGainKg: 0.30),
    );

    await tester.tap(find.byKey(const Key('gain_target_retry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Database connection failed'), findsNothing);
    expect(find.text('0.20–0.30 kg/week'), findsOneWidget);
  });

  testWidgets('refresh button calls loadTarget and updates UI', (tester) async {
    fakeGainTargetRepository.seedTarget(
      testUser.id,
      const GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
    );

    await tester.pumpApp(
      buildTestSubject(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        gainTargetRepositoryProvider.overrideWithValue(
          fakeGainTargetRepository,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('0.15–0.25 kg/week'), findsOneWidget);

    // Server target updated
    fakeGainTargetRepository.seedTarget(
      testUser.id,
      const GainTargetEntity(minWeeklyGainKg: 0.30, maxWeeklyGainKg: 0.45),
    );

    // Tap refresh
    await tester.tap(find.byKey(const Key('gain_target_refresh_button')));
    await tester.pumpAndSettle();

    expect(find.text('0.30–0.45 kg/week'), findsOneWidget);
  });
}
