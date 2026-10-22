import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_form_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_form_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/register_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/splash_screen.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_form_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

// =============================================================================
// Deterministic Catalog ViewModels (no Firebase / network calls)
// =============================================================================

class _CatalogAuthViewModel extends AuthViewModel {
  _CatalogAuthViewModel([
    this._state = const AuthState(
      user: UserEntity(id: 'catalog-user', email: 'athlete@bulktempo.app'),
      isInitializing: false,
    ),
  ]);

  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> signOut() async {}

  @override
  void clearError() {}
}

class _CatalogLoginViewModel extends LoginViewModel {
  _CatalogLoginViewModel(this._state);

  final LoginFormState _state;

  @override
  LoginFormState build() => _state;

  @override
  void updateEmail(String email) {}

  @override
  void updatePassword(String password) {}

  @override
  Future<void> submit() async {}
}

class _CatalogRegisterViewModel extends RegisterViewModel {
  _CatalogRegisterViewModel(this._state);

  final RegisterFormState _state;

  @override
  RegisterFormState build() => _state;

  @override
  void updateEmail(String email) {}

  @override
  void updatePassword(String password) {}

  @override
  Future<void> submit() async {}
}

class _CatalogGainTargetViewModel extends GainTargetViewModel {
  _CatalogGainTargetViewModel([
    this._state = const GainTargetState(
      savedTarget: GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      ),
      minInput: '0.15',
      maxInput: '0.25',
      hasLoadedOnce: true,
    ),
  ]);

  final GainTargetState _state;

  @override
  GainTargetState build() => _state;

  @override
  Future<void> loadTarget({
    bool showLoading = true,
    bool isRefresh = false,
  }) async {}

  @override
  void updateMinInput(String value) {}

  @override
  void updateMaxInput(String value) {}

  @override
  Future<void> saveTarget() async {}

  @override
  void clearMessages() {}

  @override
  void discardDraft() {}
}

class _CatalogWorkoutProgressViewModel extends WorkoutProgressViewModel {
  _CatalogWorkoutProgressViewModel([
    this._state = const WorkoutProgressLoaded(
      maskedApiKey: '••••-••••-••••-3456',
      workouts: <WorkoutEntity>[],
      weeklySummaries: <WeeklyWorkoutSummaryEntity>[],
    ),
  ]);

  final WorkoutProgressState _state;

  @override
  WorkoutProgressState build() => _state;

  @override
  Future<void> ensureInitialized({DateTime? now}) async {}

  @override
  Future<void> loadWorkouts({bool showLoading = true, DateTime? now}) async {}

  @override
  Future<bool> disconnectApiKey() async => true;
}

class _CatalogHevyKeyViewModel extends HevyKeyViewModel {
  @override
  HevyKeyFormState build() => const HevyKeyFormState();

  @override
  void updateKey(String value) {}

  @override
  void reset() {}

  @override
  Future<bool> submitKey() async => false;
}

class _CatalogDashboardViewModel extends DashboardViewModel {
  @override
  DashboardState build() {
    return const DashboardState(
      weightStatus: DashboardCardStatus.loaded,
      workoutStatus: DashboardCardStatus.loaded,
      overview: WeeklyProgressOverviewEntity(
        calendarWeeks: [],
        latestWeekLoggedDays: 0,
        isLatestWeekCurrentWeek: true,
        isLatestWeekIncomplete: false,
        currentWeekWorkoutCount: 0,
        loggedWeightWeeksCount: 0,
      ),
    );
  }

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> refreshAll() async {}

  @override
  Future<void> retryWeights() async {}

  @override
  Future<void> retryWorkouts() async {}

  @override
  Future<void> retryPace() async {}
}

class _CatalogWeightHistoryViewModel extends WeightHistoryViewModel {
  @override
  WeightHistoryState build() => const WeightHistoryInitial();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> loadEntries({bool showLoading = true}) async {}
}

// =============================================================================
// State Matrix Card Helpers
// =============================================================================

Widget _stateExample(String label, Widget child) {
  return SizedBox(
    width: 440,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        child,
      ],
    ),
  );
}

Widget _loginScreenCard({
  required LoginFormState formState,
  AuthState authState = const AuthState(),
}) {
  return ProviderScope(
    overrides: [
      loginViewModelProvider.overrideWith(
        () => _CatalogLoginViewModel(formState),
      ),
      authViewModelProvider.overrideWith(
        () => _CatalogAuthViewModel(authState),
      ),
    ],
    child: const SizedBox(height: 640, child: LoginScreen()),
  );
}

Widget _registerScreenCard({
  required RegisterFormState formState,
  AuthState authState = const AuthState(),
}) {
  return ProviderScope(
    overrides: [
      registerViewModelProvider.overrideWith(
        () => _CatalogRegisterViewModel(formState),
      ),
      authViewModelProvider.overrideWith(
        () => _CatalogAuthViewModel(authState),
      ),
    ],
    child: const SizedBox(height: 680, child: RegisterScreen()),
  );
}

// =============================================================================
// Widgetbook Category Export
// =============================================================================

/// Catalog entry for all Auth feature views and their state matrices.
final authCategory = WidgetbookCategory(
  name: 'Auth',
  children: [
    WidgetbookComponent(
      name: 'LoginScreen',
      useCases: [
        WidgetbookUseCase(
          name: 'Login — State Matrix',
          builder: (context) {
            final locale = Localizations.localeOf(context);
            final isPolish = locale.languageCode == 'pl';

            final defaultState = const LoginFormState();
            final populatedState = const LoginFormState(
              email: 'athlete@bulktempo.app',
              password: 'password123',
            );
            final validationState = LoginFormState(
              email: 'invalid-email',
              password: '123',
              emailError: isPolish
                  ? 'Wprowadź prawidłowy adres e-mail'
                  : 'Please enter a valid email address',
              passwordError: isPolish
                  ? 'Hasło musi mieć co najmniej 6 znaków'
                  : 'Password must be at least 6 characters',
            );
            final submissionFailureState = LoginFormState(
              email: 'nobody@bulktempo.app',
              password: 'password123',
              status: FormStatus.failure,
              errorMessage: isPolish
                  ? 'Nieprawidłowy e-mail lub hasło'
                  : 'Invalid email or password',
            );
            final submittingState = const LoginFormState(
              email: 'athlete@bulktempo.app',
              password: 'password123',
              status: FormStatus.submitting,
            );
            final authStreamError = AuthState(
              isInitializing: false,
              errorMessage: isPolish
                  ? 'Błąd połączenia z usługą uwierzytelniania'
                  : 'Authentication stream error occurred',
            );
            final successMessage = isPolish
                ? 'Logowanie powiodło się pomyślnie'
                : 'Logged in successfully';

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 480
                    ? constraints.maxWidth
                    : 440.0;
                Widget example(String title, Widget child) => SizedBox(
                  width: cardWidth,
                  child: _stateExample(title, child),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Wrap(
                    spacing: AppSpacing.space4,
                    runSpacing: AppSpacing.space4,
                    children: [
                      example(
                        'Default (empty)',
                        _loginScreenCard(formState: defaultState),
                      ),
                      example(
                        'Populated (ready)',
                        _loginScreenCard(formState: populatedState),
                      ),
                      example(
                        'Validation error',
                        _loginScreenCard(formState: validationState),
                      ),
                      example(
                        'Submission failure',
                        _loginScreenCard(formState: submissionFailureState),
                      ),
                      example(
                        'Submitting / busy',
                        _loginScreenCard(formState: submittingState),
                      ),
                      example(
                        'Auth stream error',
                        _loginScreenCard(
                          formState: populatedState,
                          authState: authStreamError,
                        ),
                      ),
                      example(
                        'Success feedback',
                        SizedBox(
                          height: 640,
                          child: Scaffold(
                            body: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppSpacing.space4,
                                ),
                                child: AppFeedbackBanner(
                                  message: successMessage,
                                  tone: AppFeedbackTone.success,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'RegisterScreen',
      useCases: [
        WidgetbookUseCase(
          name: 'Register — State Matrix',
          builder: (context) {
            final locale = Localizations.localeOf(context);
            final isPolish = locale.languageCode == 'pl';

            final defaultState = const RegisterFormState();
            final populatedState = const RegisterFormState(
              email: 'newuser@bulktempo.app',
              password: 'securePassword123',
            );
            final validationState = RegisterFormState(
              email: 'invalid-email',
              password: '123',
              emailError: isPolish
                  ? 'Wprowadź prawidłowy adres e-mail'
                  : 'Please enter a valid email address',
              passwordError: isPolish
                  ? 'Hasło musi mieć co najmniej 6 znaków'
                  : 'Password must be at least 6 characters',
            );
            final submissionFailureState = RegisterFormState(
              email: 'taken@bulktempo.app',
              password: 'securePassword123',
              status: FormStatus.failure,
              errorMessage: isPolish
                  ? 'Rejestracja nie powiodła się: e-mail jest już zajęty'
                  : 'Registration failed: email already in use',
            );
            final submittingState = const RegisterFormState(
              email: 'newuser@bulktempo.app',
              password: 'securePassword123',
              status: FormStatus.submitting,
            );
            final authStreamFailureState = RegisterFormState(
              email: 'newuser@bulktempo.app',
              password: 'securePassword123',
              status: FormStatus.failure,
              errorMessage: isPolish
                  ? 'Usługa rejestracji jest obecnie niedostępna'
                  : 'Registration service unavailable',
            );
            final registerSuccessMessage = isPolish
                ? 'Konto zostało pomyślnie utworzone'
                : 'Account created successfully';

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 480
                    ? constraints.maxWidth
                    : 440.0;
                Widget example(String title, Widget child) => SizedBox(
                  width: cardWidth,
                  child: _stateExample(title, child),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Wrap(
                    spacing: AppSpacing.space4,
                    runSpacing: AppSpacing.space4,
                    children: [
                      example(
                        'Default (empty)',
                        _registerScreenCard(formState: defaultState),
                      ),
                      example(
                        'Populated (ready)',
                        _registerScreenCard(formState: populatedState),
                      ),
                      example(
                        'Validation error',
                        _registerScreenCard(formState: validationState),
                      ),
                      example(
                        'Submission failure',
                        _registerScreenCard(formState: submissionFailureState),
                      ),
                      example(
                        'Submitting / busy',
                        _registerScreenCard(formState: submittingState),
                      ),
                      example(
                        'Auth stream error',
                        _registerScreenCard(formState: authStreamFailureState),
                      ),
                      example(
                        'Success feedback',
                        SizedBox(
                          height: 680,
                          child: Scaffold(
                            body: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppSpacing.space4,
                                ),
                                child: AppFeedbackBanner(
                                  message: registerSuccessMessage,
                                  tone: AppFeedbackTone.success,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'SplashScreen',
      useCases: [
        WidgetbookUseCase(
          name: 'Initial Auth Loading',
          builder: (context) {
            return const SizedBox(height: 600, child: SplashScreen());
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'HomeShellScreen',
      useCases: [
        WidgetbookUseCase(
          name: 'Profile & Navigation Shell',
          builder: (context) {
            final email = context.knobs.string(
              label: 'User Email',
              initialValue: 'athlete@bulktempo.app',
            );
            final hasGainTarget = context.knobs.boolean(
              label: 'Has Saved Gain Target',
              initialValue: true,
            );
            final isHevyConnected = context.knobs.boolean(
              label: 'Hevy Connected',
              initialValue: true,
            );

            final authState = AuthState(
              user: UserEntity(id: 'catalog-user', email: email),
              isInitializing: false,
            );

            final gainTargetState = hasGainTarget
                ? const GainTargetState(
                    savedTarget: GainTargetEntity(
                      minWeeklyGainKg: 0.15,
                      maxWeeklyGainKg: 0.25,
                    ),
                    minInput: '0.15',
                    maxInput: '0.25',
                    hasLoadedOnce: true,
                  )
                : const GainTargetState(hasLoadedOnce: true);

            final workoutState = isHevyConnected
                ? const WorkoutProgressLoaded(
                    maskedApiKey: '••••-••••-••••-3456',
                    workouts: <WorkoutEntity>[],
                    weeklySummaries: <WeeklyWorkoutSummaryEntity>[],
                  )
                : const WorkoutProgressUnconfigured();

            return ProviderScope(
              overrides: [
                authViewModelProvider.overrideWith(
                  () => _CatalogAuthViewModel(authState),
                ),
                gainTargetViewModelProvider.overrideWith(
                  () => _CatalogGainTargetViewModel(gainTargetState),
                ),
                workoutProgressViewModelProvider.overrideWith(
                  () => _CatalogWorkoutProgressViewModel(workoutState),
                ),
                hevyKeyViewModelProvider.overrideWith(
                  _CatalogHevyKeyViewModel.new,
                ),
                dashboardViewModelProvider.overrideWith(
                  _CatalogDashboardViewModel.new,
                ),
                weightHistoryViewModelProvider.overrideWith(
                  _CatalogWeightHistoryViewModel.new,
                ),
              ],
              child: const SizedBox(height: 800, child: HomeShellScreen()),
            );
          },
        ),
      ],
    ),
  ],
);
