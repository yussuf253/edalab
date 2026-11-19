import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edalab/core/localization/app_localizations.dart';
import 'package:edalab/core/modules/module_access_service.dart';
import 'package:edalab/core/providers/auth_provider.dart';
import 'package:edalab/core/providers/module_provider.dart';
import 'package:edalab/core/providers/notification_provider.dart';
import 'package:edalab/core/providers/user_location_provider.dart';
import 'package:edalab/core/widgets/app_search_bar.dart';
import 'package:edalab/core/widgets/app_shimmer.dart';
import 'package:edalab/core/widgets/common_widgets.dart';
import 'package:edalab/core/widgets/notification_bell.dart';
import 'package:edalab/features/home/screens/home_screen.dart';

Future<void> _pumpHome(
  WidgetTester tester,
  ModuleProvider moduleProvider,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ModuleProvider>.value(value: moduleProvider),
        ChangeNotifierProvider<UserLocationProvider>(
          create: (_) => UserLocationProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );
  // Settle the post-frame location kick-off; its platform calls fail without
  // a geolocator implementation and the provider swallows that itself.
  await tester.pump();
  await tester.pump();
}

Finder _byPrivateType(String name, {bool skipOffstage = true}) =>
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == name,
      skipOffstage: skipOffstage,
    );


/// The loaded header avatar: a gradient [Container] with a 14px radius.
/// Other gradient fills on the home (offer and product cards) use different
/// corner radii, so radius 14 singles the avatar out.
void main() {
  setUpAll(() {
    // The test binding answers every HTTP request with a 400, so
    // google_fonts' runtime fetch always throws and fails the test. Rendering
    // falls back to the default font instead, which is what the goldens below
    // were recorded with.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Both states below must see the same module set: the hardcoded defaults
    // (everything active) that a not-yet-hydrated provider also exposes.
    ModuleAccessService.instance.applyModules(const []);
  });

  testWidgets(
    'initial-sync shimmer occupies the same slots as the loaded home',
    (tester) async {
      final moduleProvider = ModuleProvider(); // never hydrated → skeleton

      await _pumpHome(tester, moduleProvider);
      expect(moduleProvider.isReady, isFalse);
      expect(find.byType(AppSearchBar), findsNothing);

      // Skeleton build order: avatar, location line, name line, bell, search,
      // banner, then the section title blocks.
      final shimmer = <String, Rect>{
        'avatar': tester.getRect(find.byType(ShimmerBlock).at(0)),
        'bell': tester.getRect(find.byType(ShimmerBlock).at(3)),
        'search': tester.getRect(find.byType(ShimmerBlock).at(4)),
        'banner': tester.getRect(find.byType(ShimmerBlock).at(5)),
        'servicesGrid': tester.getRect(_byPrivateType('_ServicesGridShimmer')),
      };
      expect(_byPrivateType('_ServicesGridShimmer'), findsOneWidget);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_initial_sync_shimmer.png'),
      );

      // Same provider, now hydrated from (empty) storage: the default config,
      // i.e. exactly what the skeleton was guessing at.
      await moduleProvider.hydrateFromStorage();
      await tester.pump();
      expect(moduleProvider.isReady, isTrue);
      // No load-in animations any more: the loaded content paints straight
      // into its layout slot, so a single pump is enough.
      await tester.pump();

      // The loaded view has no entrance animations, so every slot sits at its
      // layout position — the skeleton must mirror it rect-for-rect.
      final loaded = <String, Rect>{
        'search': tester.getRect(find.byType(AppSearchBar)),
        'banner': tester.getRect(_byPrivateType('_PromoBanner')),
        'servicesGrid': tester.getRect(_byPrivateType('_ServicesGrid')),
      };

      // Every section (services, special offers, restaurants, doctors,
      // trending products) is present in the loaded view, so the skeleton
      // must have mirrored all of them too.
      // Section headers below the viewport fold render offstage inside the
      // CustomScrollView, so don't skip them.
      expect(find.byType(SectionHeader, skipOffstage: false), findsNWidgets(5));
      expect(
        _byPrivateType('_SpecialOffers', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        _byPrivateType('_PopularRestaurants', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        _byPrivateType('_TopDoctors', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        _byPrivateType('_TrendingProducts', skipOffstage: false),
        findsOneWidget,
      );

      loaded.forEach((slot, expected) {
        final actual = shimmer[slot]!;
        debugPrint(
          'SLOT $slot: actual=${actual.toString()} '
          'expected=${expected.toString()}',
        );
        expect(actual.left, closeTo(expected.left, 0.01), reason: '$slot.left');
        // The skeleton sizes the section-title line box analytically
        // (18 × 1.4 × textScale) while the loaded title's height comes from
        // the font's own metrics, so the rows below it can land a fraction of
        // a pixel apart (0.2px in the test's fallback font).
        expect(actual.top, closeTo(expected.top, 0.5), reason: '$slot.top');
        expect(
          actual.width,
          closeTo(expected.width, 0.01),
          reason: '$slot.width',
        );
        expect(
          actual.height,
          closeTo(expected.height, 0.01),
          reason: '$slot.height',
        );
      });

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_loaded.png'),
      );
    },
  );
}
