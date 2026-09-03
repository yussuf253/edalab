import 'package:flutter_test/flutter_test.dart';
import 'package:edalab/pro/l10n/app_localizations_ar.dart';
import 'package:edalab/pro/l10n/app_localizations_fr.dart';

void main() {
  group('Arabic translations', () {
    late AppLocalizationsAr ar;
    setUp(() => ar = AppLocalizationsAr());

    test('recently-fixed getters return Arabic, not English', () {
      expect(ar.edaLabProWelcomeTitle, isNot('Welcome'));
      expect(ar.edaLabProWelcomeDescription, isNot('Welcome'));
      expect(ar.edaLabProWelcomeSignInButton, isNot('Sign In'));
      expect(ar.edaLabProWelcomeCreateAccountButton, isNot('Create Account'));
      expect(ar.completeLabel, isNot('Complete'));
      expect(ar.doneLabel, isNot('Done'));
      expect(ar.storeLabel, isNot('Store'));
      expect(ar.itemLabel, isNot('Item'));
      expect(ar.weekdays, isNot('Weekdays'));
    });

    test('all recently-fixed getters return non-empty strings', () {
      final getters = <String Function()>[
        () => ar.edaLabProWelcomeTitle,
        () => ar.edaLabProWelcomeDescription,
        () => ar.edaLabProWelcomeSignInButton,
        () => ar.edaLabProWelcomeCreateAccountButton,
        () => ar.completeLabel,
        () => ar.doneLabel,
        () => ar.storeLabel,
        () => ar.itemLabel,
        () => ar.weekdays,
      ];
      for (final g in getters) {
        expect(g(), isNotEmpty);
      }
    });

    test('critical getters return non-empty strings', () {
      expect(ar.appTitle, isNotEmpty);
      expect(ar.somethingWentWrong, isNotEmpty);
      expect(ar.onboardingTitle1, isNotEmpty);
      expect(ar.onboardingSubtitle1, isNotEmpty);
      expect(ar.onboardingGetStarted, isNotEmpty);
      expect(ar.onboardingSignIn, isNotEmpty);
      expect(ar.onboardingFlowQueued, isNotEmpty);
      expect(ar.offline, isNotEmpty);
      expect(ar.modules, isNotEmpty);
      expect(ar.saveChanges, isNotEmpty);
      expect(ar.next, isNotEmpty);
      expect(ar.skip, isNotEmpty);
      expect(ar.selectActiveModules, isNotEmpty);
      expect(ar.pharmacyLabel, isNotEmpty);
      expect(ar.businessNameLabel, isNotEmpty);
    });

    test('Arabic values contain Arabic script characters', () {
      // Arabic Unicode range: \u0600-\u06FF
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      expect(arabicRegex.hasMatch(ar.appTitle), isTrue,
          reason: 'appTitle should contain Arabic script');
      expect(arabicRegex.hasMatch(ar.edaLabProWelcomeTitle), isTrue,
          reason: 'edaLabProWelcomeTitle should contain Arabic script');
      expect(arabicRegex.hasMatch(ar.weekdays), isTrue,
          reason: 'weekdays should contain Arabic script');
      expect(arabicRegex.hasMatch(ar.storeLabel), isTrue,
          reason: 'storeLabel should contain Arabic script');
      expect(arabicRegex.hasMatch(ar.itemLabel), isTrue,
          reason: 'itemLabel should contain Arabic script');
    });
  });

  group('French translations', () {
    late AppLocalizationsFr fr;
    setUp(() => fr = AppLocalizationsFr());

    test('recently-fixed getters return French, not English', () {
      expect(fr.edaLabProWelcomeTitle, isNot('Welcome'));
      expect(fr.edaLabProWelcomeDescription, isNot('Welcome'));
      expect(fr.edaLabProWelcomeSignInButton, isNot('Sign In'));
      expect(fr.edaLabProWelcomeCreateAccountButton, isNot('Create Account'));
      expect(fr.completeLabel, isNot('Complete'));
      expect(fr.doneLabel, isNot('Done'));
      expect(fr.storeLabel, isNot('Store'));
      expect(fr.itemLabel, isNot('Item'));
      expect(fr.weekdays, isNot('Weekdays'));
    });

    test('all recently-fixed getters return non-empty strings', () {
      final getters = <String Function()>[
        () => fr.edaLabProWelcomeTitle,
        () => fr.edaLabProWelcomeDescription,
        () => fr.edaLabProWelcomeSignInButton,
        () => fr.edaLabProWelcomeCreateAccountButton,
        () => fr.completeLabel,
        () => fr.doneLabel,
        () => fr.storeLabel,
        () => fr.itemLabel,
        () => fr.weekdays,
      ];
      for (final g in getters) {
        expect(g(), isNotEmpty);
      }
    });

    test('critical getters return non-empty strings', () {
      expect(fr.appTitle, isNotEmpty);
      expect(fr.somethingWentWrong, isNotEmpty);
      expect(fr.onboardingTitle1, isNotEmpty);
      expect(fr.onboardingSubtitle1, isNotEmpty);
      expect(fr.onboardingGetStarted, isNotEmpty);
      expect(fr.onboardingSignIn, isNotEmpty);
      expect(fr.onboardingFlowQueued, isNotEmpty);
      expect(fr.offline, isNotEmpty);
      expect(fr.modules, isNotEmpty);
      expect(fr.saveChanges, isNotEmpty);
      expect(fr.next, isNotEmpty);
      expect(fr.skip, isNotEmpty);
      expect(fr.selectActiveModules, isNotEmpty);
      expect(fr.pharmacyLabel, isNotEmpty);
      expect(fr.businessNameLabel, isNotEmpty);
    });

    test('specific French values are correct', () {
      expect(fr.storeLabel, 'Magasin');
      expect(fr.itemLabel, 'Article');
      expect(fr.weekdays, 'Jours de la semaine');
      expect(fr.completeLabel, 'Terminé');
      expect(fr.doneLabel, 'Terminé');
      expect(fr.onboardingSignIn, 'Se connecter');
      expect(fr.edaLabProWelcomeTitle, 'Bienvenue');
      expect(fr.edaLabProWelcomeSignInButton, 'Se connecter');
      expect(fr.edaLabProWelcomeCreateAccountButton, 'Créer un compte');
    });

    test('French values contain accented characters where expected', () {
      // French should have diacritics in key words
      expect(fr.onboardingGetStarted, contains('Commencer'));
      expect(fr.edaLabProWelcomeCreateAccountButton, contains('é'));
      expect(fr.offline, contains('Hors ligne'));
    });
  });
}
