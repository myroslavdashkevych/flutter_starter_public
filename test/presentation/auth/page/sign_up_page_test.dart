import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_up_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/app_localizations_delegate.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_bloc.dart';
import 'package:flutter_starter/presentation/auth/page/sign_up_page.dart';
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
          create: (_) => SignUpBloc(
            SignUpUseCase(MockAuthRepository(), FakeAnalyticsService()),
          ),
          child: SignUpPage(onSignIn: () {}, onSuccess: () {}),
        ),
      ),
    ),
  );
}
