import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_form_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_button.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRegister;

  const LoginScreen({super.key, this.onNavigateToRegister});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final initialForm = ref.read(loginViewModelProvider);
    _emailController = TextEditingController(text: initialForm.email);
    _passwordController = TextEditingController(text: initialForm.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(loginViewModelProvider.notifier).submit();
  }

  void _goToRegister() {
    if (widget.onNavigateToRegister != null) {
      widget.onNavigateToRegister!();
      return;
    }
    try {
      context.push('/register');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginFormState>(loginViewModelProvider, (previous, next) {
      if (next.status == FormStatus.failure && next.errorMessage != null) {
        AppFeedback.showSnackBar(
          context,
          message: next.errorMessage!,
          tone: AppFeedbackTone.error,
        );
      }
    });

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppFeedback.showSnackBar(
          context,
          message: next.errorMessage!,
          tone: AppFeedbackTone.error,
        );
      }
    });

    final formState = ref.watch(loginViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);

    final isSubmitting = formState.status == FormStatus.submitting;
    final activeErrorMessage =
        (formState.status == FormStatus.failure
            ? formState.errorMessage
            : null) ??
        authState.errorMessage;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageInsetWide,
              vertical: AppSpacing.space6,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.formMaxWidth,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    AppIcons.resolve(context, AppIcon.workout, selected: true),
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    context.l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    context.l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  AuthTextField(
                    fieldKey: const Key('login_email_field'),
                    controller: _emailController,
                    label: context.l10n.emailLabel,
                    hint: context.l10n.emailHint,
                    errorText: formState.emailError,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.updateEmail,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AuthTextField(
                    fieldKey: const Key('login_password_field'),
                    controller: _passwordController,
                    label: context.l10n.passwordLabel,
                    hint: context.l10n.passwordHint,
                    errorText: formState.passwordError,
                    obscureText: _obscurePassword,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.done,
                    onChanged: notifier.updatePassword,
                    onSubmitted: (_) => _submit(),
                    onToggleObscureText: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    toggleObscureTooltip: _obscurePassword
                        ? context.l10n.showPasswordTooltip
                        : context.l10n.hidePasswordTooltip,
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  if (activeErrorMessage != null) ...[
                    AppFeedbackBanner(
                      bannerKey: const Key('login_error_banner'),
                      message: activeErrorMessage,
                      tone: AppFeedbackTone.error,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                  ],
                  AuthButton(
                    key: const Key('login_submit_button'),
                    text: context.l10n.loginButton,
                    isLoading: isSubmitting,
                    isEnabled: !isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppButton(
                    key: const Key('login_to_register_button'),
                    label: context.l10n.dontHaveAccountButton,
                    variant: AppButtonVariant.text,
                    isEnabled: !isSubmitting,
                    onPressed: _goToRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
