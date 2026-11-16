import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:flutter_starter/presentation/auth/widget/auth_field_error_message.dart';
import 'package:material_ui/material_ui.dart';

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
