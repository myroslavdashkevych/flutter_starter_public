import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_event.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_state.dart';
import 'package:material_ui/material_ui.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          previous.isDeleting &&
          !current.isDeleting &&
          current.deleteFailure == null,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) => AlertDialog(
        title: Text(l10n.profileDeleteAccountTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.item,
            children: [
              Text(l10n.profileDeleteAccountWarning),
              TextField(
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                enabled: !state.isDeleting,
                decoration: InputDecoration(
                  labelText: l10n.authPasswordLabel,
                  errorText: state.deleteFailure?.message(l10n),
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.isDeleting
                ? null
                : () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ListenableBuilder(
            listenable: _password,
            builder: (context, _) => TextButton(
              onPressed: state.isDeleting || _password.text.isEmpty
                  ? null
                  : () => context.read<ProfileBloc>().add(
                      ProfileDeleteRequested(password: _password.text),
                    ),
              child: Text(l10n.profileDeleteAccountConfirm),
            ),
          ),
        ],
      ),
    );
  }
}
