import 'package:flutter/widgets.dart';

/// Reports the screen a navigator shows by the name of its route.
///
/// Only [PageRoute]s are screens: dialogs, bottom sheets and popups are ignored.
/// A route without a name, like the shell on the root navigator, reports nothing
/// when pushed; returning to it asks [coveredScreenName] after the frame, when
/// the navigators below have updated too.
///
/// go_router also forwards the events of shell navigators to the observers of
/// the root one, so each observer ignores routes of other navigators.
class ScreenViewObserver extends NavigatorObserver {
  ScreenViewObserver(this._logScreenView, {this.coveredScreenName});

  final void Function(String name) _logScreenView;
  final String? Function()? coveredScreenName;
  final _pages = <PageRoute<dynamic>>[];

  /// The route name on top of this navigator, null before it shows anything.
  String? get currentName => _activePages.lastOrNull?.settings.name;

  /// Reports the screen on top, for a return that causes no navigator change.
  void reportCurrent() => _report(currentName);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute || route.navigator != navigator) return;
    _pages.add(route);
    _report(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute || route.navigator != navigator) return;
    _pages.remove(route);
    if (previousRoute is! PageRoute) return;
    final name = previousRoute.settings.name;
    if (name != null) {
      _report(name);
    } else if (coveredScreenName case final covered?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _report(covered()));
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute is PageRoute) _pages.remove(oldRoute);
    if (newRoute is! PageRoute || newRoute.navigator != navigator) return;
    _pages.add(newRoute);
    _report(newRoute.settings.name);
  }

  // The observers outlive a navigator only in tests, where each test has one.
  List<PageRoute<dynamic>> get _activePages =>
      _pages..removeWhere((route) => !route.isActive);

  void _report(String? name) {
    if (name != null) _logScreenView(name);
  }
}
