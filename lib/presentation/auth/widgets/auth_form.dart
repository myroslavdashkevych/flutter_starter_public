import 'package:flutter/material.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';

extension AuthFieldErrorMessage on AuthFieldError {
  String message(AppLocalizations l10n) => switch (this) {
    AuthFieldError.emailEmpty => l10n.authEmailEmpty,
    AuthFieldError.emailInvalid => l10n.authEmailInvalid,
    AuthFieldError.passwordTooShort => l10n.authPasswordTooShort,
    AuthFieldError.passwordsDoNotMatch => l10n.authPasswordsDoNotMatch,
  };
}

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: children,
          ),
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({required this.controller, this.error, super.key});

  final TextEditingController controller;
  final AuthFieldError? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.authEmailLabel,
        errorText: error?.message(l10n),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.error,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final AuthFieldError? error;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        errorText: error?.message(context.l10n),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class AuthFailureText extends StatelessWidget {
  const AuthFailureText({required this.failure, super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Text(
      failure.message(context.l10n),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
      textAlign: TextAlign.center,
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.isSubmitting,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
