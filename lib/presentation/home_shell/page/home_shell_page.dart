import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:material_ui/material_ui.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list),
            label: l10n.navCharacterList,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
