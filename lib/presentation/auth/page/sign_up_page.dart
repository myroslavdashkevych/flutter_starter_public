import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_state.dart';
import 'package:flutter_starter/presentation/auth/widget/auth_failure_text.dart';
import 'package:flutter_starter/presentation/auth/widget/auth_form_layout.dart';
import 'package:flutter_starter/presentation/auth/widget/auth_submit_button.dart';
import 'package:flutter_starter/presentation/auth/widget/email_field.dart';
import 'package:flutter_starter/presentation/auth/widget/password_field.dart';
import 'package:material_ui/material_ui.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    required this.onSignIn,
    required this.onSuccess,
    super.key,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSuccess;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SignUpBloc, SignUpState>(
      listenWhen: (previous, current) =>
          !previous.isSuccess && current.isSuccess,
      listener: (_, _) => widget.onSuccess(),
      builder: (context, state) => AuthFormLayout(
        title: l10n.signUpTitle,
        children: [
          EmailField(controller: _email, error: state.emailError),
          PasswordField(
            controller: _password,
            label: l10n.authPasswordLabel,
            error: state.passwordError,
          ),
          PasswordField(
            controller: _confirmation,
            label: l10n.authConfirmPasswordLabel,
            error: state.confirmationError,
          ),
          if (state.failure case final failure?)
            AuthFailureText(failure: failure),
          AuthSubmitButton(
            label: l10n.signUpSubmit,
            isSubmitting: state.isSubmitting,
            onPressed: () => context.read<SignUpBloc>().add(
              SignUpSubmitted(
                email: _email.text.trim(),
                password: _password.text,
                confirmation: _confirmation.text,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onSignIn,
            child: Text(l10n.signUpHaveAccount),
          ),
        ],
      ),
    );
  }
}
