import 'dart:async';

import 'package:flutter_starter/domain/notifications/repositories/notifications_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:talker/talker.dart';

/// Prepares notifications and shows the ones that arrive in the foreground. There
/// is no backend yet, so the registration ID only goes to the log.
Future<void> setUpNotifications({
  required NotificationsRepository repository,
  required Talker talker,
  required String channelName,
}) async {
  await repository.initialize(channelName: channelName);
  repository.registrationIdChanges().listen(
    (id) => talker.info('FCM registration ID (FID): $id'),
  );
  repository
      .foregroundMessages()
      .where((message) => message.title != null || message.body != null)
      .listen((message) => unawaited(repository.showForeground(message)));
  unawaited(repository.register());
}

/// Opens the route of a tapped notification. Call it after the first frame: the
/// message that launched the app arrives right away.
void openTappedNotifications({
  required NotificationsRepository repository,
  required GoRouter router,
  required Talker talker,
}) {
  repository.openedMessages().listen((message) {
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
