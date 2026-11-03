import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_state.dart';
import 'package:flutter_starter/presentation/auth/widgets/auth_form.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    required this.onSignUp,
    required this.onResetPassword,
    required this.onSuccess,
    super.key,
  });

  final VoidCallback onSignUp;
  final VoidCallback onResetPassword;
  final VoidCallback onSuccess;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SignInCubit, SignInState>(
      listenWhen: (previous, current) =>
          !previous.isSuccess && current.isSuccess,
      listener: (_, _) => widget.onSuccess(),
      builder: (context, state) => AuthFormLayout(
        title: l10n.signInTitle,
        children: [
          EmailField(controller: _email, error: state.emailError),
          PasswordField(
            controller: _password,
            label: l10n.authPasswordLabel,
            error: state.passwordError,
          ),
          if (state.failure case final failure?)
            AuthFailureText(failure: failure),
          AuthSubmitButton(
            label: l10n.signInSubmit,
            isSubmitting: state.isSubmitting,
            onPressed: () => context.read<SignInCubit>().submit(
              email: _email.text.trim(),
              password: _password.text,
            ),
          ),
          TextButton(
            onPressed: widget.onResetPassword,
            child: Text(l10n.signInForgotPassword),
          ),
          TextButton(
            onPressed: widget.onSignUp,
            child: Text(l10n.signInCreateAccount),
          ),
        ],
      ),
    );
  }
}
