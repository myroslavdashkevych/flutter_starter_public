import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class FailureView extends StatelessWidget {
  const FailureView({required this.failure, required this.onRetry, super.key});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.content),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(failure.message(l10n), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.inline),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
