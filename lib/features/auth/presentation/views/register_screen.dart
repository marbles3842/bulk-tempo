import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_form_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_button.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToLogin;

  const RegisterScreen({super.key, this.onNavigateToLogin});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final initialForm = ref.read(registerViewModelProvider);
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
    ref.read(registerViewModelProvider.notifier).submit();
  }

  void _goToLogin() {
    if (widget.onNavigateToLogin != null) {
      widget.onNavigateToLogin!();
      return;
    }
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterFormState>(registerViewModelProvider, (previous, next) {
      if (next.status == FormStatus.failure && next.errorMessage != null) {
        AppFeedback.showSnackBar(
          context,
          message: next.errorMessage!,
          tone: AppFeedbackTone.error,
        );
      }
    });

    final formState = ref.watch(registerViewModelProvider);
    final notifier = ref.read(registerViewModelProvider.notifier);
    final isSubmitting = formState.status == FormStatus.submitting;
    final activeErrorMessage = formState.status == FormStatus.failure
        ? formState.errorMessage
        : null;

    final capabilities = PresentationCapabilities.resolve(context);
    final isMaterial =
        capabilities.platformMode == AdaptivePlatformMode.material;
    final colorScheme = Theme.of(context).colorScheme;

    final PreferredSizeWidget appBar = isMaterial
        ? AppBar(
            leading: IconButton(
              key: const Key('register_back_button'),
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: isSubmitting ? null : _goToLogin,
            ),
          )
        : CupertinoNavigationBar(
            border: null,
            backgroundColor: colorScheme.surface.withValues(alpha: 0),
            leading: Tooltip(
              message: MaterialLocalizations.of(context).backButtonTooltip,
              child: CupertinoButton(
                key: const Key('register_back_button'),
                padding: EdgeInsets.zero,
                onPressed: isSubmitting ? null : _goToLogin,
                child: const Icon(CupertinoIcons.back),
              ),
            ),
          );

    return Scaffold(
      appBar: appBar,
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
                    context.l10n.registerTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    context.l10n.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  AuthTextField(
                    fieldKey: const Key('register_email_field'),
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
                    fieldKey: const Key('register_password_field'),
                    controller: _passwordController,
                    label: context.l10n.passwordLabel,
                    hint: context.l10n.passwordHintRegister,
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
                      bannerKey: const Key('register_error_banner'),
                      message: activeErrorMessage,
                      tone: AppFeedbackTone.error,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                  ],
                  AuthButton(
                    key: const Key('register_submit_button'),
                    text: context.l10n.registerButton,
                    isLoading: isSubmitting,
                    isEnabled: !isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppButton(
                    key: const Key('register_to_login_button'),
                    label: context.l10n.alreadyHaveAccountButton,
                    variant: AppButtonVariant.text,
                    isEnabled: !isSubmitting,
                    onPressed: _goToLogin,
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
