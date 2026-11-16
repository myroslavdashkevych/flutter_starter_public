import 'dart:async';

import 'package:flutter_starter/domain/use_case/notification/initialize_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/register_for_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/show_foreground_notification_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_foreground_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_notification_registration_ids_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_opened_notifications_use_case.dart';
import 'package:go_router/go_router.dart';
import 'package:talker/talker.dart';

/// Prepares notifications and shows the ones that arrive in the foreground. There
/// is no backend yet, so the registration ID only goes to the log.
Future<void> setUpNotifications({
  required InitializeNotificationsUseCase initialize,
  required WatchNotificationRegistrationIdsUseCase watchRegistrationIds,
  required WatchForegroundNotificationsUseCase watchForeground,
  required ShowForegroundNotificationUseCase showForeground,
  required RegisterForNotificationsUseCase register,
  required Talker talker,
  required String channelName,
}) async {
  await initialize((channelName: channelName));
  watchRegistrationIds(())
      .listen((id) => talker.info('FCM registration ID (FID): $id'));
  watchForeground(())
      .listen((message) => unawaited(showForeground((message: message))));
  unawaited(register(()));
}

/// Opens the route of a tapped notification. Call it after the first frame: the
/// message that launched the app arrives right away.
void openTappedNotifications({
  required WatchOpenedNotificationsUseCase watchOpened,
  required GoRouter router,
  required Talker talker,
}) {
  watchOpened(()).listen((message) {
    final route = message.route;
    if (route == null) return;
    if (isOpenableRoute(router, route)) {
      router.go(route);
    } else {
      talker.warning('Ignored the notification route: $route');
    }
  });
}

/// A route comes from outside the app, so only an existing in-app location
/// passes. The typed routes parse `id` with `int.parse`, which throws on a bad id.
bool isOpenableRoute(GoRouter router, String route) {
  final uri = Uri.tryParse(route);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/')) {
    return false;
  }
  final match = router.configuration.findMatch(uri);
  if (match.isError) return false;
  final id = match.pathParameters['id'];
  return id == null || int.tryParse(id) != null;
}
