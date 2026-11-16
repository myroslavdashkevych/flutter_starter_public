import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_event.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_state.dart';
import 'package:flutter_starter/presentation/profile/widget/delete_account_dialog.dart';
import 'package:material_ui/material_ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.onSignIn,
    required this.onFavorites,
    super.key,
  });

  final VoidCallback onSignIn;
  final VoidCallback onFavorites;

  Future<void> _handleSignOutTap(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<ProfileBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileSignOutTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profileSignOut),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const ProfileSignOutRequested());
  }

  Future<void> _handleDeleteAccountTap(BuildContext context) =>
      showDialog<void>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: const DeleteAccountDialog(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.signOutFailure != current.signOutFailure &&
            current.signOutFailure != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.signOutFailure!.message(l10n))),
          );
        },
        builder: (context, state) {
          if (!state.isAuthKnown) return const SizedBox.shrink();
          final user = state.user;
          if (user == null) return _GuestView(onSignIn: onSignIn);
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.authEmailLabel),
                subtitle: Text(user.email ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text(l10n.favoriteListTitle),
                onTap: onFavorites,
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.profileSignOut),
                onTap: () => _handleSignOutTap(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.profileDeleteAccount),
                onTap: () => _handleDeleteAccountTap(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.content),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.item,
          children: [
            Text(l10n.profileGuestMessage, textAlign: TextAlign.center),
            FilledButton(onPressed: onSignIn, child: Text(l10n.profileSignIn)),
          ],
        ),
      ),
    );
  }
}
