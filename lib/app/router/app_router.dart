import 'package:flutter_starter/app/router/auth_redirect.dart';
import 'package:flutter_starter/app/router/routes.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  routes: $appRoutes,
  initialLocation: const ItemsRoute().location,
  // FlutterActivity reads the `route` intent extra as the platform default route,
  // and FCM copies `data.route` there. That would skip `isOpenableRoute`.
  overridePlatformDefaultLocation: true,
  redirect: (_, state) => authRedirect(authBloc.state, state.uri),
  observers: [rootScreenViewObserver],
);
