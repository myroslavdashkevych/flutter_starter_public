import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/app_localizations_delegate.dart';
import 'package:flutter_starter/presentation/home_shell/page/home_shell_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helper/accessibility.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    int currentIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeShellPage(
          currentIndex: currentIndex,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          child: const Text('child'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testAccessibility((tester, theme) => pumpPage(tester, theme: theme));

  testWidgets('NAV-2: shows the child and the tabs in order', (tester) async {
    await pumpPage(tester);

    expect(find.text('child'), findsOneWidget);
    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((destination) => destination.label);
    expect(labels, ['Characters', 'Profile', 'Settings']);
  });

  testWidgets('highlights the current tab', (tester) async {
    await pumpPage(tester, currentIndex: 2);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('reports the selected tab', (tester) async {
    int? selected;
    await pumpPage(tester, onDestinationSelected: (index) => selected = index);

    await tester.tap(find.text('Profile'));

    expect(selected, 1);
  });
}
