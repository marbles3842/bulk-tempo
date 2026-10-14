import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final formState = ref.watch(registerViewModelProvider);
    final notifier = ref.read(registerViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.fitness_center, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.registerTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    fieldKey: const Key('register_email_field'),
                    controller: _emailController,
                    label: context.l10n.emailLabel,
                    hint: context.l10n.emailHint,
                    errorText: formState.emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.updateEmail,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    fieldKey: const Key('register_password_field'),
                    controller: _passwordController,
                    label: context.l10n.passwordLabel,
                    hint: context.l10n.passwordHintRegister,
                    errorText: formState.passwordError,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: notifier.updatePassword,
                    onSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscurePassword
                          ? context.l10n.showPasswordTooltip
                          : context.l10n.hidePasswordTooltip,
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthButton(
                    key: const Key('register_submit_button'),
                    text: context.l10n.registerButton,
                    isLoading: formState.status == FormStatus.submitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    key: const Key('register_to_login_button'),
                    onPressed: _goToLogin,
                    child: Text(context.l10n.alreadyHaveAccountButton),
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
