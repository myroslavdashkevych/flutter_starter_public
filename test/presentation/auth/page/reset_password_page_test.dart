import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/use_case/auth/send_password_reset_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/app_localizations_delegate.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_bloc.dart';
import 'package:flutter_starter/presentation/auth/page/reset_password_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helper/accessibility.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  testAccessibility(
    (tester, theme) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => ResetPasswordBloc(
            SendPasswordResetUseCase(
              MockAuthRepository(),
              FakeAnalyticsService(),
            ),
          ),
          child: ResetPasswordPage(onSignIn: () {}),
        ),
      ),
    ),
  );
}
