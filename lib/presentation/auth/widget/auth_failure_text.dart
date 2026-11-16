import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:material_ui/material_ui.dart';

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
