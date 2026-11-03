import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_state.dart';
import 'package:flutter_starter/presentation/auth/widgets/auth_form.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
      builder: (context, state) => AuthFormLayout(
        title: l10n.resetPasswordTitle,
        children: [
          if (state.isSent)
            Text(l10n.resetPasswordSent, textAlign: TextAlign.center)
          else ...[
            EmailField(controller: _email, error: state.emailError),
            if (state.failure case final failure?)
              AuthFailureText(failure: failure),
            AuthSubmitButton(
              label: l10n.resetPasswordSubmit,
              isSubmitting: state.isSubmitting,
              onPressed: () => context.read<ResetPasswordCubit>().submit(
                email: _email.text.trim(),
              ),
            ),
          ],
          TextButton(
            onPressed: widget.onSignIn,
            child: Text(l10n.resetPasswordBackToSignIn),
          ),
        ],
      ),
    );
  }
}
