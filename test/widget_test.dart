import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edalab/app.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:edalab/core/providers/language_provider.dart';
import 'package:edalab/core/providers/theme_provider.dart';

void main() {
  testWidgets('EdaLab app smoke test', (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: EdaLabApp(router: router),
      ),
    );
    await tester.pump();
  });
}
