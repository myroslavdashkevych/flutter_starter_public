import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/app_info.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/injection.dart';
import 'package:flutter_starter/app/links/open_link.dart';
import 'package:flutter_starter/app/router/screen_view_observer.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/notifications/usecases/request_notification_permission_use_case.dart';
import 'package:flutter_starter/presentation/_shared/bloc/favorite/favorite_toggle_cubit.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/widgets/button/favorite_toggle.dart';
import 'package:flutter_starter/presentation/_shared/widgets/dialog/notification_permission_dialog.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_cubit.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_cubit.dart';
import 'package:flutter_starter/presentation/auth/pages/reset_password_page.dart';
import 'package:flutter_starter/presentation/auth/pages/sign_in_page.dart';
import 'package:flutter_starter/presentation/auth/pages/sign_up_page.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:flutter_starter/presentation/favorites/pages/favorites_page.dart';
import 'package:flutter_starter/presentation/favorites/widgets/remove_favorite_button.dart';
import 'package:flutter_starter/presentation/home_shell/pages/home_shell_page.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_cubit.dart';
import 'package:flutter_starter/presentation/item_details/pages/item_details_page.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_bloc.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_event.dart';
import 'package:flutter_starter/presentation/items_list/pages/items_list_page.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_cubit.dart';
import 'package:flutter_starter/presentation/profile/pages/profile_page.dart';
import 'package:flutter_starter/presentation/settings/pages/settings_page.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'routes.g.dart';

/// Route names, reported as analytics screen names. They carry no ids.
abstract final class _ScreenNames {
  static const signIn = 'sign_in';
  static const signUp = 'sign_up';
  static const resetPassword = 'reset_password';
  static const items = 'items';
  static const itemDetails = 'item_details';
  static const profile = 'profile';
  static const favorites = 'favorites';
  static const favoriteDetails = 'favorite_details';
  static const settings = 'settings';
  static const logs = 'logs';
}

String? _lastScreen;

void _logScreenView(String name) {
  _lastScreen = name;
  unawaited(getIt<AnalyticsService>().logScreenView(name));
}

// A navigator needs its own observer, so each branch has one.
final _itemsObserver = ScreenViewObserver(_logScreenView);
final _profileObserver = ScreenViewObserver(_logScreenView);
final _settingsObserver = ScreenViewObserver(_logScreenView);
final _branchObservers = [_itemsObserver, _profileObserver, _settingsObserver];
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

/// The moment to ask about notifications: the first opened item, for guests and
/// signed-in users alike. A new app replaces only this trigger.
void _askForNotificationPermission(BuildContext context) => unawaited(
  getIt<RequestNotificationPermissionUseCase>()(
    askUser: () => showNotificationPermissionDialog(context),
  ),
);

Widget _favoriteToggle(Item item) => BlocProvider(
  create: (_) => getIt<FavoriteToggleCubit>()..watch(item.id),
  child: FavoriteToggle(item: item),
);

@TypedGoRoute<SignInRoute>(path: '/sign-in', name: _ScreenNames.signIn)
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<SignInCubit>(),
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
    create: (_) => getIt<SignUpCubit>(),
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
    create: (_) => getIt<ResetPasswordCubit>(),
    child: ResetPasswordPage(onSignIn: () => context.pop()),
  );
}

@TypedStatefulShellRoute<HomeShellRoute>(
  branches: [
    TypedStatefulShellBranch<ItemsBranch>(
      routes: [
        TypedGoRoute<ItemsRoute>(
          path: '/items',
          name: _ScreenNames.items,
          routes: [
            TypedGoRoute<ItemDetailsRoute>(
              path: ':id',
              name: _ScreenNames.itemDetails,
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
            TypedGoRoute<FavoritesRoute>(
              path: 'favorites',
              name: _ScreenNames.favorites,
              routes: [
                TypedGoRoute<FavoriteDetailsRoute>(
                  path: ':id',
                  name: _ScreenNames.favoriteDetails,
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

class ItemsBranch extends StatefulShellBranchData {
  const ItemsBranch();

  static final List<NavigatorObserver> $observers = [_itemsObserver];
}

class ProfileBranch extends StatefulShellBranchData {
  const ProfileBranch();

  static final List<NavigatorObserver> $observers = [_profileObserver];
}

class SettingsBranch extends StatefulShellBranchData {
  const SettingsBranch();

  static final List<NavigatorObserver> $observers = [_settingsObserver];
}

class ItemsRoute extends GoRouteData with $ItemsRoute {
  const ItemsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<ItemsListBloc>()..add(const ItemsListLoadRequested()),
    child: ItemsListPage(
      onItemSelected: (id) => ItemDetailsRoute(id: id).go(context),
      favoriteToggleBuilder: _favoriteToggle,
    ),
  );
}

class ItemDetailsRoute extends GoRouteData with $ItemDetailsRoute {
  const ItemDetailsRoute({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) =>
        getIt<ItemDetailsCubit>()
          ..open(id, onLoaded: () => _askForNotificationPermission(context)),
    child: ItemDetailsPage(id: id, favoriteToggleBuilder: _favoriteToggle),
  );
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<ProfileCubit>(),
    child: ProfilePage(
      onSignIn: () => const SignInRoute().push<void>(context),
      onFavorites: () => const FavoritesRoute().go(context),
    ),
  );
}

class FavoritesRoute extends GoRouteData with $FavoritesRoute {
  const FavoritesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => getIt<FavoritesCubit>(),
    child: FavoritesPage(
      onSignIn: () => const SignInRoute().push<void>(context),
      onItemSelected: (id) => FavoriteDetailsRoute(id: id).go(context),
      favoriteToggleBuilder: _favoriteToggle,
    ),
  );
}

class FavoriteDetailsRoute extends GoRouteData with $FavoriteDetailsRoute {
  const FavoriteDetailsRoute({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) =>
        getIt<ItemDetailsCubit>()
          ..open(id, onLoaded: () => _askForNotificationPermission(context)),
    child: ItemDetailsPage(
      id: id,
      favoriteToggleBuilder: _favoriteToggle,
      notFoundActionBuilder: (_) => BlocProvider(
        create: (_) => getIt<FavoritesCubit>(),
        child: RemoveFavoriteButton(id: id, onRemoved: () => context.pop()),
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
