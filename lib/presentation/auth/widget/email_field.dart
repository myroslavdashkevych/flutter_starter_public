import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:flutter_starter/presentation/auth/widget/auth_field_error_message.dart';
import 'package:material_ui/material_ui.dart';

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
