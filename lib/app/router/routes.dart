import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/link/open_link.dart';
import 'package:flutter_starter/app/router/screen_view_observer.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/use_case/notification/request_notification_permission_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/should_ask_notification_permission_use_case.dart';
import 'package:flutter_starter/domain/use_case/observability/track_screen_view_use_case.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_bloc.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_event.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/widget/favorite_toggle.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/widget/dialog/notification_permission_dialog.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_bloc.dart';
import 'package:flutter_starter/presentation/auth/page/reset_password_page.dart';
import 'package:flutter_starter/presentation/auth/page/sign_in_page.dart';
import 'package:flutter_starter/presentation/auth/page/sign_up_page.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_event.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_state.dart';
import 'package:flutter_starter/presentation/character_detail/page/character_detail_page.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_bloc.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_event.dart';
import 'package:flutter_starter/presentation/character_list/page/character_list_page.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_bloc.dart';
import 'package:flutter_starter/presentation/favorite_list/page/favorite_list_page.dart';
import 'package:flutter_starter/presentation/favorite_list/widget/remove_favorite_button.dart';
import 'package:flutter_starter/presentation/home_shell/page/home_shell_page.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/profile/page/profile_page.dart';
import 'package:flutter_starter/presentation/settings/page/settings_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'routes.g.dart';

/// Route names, reported as analytics screen names. They carry no ids.
abstract final class _ScreenNames {
  static const signIn = 'sign_in';
  static const signUp = 'sign_up';
  static const resetPassword = 'reset_password';
  static const characterList = 'character_list';
  static const characterDetail = 'character_detail';
  static const profile = 'profile';
  static const favoriteList = 'favorite_list';
  static const favoriteDetail = 'favorite_detail';
  static const settings = 'settings';
  static const logs = 'logs';
}

String? _lastScreen;

void _logScreenView(String name) {
  _lastScreen = name;
  unawaited(getIt<TrackScreenViewUseCase>()((name: name)));
}

// A navigator needs its own observer, so each branch has one.
final _characterListObserver = ScreenViewObserver(_logScreenView);
final _profileObserver = ScreenViewObserver(_logScreenView);
final _settingsObserver = ScreenViewObserver(_logScreenView);
final _branchObservers = [
  _characterListObserver,
  _profileObserver,
  _settingsObserver,
];
var _currentBranch = 0;

/// Closing an auth page returns to the shell, whose route has no name: the
/// current tab tells what the user sees then. A tab that has changed in the same
/// navigation has already reported that screen itself.
final rootScreenViewObserver = ScreenViewObserver(
  _logScreenView,
  coveredScreenName: () {
    final name = _branchObservers[_currentBranch].currentName;
    return name == _lastScreen ? null : name;
  },
);

Never _throwTestCrash() => throw StateError('Test crash from the dev settings');

/// The moment to ask about notifications: the first opened character, for guests and
/// signed-in users alike. A new app replaces only this trigger. A dialog that
/// could not be shown (null) leaves the flag unset, so the user is asked again.
Future<void> _askForNotificationPermission(BuildContext context) async {
  final shouldAsk = await getIt<ShouldAskNotificationPermissionUseCase>()(());
  if (shouldAsk case Ok(value: false) || Err()) return;
  if (!context.mounted) return;
  final agreed = await showNotificationPermissionDialog(context);
  if (agreed == null) return;
  await getIt<RequestNotificationPermissionUseCase>()((agreed: agreed));
}

/// Asks about notifications when the opened character loads, not after a failure or
/// a retry (NTF-1). A widget, so the flag survives a rebuild of the route.
class _AskOnFirstLoad extends StatefulWidget {
  const _AskOnFirstLoad({required this.child});

  final Widget child;

  @override
  State<_AskOnFirstLoad> createState() => _AskOnFirstLoadState();
}

class _AskOnFirstLoadState extends State<_AskOnFirstLoad> {
  var _settled = false;

  @override
  Widget build(BuildContext context) =>
      BlocListener<CharacterDetailBloc, CharacterDetailState>(
        listenWhen: (_, current) =>
            !_settled && current is! CharacterDetailLoading,
        listener: (context, state) {
          _settled = true;
          if (state is CharacterDetailLoaded) {
            unawaited(_askForNotificationPermission(context));
          }
        },
        child: widget.child,
      );
}

Widget _favoriteToggle(Character character) => BlocProvider(
  create: (_) =>
      getIt<FavoriteToggleBloc>()..add(FavoriteToggleStarted(character.id)),
  child: FavoriteToggle(character: character),
);

@TypedGoRoute<SignInRoute>(path: '/sign-in', name: _ScreenNames.signIn)
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<SignInBloc>(),
    child: SignInPage(
      onSignUp: () => const SignUpRoute().push<void>(context),
      onResetPassword: () => const ResetPasswordRoute().push<void>(context),
      onSuccess: () => const ProfileRoute().go(context),
    ),
  );
}

@TypedGoRoute<SignUpRoute>(path: '/sign-up', name: _ScreenNames.signUp)
class SignUpRoute extends GoRouteData with $SignUpRoute {
  const SignUpRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<SignUpBloc>(),
    child: SignUpPage(
      onSignIn: () => context.pop(),
      onSuccess: () => const ProfileRoute().go(context),
    ),
  );
}

@TypedGoRoute<ResetPasswordRoute>(
  path: '/reset-password',
  name: _ScreenNames.resetPassword,
)
class ResetPasswordRoute extends GoRouteData with $ResetPasswordRoute {
  const ResetPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<ResetPasswordBloc>(),
    child: ResetPasswordPage(onSignIn: () => context.pop()),
  );
}

@TypedStatefulShellRoute<HomeShellRoute>(
  branches: [
    TypedStatefulShellBranch<CharacterListBranch>(
      routes: [
        TypedGoRoute<CharacterListRoute>(
          path: '/character-list',
          name: _ScreenNames.characterList,
          routes: [
            TypedGoRoute<CharacterDetailRoute>(
              path: ':id',
              name: _ScreenNames.characterDetail,
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<ProfileBranch>(
      routes: [
        TypedGoRoute<ProfileRoute>(
          path: '/profile',
          name: _ScreenNames.profile,
          routes: [
            TypedGoRoute<FavoriteListRoute>(
              path: 'favorite-list',
              name: _ScreenNames.favoriteList,
              routes: [
                TypedGoRoute<FavoriteDetailRoute>(
                  path: ':id',
                  name: _ScreenNames.favoriteDetail,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: [
        TypedGoRoute<SettingsRoute>(
          path: '/settings',
          name: _ScreenNames.settings,
          routes: [
            TypedGoRoute<LogsRoute>(path: 'logs', name: _ScreenNames.logs),
          ],
        ),
      ],
    ),
  ],
)
class HomeShellRoute extends StatefulShellRouteData {
  const HomeShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    _currentBranch = navigationShell.currentIndex;
    return HomeShellPage(
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        final isCurrent = index == navigationShell.currentIndex;
        // Switching tabs causes no navigator change, so it is reported here. A
        // tab shown for the first time has no current name: its observer reports
        // it. Tapping the active tab pops to its root, which the observer sees.
        if (!isCurrent) _branchObservers[index].reportCurrent();
        navigationShell.goBranch(index, initialLocation: isCurrent);
      },
      child: navigationShell,
    );
  }
}

class CharacterListBranch extends StatefulShellBranchData {
  const CharacterListBranch();

  static final List<NavigatorObserver> $observers = [_characterListObserver];
}

class ProfileBranch extends StatefulShellBranchData {
  const ProfileBranch();

  static final List<NavigatorObserver> $observers = [_profileObserver];
}

class SettingsBranch extends StatefulShellBranchData {
  const SettingsBranch();

  static final List<NavigatorObserver> $observers = [_settingsObserver];
}

class CharacterListRoute extends GoRouteData with $CharacterListRoute {
  const CharacterListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) =>
        getIt<CharacterListBloc>()..add(const CharacterListLoadRequested()),
    child: CharacterListPage(
      onCharacterSelected: (id) => CharacterDetailRoute(id: id).go(context),
      favoriteToggleBuilder: _favoriteToggle,
    ),
  );
}

class CharacterDetailRoute extends GoRouteData with $CharacterDetailRoute {
  const CharacterDetailRoute({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<CharacterDetailBloc>()..add(CharacterDetailOpened(id)),
    child: _AskOnFirstLoad(
      child: CharacterDetailPage(
        id: id,
        favoriteToggleBuilder: _favoriteToggle,
      ),
    ),
  );
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<ProfileBloc>(),
    child: ProfilePage(
      onSignIn: () => const SignInRoute().push<void>(context),
      onFavorites: () => const FavoriteListRoute().go(context),
    ),
  );
}

class FavoriteListRoute extends GoRouteData with $FavoriteListRoute {
  const FavoriteListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<FavoriteListBloc>(),
    child: FavoriteListPage(
      onSignIn: () => const SignInRoute().push<void>(context),
      onCharacterSelected: (id) => FavoriteDetailRoute(id: id).go(context),
      favoriteToggleBuilder: _favoriteToggle,
    ),
  );
}

class FavoriteDetailRoute extends GoRouteData with $FavoriteDetailRoute {
  const FavoriteDetailRoute({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<CharacterDetailBloc>()..add(CharacterDetailOpened(id)),
    child: _AskOnFirstLoad(
      child: CharacterDetailPage(
        id: id,
        favoriteToggleBuilder: _favoriteToggle,
        notFoundActionBuilder: (_) => BlocProvider(
          create: (_) => getIt<FavoriteListBloc>(),
          child: RemoveFavoriteButton(id: id, onRemoved: () => context.pop()),
        ),
      ),
    ),
  );
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final config = getIt<AppConfig>();
    final isDev = config.flavor == Flavor.dev;
    return SettingsPage(
      appVersion: getIt<AppInfo>().version,
      privacyPolicyUrl: Uri.parse(config.privacyPolicyUrl),
      onOpenLink: (url) => openLink(url, talker: getIt<Talker>()),
      onLogs: isDev ? () => const LogsRoute().go(context) : null,
      onTestCrash: isDev ? _throwTestCrash : null,
    );
  }
}

class LogsRoute extends GoRouteData with $LogsRoute {
  const LogsRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      getIt<AppConfig>().flavor == Flavor.dev
      ? null
      : const SettingsRoute().location;

  @override
  Widget build(BuildContext context, GoRouterState state) => TalkerScreen(
    talker: getIt<Talker>(),
    appBarTitle: context.l10n.settingsLogs,
  );
}
