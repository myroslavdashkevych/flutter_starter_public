import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.content),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.item,
            children: children,
          ),
        ),
      ),
    );
  }
}
