import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  /// No description provided for @moduleMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get moduleMessages;

  /// No description provided for @moduleOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get moduleOrders;

  /// No description provided for @moduleFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get moduleFood;

  /// No description provided for @moduleShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get moduleShopping;

  /// No description provided for @moduleGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get moduleGrocery;

  /// No description provided for @modulePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get modulePharmacy;

  /// No description provided for @moduleRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get moduleRide;

  /// No description provided for @moduleHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get moduleHotel;

  /// No description provided for @moduleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get moduleDoctor;

  /// No description provided for @moduleHomeServices.
  ///
  /// In en, this message translates to:
  /// **'Home Services'**
  String get moduleHomeServices;

  /// No description provided for @moduleLaundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get moduleLaundry;

  /// No description provided for @modulePromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get modulePromotions;

  /// No description provided for @moduleAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get moduleAccount;

  /// No description provided for @moduleSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get moduleSystem;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EdaLab Pro'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @messagesChatFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get messagesChatFallbackTitle;

  /// No description provided for @messagesTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messagesTypeMessage;

  /// No description provided for @doctorBookingNoContact.
  ///
  /// In en, this message translates to:
  /// **'No contact information available'**
  String get doctorBookingNoContact;

  /// No description provided for @doctorBookingCannotOpenContact.
  ///
  /// In en, this message translates to:
  /// **'Cannot open contact information'**
  String get doctorBookingCannotOpenContact;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'All Your Pro Operations, In One Place'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Manage appointments and accept service bookings from one polished workspace.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Accept Work Instantly And Keep Flowing'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Update availability, claim requests, and move jobs from queue to completion with fewer taps and smarter context.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Insight, Control, And Clear Next Actions'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'See performance snapshots, urgent priorities, and customer activity in real time so nothing slips through.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onboardingSignIn;

  /// No description provided for @edaLabProWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get edaLabProWelcomeTitle;

  /// No description provided for @edaLabProWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get edaLabProWelcomeDescription;

  /// No description provided for @edaLabProWelcomeSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get edaLabProWelcomeSignInButton;

  /// No description provided for @edaLabProWelcomeCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get edaLabProWelcomeCreateAccountButton;

  /// No description provided for @onboardingFlowQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get onboardingFlowQueued;

  /// No description provided for @onboardingFlowQueuedDetail.
  ///
  /// In en, this message translates to:
  /// **'8 incoming requests'**
  String get onboardingFlowQueuedDetail;

  /// No description provided for @onboardingFlowAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get onboardingFlowAssigned;

  /// No description provided for @onboardingFlowAssignedDetail.
  ///
  /// In en, this message translates to:
  /// **'Auto-routed by availability'**
  String get onboardingFlowAssignedDetail;

  /// No description provided for @onboardingFlowCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get onboardingFlowCompleted;

  /// No description provided for @onboardingFlowCompletedDetail.
  ///
  /// In en, this message translates to:
  /// **'Customers notified instantly'**
  String get onboardingFlowCompletedDetail;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro Sign In'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your dedicated pro account to continue managing your workspace.'**
  String get loginSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createProAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a pro account'**
  String get createProAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Pro Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your dedicated pro sign-in'**
  String get registerSubtitle;

  /// No description provided for @registerInfo.
  ///
  /// In en, this message translates to:
  /// **'This account is separate from the customer app and is used only for EdaLab Pro access.'**
  String get registerInfo;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameRequired;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get creatingAccount;

  /// No description provided for @proContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get proContinue;

  /// No description provided for @alreadyHaveProAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have a pro account? Sign in'**
  String get alreadyHaveProAccount;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join as a Professional'**
  String get signupTitle;

  /// No description provided for @signupInfo.
  ///
  /// In en, this message translates to:
  /// **'Create or sign in to a pro account first before setting up your workspace.'**
  String get signupInfo;

  /// No description provided for @goToProSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Pro Sign In'**
  String get goToProSignIn;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(Object email);

  /// No description provided for @signedInAsMessage.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}. Now choose the pro profile and modules you want to operate.'**
  String signedInAsMessage(Object email);

  /// No description provided for @creatingWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Creating your pro workspace...'**
  String get creatingWorkspace;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. {error}'**
  String signupFailed(Object error);

  /// No description provided for @chooseProfileType.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Profile Type'**
  String get chooseProfileType;

  /// No description provided for @selectActiveModules.
  ///
  /// In en, this message translates to:
  /// **'Select Active Modules'**
  String get selectActiveModules;

  /// No description provided for @providerInfo.
  ///
  /// In en, this message translates to:
  /// **'After sign-up, create your own service listing from Availability, then configure services offered, activity zone, booking modes, and hours in Schedule.'**
  String get providerInfo;

  /// No description provided for @doctorInfo.
  ///
  /// In en, this message translates to:
  /// **'After sign-up, you will configure your practice including clinic visits, telemedicine, and home care services.'**
  String get doctorInfo;

  /// No description provided for @businessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessNameLabel;

  /// No description provided for @businessNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the business, provider, clinic, fleet, or profile name'**
  String get businessNameHint;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// No description provided for @completeSignUp.
  ///
  /// In en, this message translates to:
  /// **'Complete Sign Up'**
  String get completeSignUp;

  /// No description provided for @profileTypeDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get profileTypeDoctor;

  /// No description provided for @profileTypeProvider.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get profileTypeProvider;

  /// No description provided for @profileTypeShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get profileTypeShop;

  /// No description provided for @profileTypeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get profileTypeDelivery;

  /// No description provided for @profileTypeRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get profileTypeRide;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @businessNameMinChars.
  ///
  /// In en, this message translates to:
  /// **'Business name must be at least 2 characters.'**
  String get businessNameMinChars;

  /// No description provided for @enableAtLeastOneModule.
  ///
  /// In en, this message translates to:
  /// **'Enable at least one module.'**
  String get enableAtLeastOneModule;

  /// No description provided for @profileSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile settings updated.'**
  String get profileSettingsUpdated;

  /// No description provided for @pharmacyBusinessConnected.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy business connected.'**
  String get pharmacyBusinessConnected;

  /// No description provided for @addAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Add at least one offered service.'**
  String get addAtLeastOneService;

  /// No description provided for @providerSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Provider settings updated.'**
  String get providerSettingsUpdated;

  /// No description provided for @laundryServiceNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Laundry service name must be valid.'**
  String get laundryServiceNameInvalid;

  /// No description provided for @priceMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than zero.'**
  String get priceMustBePositive;

  /// No description provided for @unitMinChars.
  ///
  /// In en, this message translates to:
  /// **'Unit must be at least 2 characters.'**
  String get unitMinChars;

  /// No description provided for @addItemCatalogEntry.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item catalog entry.'**
  String get addItemCatalogEntry;

  /// No description provided for @addPickupSlot.
  ///
  /// In en, this message translates to:
  /// **'Add at least one pickup slot.'**
  String get addPickupSlot;

  /// No description provided for @minNoticeHoursRange.
  ///
  /// In en, this message translates to:
  /// **'Min notice hours must be between 0 and 72.'**
  String get minNoticeHoursRange;

  /// No description provided for @maxAdvanceDaysRange.
  ///
  /// In en, this message translates to:
  /// **'Max advance days must be between 1 and 30.'**
  String get maxAdvanceDaysRange;

  /// No description provided for @taxRateRange.
  ///
  /// In en, this message translates to:
  /// **'Tax rate must be between 0 and 40.'**
  String get taxRateRange;

  /// No description provided for @deliveryFeeRange.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee must be between 0 and 100000.'**
  String get deliveryFeeRange;

  /// No description provided for @serviceEnabled.
  ///
  /// In en, this message translates to:
  /// **'Service enabled'**
  String get serviceEnabled;

  /// No description provided for @createProviderListing.
  ///
  /// In en, this message translates to:
  /// **'Create Provider Listing'**
  String get createProviderListing;

  /// No description provided for @addProviderListing.
  ///
  /// In en, this message translates to:
  /// **'Add Provider Listing'**
  String get addProviderListing;

  /// No description provided for @createLaundryService.
  ///
  /// In en, this message translates to:
  /// **'Create Laundry Service'**
  String get createLaundryService;

  /// No description provided for @addLaundryService.
  ///
  /// In en, this message translates to:
  /// **'Add laundry service'**
  String get addLaundryService;

  /// No description provided for @openDispatchQueue.
  ///
  /// In en, this message translates to:
  /// **'Open Dispatch Queue'**
  String get openDispatchQueue;

  /// No description provided for @openRideQueue.
  ///
  /// In en, this message translates to:
  /// **'Open Ride Queue'**
  String get openRideQueue;

  /// No description provided for @doctorProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Doctor profile updated.'**
  String get doctorProfileUpdated;

  /// No description provided for @locationServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Location / service area'**
  String get locationServiceArea;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response time'**
  String get responseTime;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @bookingModes.
  ///
  /// In en, this message translates to:
  /// **'Booking modes'**
  String get bookingModes;

  /// No description provided for @weekdaysHours.
  ///
  /// In en, this message translates to:
  /// **'Weekdays hours'**
  String get weekdaysHours;

  /// No description provided for @saturdayHours.
  ///
  /// In en, this message translates to:
  /// **'Saturday hours'**
  String get saturdayHours;

  /// No description provided for @sundayHours.
  ///
  /// In en, this message translates to:
  /// **'Sunday hours'**
  String get sundayHours;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get serviceName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @itemCatalog.
  ///
  /// In en, this message translates to:
  /// **'Item catalog'**
  String get itemCatalog;

  /// No description provided for @pickupSlots.
  ///
  /// In en, this message translates to:
  /// **'Pickup slots'**
  String get pickupSlots;

  /// No description provided for @turnaroundHours.
  ///
  /// In en, this message translates to:
  /// **'Turnaround (hrs)'**
  String get turnaroundHours;

  /// No description provided for @minNoticeHours.
  ///
  /// In en, this message translates to:
  /// **'Min notice (hrs)'**
  String get minNoticeHours;

  /// No description provided for @maxAdvanceDays.
  ///
  /// In en, this message translates to:
  /// **'Max advance (days)'**
  String get maxAdvanceDays;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax rate (%)'**
  String get taxRate;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @clinicOrServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Clinic or service area'**
  String get clinicOrServiceArea;

  /// No description provided for @enterValidRestaurantName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid restaurant name first.'**
  String get enterValidRestaurantName;

  /// No description provided for @connectRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Connect Restaurant'**
  String get connectRestaurant;

  /// No description provided for @editRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Edit Restaurant'**
  String get editRestaurant;

  /// No description provided for @restaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name'**
  String get restaurantName;

  /// No description provided for @cuisine.
  ///
  /// In en, this message translates to:
  /// **'Cuisine'**
  String get cuisine;

  /// No description provided for @cuisineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Djiboutian, Mixed, Seafood'**
  String get cuisineHint;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @uploadRestaurantImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Restaurant Image'**
  String get uploadRestaurantImage;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Save Restaurant'**
  String get saveRestaurant;

  /// No description provided for @restaurantConnectedProfile.
  ///
  /// In en, this message translates to:
  /// **'Restaurant connected to your profile.'**
  String get restaurantConnectedProfile;

  /// No description provided for @restaurantDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Restaurant details updated.'**
  String get restaurantDetailsUpdated;

  /// No description provided for @pharmacyBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy business name'**
  String get pharmacyBusinessName;

  /// No description provided for @enterValidPharmacyBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid pharmacy business name.'**
  String get enterValidPharmacyBusinessName;

  /// No description provided for @connectPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Connect Pharmacy'**
  String get connectPharmacy;

  /// No description provided for @enableServicesModule.
  ///
  /// In en, this message translates to:
  /// **'Enable Services module first to create a provider listing.'**
  String get enableServicesModule;

  /// No description provided for @connectPharmacyBusiness.
  ///
  /// In en, this message translates to:
  /// **'Connect Pharmacy Business'**
  String get connectPharmacyBusiness;

  /// No description provided for @updatePharmacyBusiness.
  ///
  /// In en, this message translates to:
  /// **'Update Pharmacy Business'**
  String get updatePharmacyBusiness;

  /// No description provided for @savePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Save Pharmacy'**
  String get savePharmacy;

  /// No description provided for @connectedBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Connected businesses: {businesses}'**
  String connectedBusinesses(Object businesses);

  /// No description provided for @deliveryRequestClaimed.
  ///
  /// In en, this message translates to:
  /// **'Delivery request claimed.'**
  String get deliveryRequestClaimed;

  /// No description provided for @rideRequestClaimed.
  ///
  /// In en, this message translates to:
  /// **'Ride request claimed.'**
  String get rideRequestClaimed;

  /// No description provided for @enableServicesModuleFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable Services module first to create a provider listing.'**
  String get enableServicesModuleFirst;

  /// No description provided for @enableLaundryModuleFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable Laundry module first to create a listing.'**
  String get enableLaundryModuleFirst;

  /// No description provided for @laundryServiceNameMustBeValid.
  ///
  /// In en, this message translates to:
  /// **'Laundry service name must be valid.'**
  String get laundryServiceNameMustBeValid;

  /// No description provided for @priceMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than zero.'**
  String get priceMustBeGreaterThanZero;

  /// No description provided for @unitMustBeAtLeast2Chars.
  ///
  /// In en, this message translates to:
  /// **'Unit must be at least 2 characters.'**
  String get unitMustBeAtLeast2Chars;

  /// No description provided for @addAtLeastOneItemCatalog.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item catalog entry.'**
  String get addAtLeastOneItemCatalog;

  /// No description provided for @addAtLeastOnePickupSlot.
  ///
  /// In en, this message translates to:
  /// **'Add at least one pickup slot.'**
  String get addAtLeastOnePickupSlot;

  /// No description provided for @minNoticeHoursBetween.
  ///
  /// In en, this message translates to:
  /// **'Min notice hours must be between 0 and 72.'**
  String get minNoticeHoursBetween;

  /// No description provided for @maxAdvanceDaysBetween.
  ///
  /// In en, this message translates to:
  /// **'Max advance days must be between 1 and 30.'**
  String get maxAdvanceDaysBetween;

  /// No description provided for @taxRateMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Tax rate must be between 0 and 40.'**
  String get taxRateMustBeBetween;

  /// No description provided for @roomCleaning.
  ///
  /// In en, this message translates to:
  /// **'Room Cleaning'**
  String get roomCleaning;

  /// No description provided for @floorCleaning.
  ///
  /// In en, this message translates to:
  /// **'Floor Cleaning'**
  String get floorCleaning;

  /// No description provided for @kitchenCleaning.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Cleaning'**
  String get kitchenCleaning;

  /// No description provided for @bathroomCleaning.
  ///
  /// In en, this message translates to:
  /// **'Bathroom Cleaning'**
  String get bathroomCleaning;

  /// No description provided for @dishes.
  ///
  /// In en, this message translates to:
  /// **'Dishes'**
  String get dishes;

  /// No description provided for @laundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get laundry;

  /// No description provided for @oneTimeJob.
  ///
  /// In en, this message translates to:
  /// **'One‑time job'**
  String get oneTimeJob;

  /// No description provided for @dailyRecurring.
  ///
  /// In en, this message translates to:
  /// **'Daily recurring'**
  String get dailyRecurring;

  /// No description provided for @weeklyRecurring.
  ///
  /// In en, this message translates to:
  /// **'Weekly recurring'**
  String get weeklyRecurring;

  /// No description provided for @shift2h.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get shift2h;

  /// No description provided for @shift4h.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get shift4h;

  /// No description provided for @shift8h.
  ///
  /// In en, this message translates to:
  /// **'8 hours'**
  String get shift8h;

  /// No description provided for @within30Min.
  ///
  /// In en, this message translates to:
  /// **'Within 30 min'**
  String get within30Min;

  /// No description provided for @scheduledSlot.
  ///
  /// In en, this message translates to:
  /// **'Scheduled slot'**
  String get scheduledSlot;

  /// No description provided for @f2.
  ///
  /// In en, this message translates to:
  /// **'F2'**
  String get f2;

  /// No description provided for @f3.
  ///
  /// In en, this message translates to:
  /// **'F3'**
  String get f3;

  /// No description provided for @f4.
  ///
  /// In en, this message translates to:
  /// **'F4'**
  String get f4;

  /// No description provided for @providerSupplies.
  ///
  /// In en, this message translates to:
  /// **'Provider supplies'**
  String get providerSupplies;

  /// No description provided for @customerSupplies.
  ///
  /// In en, this message translates to:
  /// **'Customer supplies'**
  String get customerSupplies;

  /// No description provided for @deliveryFeeMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee must be between 0 and 100000.'**
  String get deliveryFeeMustBeBetween;

  /// No description provided for @storefrontSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Storefront Snapshot'**
  String get storefrontSnapshot;

  /// No description provided for @snapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get snapshot;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @pharmacyBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Businesses'**
  String get pharmacyBusinesses;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @providerSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Provider Snapshot'**
  String get providerSnapshot;

  /// No description provided for @serviceListings.
  ///
  /// In en, this message translates to:
  /// **'Service Listings'**
  String get serviceListings;

  /// No description provided for @laundryListings.
  ///
  /// In en, this message translates to:
  /// **'Laundry Listings'**
  String get laundryListings;

  /// No description provided for @listingsWithLocation.
  ///
  /// In en, this message translates to:
  /// **'Listings With Location'**
  String get listingsWithLocation;

  /// No description provided for @enabledModules.
  ///
  /// In en, this message translates to:
  /// **'Enabled Modules'**
  String get enabledModules;

  /// No description provided for @doctorSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Doctor Snapshot'**
  String get doctorSnapshot;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @profilesWithLocation.
  ///
  /// In en, this message translates to:
  /// **'Profiles With Location'**
  String get profilesWithLocation;

  /// No description provided for @careModes.
  ///
  /// In en, this message translates to:
  /// **'Care Modes'**
  String get careModes;

  /// No description provided for @dispatchSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Dispatch snapshot'**
  String get dispatchSnapshot;

  /// No description provided for @dispatchSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage dispatch profile operations and online status.'**
  String get dispatchSnapshotSubtitle;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @deliveryModules.
  ///
  /// In en, this message translates to:
  /// **'Delivery Modules'**
  String get deliveryModules;

  /// No description provided for @businessNameLength.
  ///
  /// In en, this message translates to:
  /// **'Business Name Length'**
  String get businessNameLength;

  /// No description provided for @riderSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Rider Snapshot'**
  String get riderSnapshot;

  /// No description provided for @riderSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage rider profile operations and trip availability.'**
  String get riderSnapshotSubtitle;

  /// No description provided for @rideModules.
  ///
  /// In en, this message translates to:
  /// **'Ride Modules'**
  String get rideModules;

  /// No description provided for @profileSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Profile Snapshot'**
  String get profileSnapshot;

  /// No description provided for @temporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get temporarilyUnavailable;

  /// No description provided for @storefrontSetup.
  ///
  /// In en, this message translates to:
  /// **'Storefront Setup'**
  String get storefrontSetup;

  /// No description provided for @storefrontSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage store name, description, and storefront image.'**
  String get storefrontSetupSubtitle;

  /// No description provided for @productsMedicines.
  ///
  /// In en, this message translates to:
  /// **'Products & Medicines'**
  String get productsMedicines;

  /// No description provided for @productsMedicinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage shopping products and pharmacy medicine catalog.'**
  String get productsMedicinesSubtitle;

  /// No description provided for @ordersQueue.
  ///
  /// In en, this message translates to:
  /// **'Orders Queue'**
  String get ordersQueue;

  /// No description provided for @ordersQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor all incoming orders by module lane.'**
  String get ordersQueueSubtitle;

  /// No description provided for @serviceAndLaundryProfiles.
  ///
  /// In en, this message translates to:
  /// **'Service & Laundry Profiles'**
  String get serviceAndLaundryProfiles;

  /// No description provided for @serviceAndLaundryProfilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, configure, and manage service or laundry listings.'**
  String get serviceAndLaundryProfilesSubtitle;

  /// No description provided for @scheduleAndBookingModes.
  ///
  /// In en, this message translates to:
  /// **'Schedule & Booking Modes'**
  String get scheduleAndBookingModes;

  /// No description provided for @scheduleAndBookingModesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage provider schedule and booking preferences.'**
  String get scheduleAndBookingModesSubtitle;

  /// No description provided for @jobsQueue.
  ///
  /// In en, this message translates to:
  /// **'Available missions'**
  String get jobsQueue;

  /// No description provided for @jobsQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track active and pending provider service jobs.'**
  String get jobsQueueSubtitle;

  /// No description provided for @doctorDetails.
  ///
  /// In en, this message translates to:
  /// **'Doctor Details'**
  String get doctorDetails;

  /// No description provided for @doctorDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure doctor profiles and consultation readiness.'**
  String get doctorDetailsSubtitle;

  /// No description provided for @doctorAvailability.
  ///
  /// In en, this message translates to:
  /// **'Doctor Availability'**
  String get doctorAvailability;

  /// No description provided for @doctorAvailabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control who is accepting consultations right now.'**
  String get doctorAvailabilitySubtitle;

  /// No description provided for @appointmentsQueue.
  ///
  /// In en, this message translates to:
  /// **'Appointments Queue'**
  String get appointmentsQueue;

  /// No description provided for @appointmentsQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review appointments and home-care requests.'**
  String get appointmentsQueueSubtitle;

  /// No description provided for @dispatchQueue.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Queue'**
  String get dispatchQueue;

  /// No description provided for @dispatchQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open delivery dispatch and claim jobs.'**
  String get dispatchQueueSubtitle;

  /// No description provided for @rideQueue.
  ///
  /// In en, this message translates to:
  /// **'Ride Queue'**
  String get rideQueue;

  /// No description provided for @rideQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open trip requests and assigned rides.'**
  String get rideQueueSubtitle;

  /// No description provided for @profileManagement.
  ///
  /// In en, this message translates to:
  /// **'Profile Management'**
  String get profileManagement;

  /// No description provided for @shopProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Shop Profile Details'**
  String get shopProfileDetails;

  /// No description provided for @providerProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Provider Profile Details'**
  String get providerProfileDetails;

  /// No description provided for @laundryProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Laundry Profile Details'**
  String get laundryProfileDetails;

  /// No description provided for @doctorProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile Details'**
  String get doctorProfileDetails;

  /// No description provided for @deliveryProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Profile Details'**
  String get deliveryProfileDetails;

  /// No description provided for @riderProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Rider Profile Details'**
  String get riderProfileDetails;

  /// No description provided for @profileFrontendSections.
  ///
  /// In en, this message translates to:
  /// **'Profile Frontend Sections'**
  String get profileFrontendSections;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @businessNameOnly.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessNameOnly;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @contactSupportWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Contact Support on WhatsApp'**
  String get contactSupportWhatsApp;

  /// No description provided for @noProProfileFound.
  ///
  /// In en, this message translates to:
  /// **'No Pro Profile found.'**
  String get noProProfileFound;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @ordersQueueNav.
  ///
  /// In en, this message translates to:
  /// **'Orders Queue'**
  String get ordersQueueNav;

  /// No description provided for @storeSetup.
  ///
  /// In en, this message translates to:
  /// **'Store Setup'**
  String get storeSetup;

  /// No description provided for @storeSetupNav.
  ///
  /// In en, this message translates to:
  /// **'Store Setup'**
  String get storeSetupNav;

  /// No description provided for @productsManager.
  ///
  /// In en, this message translates to:
  /// **'Products Manager'**
  String get productsManager;

  /// No description provided for @shoppingLane.
  ///
  /// In en, this message translates to:
  /// **'Shopping Lane'**
  String get shoppingLane;

  /// No description provided for @shoppingLaneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Focus only on your retail orders and fulfillment.'**
  String get shoppingLaneSubtitle;

  /// No description provided for @foodLane.
  ///
  /// In en, this message translates to:
  /// **'Food Lane'**
  String get foodLane;

  /// No description provided for @foodLaneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Focus only on your kitchen queue and prep flow.'**
  String get foodLaneSubtitle;

  /// No description provided for @pharmacyLane.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Lane'**
  String get pharmacyLane;

  /// No description provided for @pharmacyLaneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Focus only on your pharmacy orders and fulfillment.'**
  String get pharmacyLaneSubtitle;

  /// No description provided for @goOnlineBeforeClaiming.
  ///
  /// In en, this message translates to:
  /// **'Go online before claiming deliveries.'**
  String get goOnlineBeforeClaiming;

  /// No description provided for @deliveryRequestClaimedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Delivery request claimed successfully.'**
  String get deliveryRequestClaimedSuccessfully;

  /// No description provided for @couldNotClaimDelivery.
  ///
  /// In en, this message translates to:
  /// **'Could not claim delivery: {error}'**
  String couldNotClaimDelivery(Object error);

  /// No description provided for @priorityDispatch.
  ///
  /// In en, this message translates to:
  /// **'Priority Dispatch'**
  String get priorityDispatch;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @completeLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @selectPharmacyFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a pharmacy first.'**
  String get selectPharmacyFirst;

  /// No description provided for @selectStoreFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a store first.'**
  String get selectStoreFirst;

  /// No description provided for @medicineAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Medicine added successfully!'**
  String get medicineAddedSuccessfully;

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAddedSuccessfully;

  /// No description provided for @basicDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetailsLabel;

  /// No description provided for @basicDetailsMedicineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic information about the medicine'**
  String get basicDetailsMedicineSubtitle;

  /// No description provided for @basicDetailsProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic information about the product'**
  String get basicDetailsProductSubtitle;

  /// No description provided for @storeLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeLabel;

  /// No description provided for @pharmacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacyLabel;

  /// No description provided for @enterCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid category (min 2 chars).'**
  String get enterCategoryError;

  /// No description provided for @enterNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name (min 2 chars).'**
  String get enterNameError;

  /// No description provided for @labBrandOptional.
  ///
  /// In en, this message translates to:
  /// **'Laboratory/Brand (Optional)'**
  String get labBrandOptional;

  /// No description provided for @brandOptional.
  ///
  /// In en, this message translates to:
  /// **'Brand (Optional)'**
  String get brandOptional;

  /// No description provided for @enterDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid description (min 4 chars).'**
  String get enterDescriptionError;

  /// No description provided for @medicalSpecificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical Specification'**
  String get medicalSpecificationLabel;

  /// No description provided for @dosageOptional.
  ///
  /// In en, this message translates to:
  /// **'Dosage (Optional)'**
  String get dosageOptional;

  /// No description provided for @packageSizeOptional.
  ///
  /// In en, this message translates to:
  /// **'Package Size (Optional)'**
  String get packageSizeOptional;

  /// No description provided for @pricingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Fulfillment'**
  String get pricingLabel;

  /// No description provided for @enterValidPriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price.'**
  String get enterValidPriceError;

  /// No description provided for @originalPriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Original Price (Optional)'**
  String get originalPriceOptional;

  /// No description provided for @unitOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit (Optional)'**
  String get unitOptional;

  /// No description provided for @pharmacyUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., box, bottle, strip'**
  String get pharmacyUnitHint;

  /// No description provided for @shoppingUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., piece, kg, pack'**
  String get shoppingUnitHint;

  /// No description provided for @badgeOptional.
  ///
  /// In en, this message translates to:
  /// **'Badge (Optional)'**
  String get badgeOptional;

  /// No description provided for @badgeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., New, Sale, Limited'**
  String get badgeHint;

  /// No description provided for @mediaAttributesLabel.
  ///
  /// In en, this message translates to:
  /// **'Media & Attributes'**
  String get mediaAttributesLabel;

  /// No description provided for @mediaAttributesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visuals and additional product data'**
  String get mediaAttributesSubtitle;

  /// No description provided for @primaryImageURL.
  ///
  /// In en, this message translates to:
  /// **'Primary Image URL'**
  String get primaryImageURL;

  /// No description provided for @galleryImageURLs.
  ///
  /// In en, this message translates to:
  /// **'Gallery Image URLs (New line separated)'**
  String get galleryImageURLs;

  /// No description provided for @galleryURLsHint.
  ///
  /// In en, this message translates to:
  /// **'https://...\\nhttps://...'**
  String get galleryURLsHint;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabel;

  /// No description provided for @dispatchLanes.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Lanes'**
  String get dispatchLanes;

  /// No description provided for @openFullQueue.
  ///
  /// In en, this message translates to:
  /// **'Open Full Queue'**
  String get openFullQueue;

  /// No description provided for @dispatchLanesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run shopping, food, and pharmacy dispatch from one board.'**
  String get dispatchLanesSubtitle;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @zones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get zones;

  /// No description provided for @noActiveDispatchLanes.
  ///
  /// In en, this message translates to:
  /// **'No active dispatch lanes yet. New requests will appear here.'**
  String get noActiveDispatchLanes;

  /// No description provided for @updateQueueStatus.
  ///
  /// In en, this message translates to:
  /// **'Order updated to {status}.'**
  String updateQueueStatus(Object status);

  /// No description provided for @queueLabel.
  ///
  /// In en, this message translates to:
  /// **'{businessName} Queue'**
  String queueLabel(Object businessName);

  /// No description provided for @moduleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get moduleActive;

  /// No description provided for @moduleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get moduleCompleted;

  /// No description provided for @moduleCount.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get moduleCount;

  /// No description provided for @loadingOrderQueue.
  ///
  /// In en, this message translates to:
  /// **'Loading order queue...'**
  String get loadingOrderQueue;

  /// No description provided for @noOrdersMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No orders match the current queue filters.'**
  String get noOrdersMatchFilters;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @moduleOrder.
  ///
  /// In en, this message translates to:
  /// **'{module} order'**
  String moduleOrder(Object module);

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @viewRx.
  ///
  /// In en, this message translates to:
  /// **'View Rx'**
  String get viewRx;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutQuestion;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from your pro account'**
  String get signOutSubtitle;

  /// No description provided for @managementTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Management'**
  String get managementTitle;

  /// No description provided for @managementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage profile, modules, and listings.'**
  String get managementSubtitle;

  /// No description provided for @moduleAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Module Access'**
  String get moduleAccessTitle;

  /// No description provided for @moduleAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active modules and features available to you.'**
  String get moduleAccessSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @providerAvailability.
  ///
  /// In en, this message translates to:
  /// **'Provider Availability'**
  String get providerAvailability;

  /// No description provided for @providerAvailabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pause or reopen service and laundry lanes.'**
  String get providerAvailabilitySubtitle;

  /// No description provided for @schedulingSettings.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedulingSettings;

  /// No description provided for @schedulingSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your available slots'**
  String get schedulingSettingsSubtitle;

  /// No description provided for @scheduleSettings.
  ///
  /// In en, this message translates to:
  /// **'Schedule Settings'**
  String get scheduleSettings;

  /// No description provided for @scheduleSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update working hours and care modes.'**
  String get scheduleSettingsSubtitle;

  /// No description provided for @waitForImageUploads.
  ///
  /// In en, this message translates to:
  /// **'Please wait for image uploads to complete.'**
  String get waitForImageUploads;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic details'**
  String get basicDetails;

  /// No description provided for @basicDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, module, and type.'**
  String get basicDetailsSubtitle;

  /// No description provided for @medicalSpecification.
  ///
  /// In en, this message translates to:
  /// **'Medical specification'**
  String get medicalSpecification;

  /// No description provided for @medicalSpecificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dosage and prescription requirements'**
  String get medicalSpecificationSubtitle;

  /// No description provided for @requiresPrescription.
  ///
  /// In en, this message translates to:
  /// **'Requires Prescription'**
  String get requiresPrescription;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @pricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your price and inventory details'**
  String get pricingSubtitle;

  /// No description provided for @mediaAndAttributes.
  ///
  /// In en, this message translates to:
  /// **'Media and attributes'**
  String get mediaAndAttributes;

  /// No description provided for @mediaAndAttributesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Images and metadata.'**
  String get mediaAndAttributesSubtitle;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get availability;

  /// No description provided for @availabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control product visibility in your store'**
  String get availabilitySubtitle;

  /// No description provided for @markAsOrganic.
  ///
  /// In en, this message translates to:
  /// **'Mark as Organic'**
  String get markAsOrganic;

  /// No description provided for @availableInStock.
  ///
  /// In en, this message translates to:
  /// **'Available in stock'**
  String get availableInStock;

  /// No description provided for @createStoreFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a store first before adding products.'**
  String get createStoreFirst;

  /// No description provided for @pharmacyBusinessConnectedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy business connected to your profile.'**
  String get pharmacyBusinessConnectedToProfile;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @openQueue.
  ///
  /// In en, this message translates to:
  /// **'Open Queue'**
  String get openQueue;

  /// No description provided for @storeSetupNav2.
  ///
  /// In en, this message translates to:
  /// **'Store Setup'**
  String get storeSetupNav2;

  /// No description provided for @configureFrontend.
  ///
  /// In en, this message translates to:
  /// **'Configure storefront identity and availability.'**
  String get configureFrontend;

  /// No description provided for @productsNav.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsNav;

  /// No description provided for @manageCatalog.
  ///
  /// In en, this message translates to:
  /// **'Manage products and stock across your stores.'**
  String get manageCatalog;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @wasPrice.
  ///
  /// In en, this message translates to:
  /// **'was {price}'**
  String wasPrice(Object price);

  /// No description provided for @dispatchNav.
  ///
  /// In en, this message translates to:
  /// **'{businessName} Dispatch'**
  String dispatchNav(Object businessName);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @lanes.
  ///
  /// In en, this message translates to:
  /// **'Lanes'**
  String get lanes;

  /// No description provided for @loadingDispatchQueue.
  ///
  /// In en, this message translates to:
  /// **'Loading dispatch queue...'**
  String get loadingDispatchQueue;

  /// No description provided for @moduleDelivery.
  ///
  /// In en, this message translates to:
  /// **'{module} delivery'**
  String moduleDelivery(Object module);

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Account pending verification'**
  String get pendingVerification;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your account. This may take 24-48 hours.'**
  String get verificationInProgress;

  /// No description provided for @pendingVerificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Your pro account is under review. We\'re verifying your business details and documents.'**
  String get pendingVerificationDetails;

  /// No description provided for @notPreviouslyApproved.
  ///
  /// In en, this message translates to:
  /// **'Not Previously Approved'**
  String get notPreviouslyApproved;

  /// No description provided for @previouslyApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account was approved before. Contact support to know more.'**
  String get previouslyApprovedMessage;

  /// No description provided for @liveInsights.
  ///
  /// In en, this message translates to:
  /// **'Live Insights'**
  String get liveInsights;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @responseValue.
  ///
  /// In en, this message translates to:
  /// **'4.2m'**
  String get responseValue;

  /// No description provided for @sla.
  ///
  /// In en, this message translates to:
  /// **'SLA'**
  String get sla;

  /// No description provided for @slaValue.
  ///
  /// In en, this message translates to:
  /// **'96%'**
  String get slaValue;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @resolvedValue.
  ///
  /// In en, this message translates to:
  /// **'41'**
  String get resolvedValue;

  /// No description provided for @urgent3.
  ///
  /// In en, this message translates to:
  /// **'Urgent 3'**
  String get urgent3;

  /// No description provided for @shoppingStoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Shopping Store Profile'**
  String get shoppingStoreProfile;

  /// No description provided for @restaurantProfile.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Profile'**
  String get restaurantProfile;

  /// No description provided for @pharmacyProfile.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Profile'**
  String get pharmacyProfile;

  /// No description provided for @openDispatchQueueNav.
  ///
  /// In en, this message translates to:
  /// **'Open Dispatch Queue'**
  String get openDispatchQueueNav;

  /// No description provided for @orderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order updated to {status}.'**
  String orderUpdated(Object status);

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @out.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get out;

  /// No description provided for @verificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPendingTitle;

  /// No description provided for @verificationPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is under verification'**
  String get verificationPendingSubtitle;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountTypeLabel;

  /// No description provided for @whatsHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get whatsHappening;

  /// No description provided for @verificationDescription.
  ///
  /// In en, this message translates to:
  /// **'We are verifying your business details and documents to ensure the safety and quality of our platform. This typically takes 24-48 hours.'**
  String get verificationDescription;

  /// No description provided for @available247.
  ///
  /// In en, this message translates to:
  /// **'Available 24/7'**
  String get available247;

  /// No description provided for @goOnlineBeforeClaimingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Go online before claiming deliveries.'**
  String get goOnlineBeforeClaimingDeliveries;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @urgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentLabel;

  /// No description provided for @zonesLabel.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get zonesLabel;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offlineStatus;

  /// No description provided for @storeManagement.
  ///
  /// In en, this message translates to:
  /// **'Store Management'**
  String get storeManagement;

  /// No description provided for @serviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Service Management'**
  String get serviceManagement;

  /// No description provided for @clinicManagement.
  ///
  /// In en, this message translates to:
  /// **'Clinic Management'**
  String get clinicManagement;

  /// No description provided for @dispatchManagement.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Management'**
  String get dispatchManagement;

  /// No description provided for @tripManagement.
  ///
  /// In en, this message translates to:
  /// **'Trip Management'**
  String get tripManagement;

  /// No description provided for @storeLanes.
  ///
  /// In en, this message translates to:
  /// **'Store Lanes'**
  String get storeLanes;

  /// No description provided for @serviceLanes.
  ///
  /// In en, this message translates to:
  /// **'Service Lanes'**
  String get serviceLanes;

  /// No description provided for @careLanes.
  ///
  /// In en, this message translates to:
  /// **'Care Lanes'**
  String get careLanes;

  /// No description provided for @deliveryLanes.
  ///
  /// In en, this message translates to:
  /// **'Delivery Lanes'**
  String get deliveryLanes;

  /// No description provided for @rideLanes.
  ///
  /// In en, this message translates to:
  /// **'Ride lanes'**
  String get rideLanes;

  /// No description provided for @verifiedAccount.
  ///
  /// In en, this message translates to:
  /// **'✓ Verified account'**
  String get verifiedAccount;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'⏳ Verification pending'**
  String get verificationPending;

  /// No description provided for @workspaceId.
  ///
  /// In en, this message translates to:
  /// **'Workspace ID: {id}'**
  String workspaceId(Object id);

  /// No description provided for @profileManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage business name, modules, and profile frontend sections.'**
  String get profileManagementSubtitle;

  /// No description provided for @storeSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your public storefront details. This setup is used by customers when browsing your store.'**
  String get storeSetupSubtitle;

  /// No description provided for @productsManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage products and stock across your stores.'**
  String get productsManagerSubtitle;

  /// No description provided for @storeOwnerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Store owner workspace'**
  String get storeOwnerWorkspace;

  /// No description provided for @serviceOperatorWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Service operator workspace'**
  String get serviceOperatorWorkspace;

  /// No description provided for @clinicalWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Clinical workspace'**
  String get clinicalWorkspace;

  /// No description provided for @dispatchPartnerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Dispatch partner workspace'**
  String get dispatchPartnerWorkspace;

  /// No description provided for @ridePartnerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Ride partner workspace'**
  String get ridePartnerWorkspace;

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutDialogTitle;

  /// No description provided for @signOutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out? You will need to log in again to access your pro account.'**
  String get signOutDialogContent;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @receiveDispatchWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Receive dispatch work when online.'**
  String get receiveDispatchWhenOnline;

  /// No description provided for @receiveRideWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Receive ride requests when online.'**
  String get receiveRideWhenOnline;

  /// No description provided for @offlineButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineButtonLabel;

  /// No description provided for @claimingButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Claiming...'**
  String get claimingButtonLabel;

  /// No description provided for @runDeliveryOperations.
  ///
  /// In en, this message translates to:
  /// **'Run shopping, food, and pharmacy dispatch from one board.'**
  String get runDeliveryOperations;

  /// No description provided for @liveOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Live Orders'**
  String get liveOrdersLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @stockAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock Alerts'**
  String get stockAlertsLabel;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @assignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedLabel;

  /// No description provided for @lanesLabel.
  ///
  /// In en, this message translates to:
  /// **'Lanes'**
  String get lanesLabel;

  /// No description provided for @openRequestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Requests'**
  String get openRequestsLabel;

  /// No description provided for @assignedToMeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned To Me'**
  String get assignedToMeLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @shoppingLabel.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shoppingLabel;

  /// No description provided for @foodLabel.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodLabel;

  /// No description provided for @saveProviderSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Provider Settings'**
  String get saveProviderSettings;

  /// No description provided for @saveLaundryService.
  ///
  /// In en, this message translates to:
  /// **'Save Laundry Service'**
  String get saveLaundryService;

  /// No description provided for @saveDoctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Doctor Profile'**
  String get saveDoctorProfile;

  /// No description provided for @nameShownToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Name shown to customers across enabled modules'**
  String get nameShownToCustomers;

  /// No description provided for @enabledModulesLower.
  ///
  /// In en, this message translates to:
  /// **'Enabled modules'**
  String get enabledModulesLower;

  /// No description provided for @manageProProfileIdentity.
  ///
  /// In en, this message translates to:
  /// **'Manage pro profile identity, module access, and frontend profile sections from one place.'**
  String get manageProProfileIdentity;

  /// No description provided for @atLeastOneModuleMustStayEnabled.
  ///
  /// In en, this message translates to:
  /// **'At least one module must stay enabled.'**
  String get atLeastOneModuleMustStayEnabled;

  /// No description provided for @couldNotLoadProfileInsights.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile insights.'**
  String get couldNotLoadProfileInsights;

  /// No description provided for @couldNotLoadShopProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load shop profile details.'**
  String get couldNotLoadShopProfileDetails;

  /// No description provided for @editStoreNameTaglineDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit store name, tagline, description, and image.'**
  String get editStoreNameTaglineDescription;

  /// No description provided for @cuisinePrefix.
  ///
  /// In en, this message translates to:
  /// **'Cuisine: {cuisine}'**
  String cuisinePrefix(Object cuisine);

  /// No description provided for @editRestaurantNameCuisineImage.
  ///
  /// In en, this message translates to:
  /// **'Edit restaurant name, cuisine, and image.'**
  String get editRestaurantNameCuisineImage;

  /// No description provided for @pharmacyBusinessesConnected.
  ///
  /// In en, this message translates to:
  /// **'{count} businesses connected'**
  String pharmacyBusinessesConnected(Object count);

  /// No description provided for @editPharmacyBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Edit pharmacy business name for pharmacy listings.'**
  String get editPharmacyBusinessName;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @couldNotLoadProviderProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load provider profile details.'**
  String get couldNotLoadProviderProfileDetails;

  /// No description provided for @noProviderListingLinkedYet.
  ///
  /// In en, this message translates to:
  /// **'No provider listing is linked yet.'**
  String get noProviderListingLinkedYet;

  /// No description provided for @enableServicesModuleToCreateOne.
  ///
  /// In en, this message translates to:
  /// **'Enable Services module to create one.'**
  String get enableServicesModuleToCreateOne;

  /// No description provided for @servicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} services'**
  String servicesCount(Object count);

  /// No description provided for @couldNotLoadLaundryProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load laundry profile details.'**
  String get couldNotLoadLaundryProfileDetails;

  /// No description provided for @noLaundryServiceListingYet.
  ///
  /// In en, this message translates to:
  /// **'No laundry service listing yet.'**
  String get noLaundryServiceListingYet;

  /// No description provided for @laundryModuleNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Laundry module is not enabled for this profile.'**
  String get laundryModuleNotEnabled;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(Object count);

  /// No description provided for @slotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} slots'**
  String slotsCount(Object count);

  /// No description provided for @couldNotLoadDoctorProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load doctor profile details.'**
  String get couldNotLoadDoctorProfileDetails;

  /// No description provided for @noDoctorProfileBound.
  ///
  /// In en, this message translates to:
  /// **'No doctor profile is currently bound to this pro account. Update the business name or use schedule tools to sync doctor binding.'**
  String get noDoctorProfileBound;

  /// No description provided for @generalPractice.
  ///
  /// In en, this message translates to:
  /// **'General Practice'**
  String get generalPractice;

  /// No description provided for @couldNotLoadDispatchProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load dispatch profile details.'**
  String get couldNotLoadDispatchProfileDetails;

  /// No description provided for @openRequests.
  ///
  /// In en, this message translates to:
  /// **'Open Requests'**
  String get openRequests;

  /// No description provided for @couldNotLoadRiderProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load rider profile details.'**
  String get couldNotLoadRiderProfileDetails;

  /// No description provided for @rideSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Ride snapshot'**
  String get rideSnapshot;

  /// No description provided for @liveTrips.
  ///
  /// In en, this message translates to:
  /// **'Live trips'**
  String get liveTrips;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @providerListing.
  ///
  /// In en, this message translates to:
  /// **'Provider listing'**
  String get providerListing;

  /// No description provided for @providerProfile.
  ///
  /// In en, this message translates to:
  /// **'Provider profile'**
  String get providerProfile;

  /// No description provided for @laundryService.
  ///
  /// In en, this message translates to:
  /// **'Laundry Service'**
  String get laundryService;

  /// No description provided for @deliveryRequest.
  ///
  /// In en, this message translates to:
  /// **'Delivery request'**
  String get deliveryRequest;

  /// No description provided for @rideRequest.
  ///
  /// In en, this message translates to:
  /// **'Ride request'**
  String get rideRequest;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @editProviderProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Provider Profile'**
  String get editProviderProfile;

  /// No description provided for @commaOrNewlineSeparated.
  ///
  /// In en, this message translates to:
  /// **'Comma or newline separated'**
  String get commaOrNewlineSeparated;

  /// No description provided for @bookingModesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home Visit, Scheduled Slot'**
  String get bookingModesHint;

  /// No description provided for @washAndFold.
  ///
  /// In en, this message translates to:
  /// **'Wash & Fold'**
  String get washAndFold;

  /// No description provided for @shirt.
  ///
  /// In en, this message translates to:
  /// **'Shirt'**
  String get shirt;

  /// No description provided for @tShirt.
  ///
  /// In en, this message translates to:
  /// **'T-Shirt'**
  String get tShirt;

  /// No description provided for @polo.
  ///
  /// In en, this message translates to:
  /// **'Polo'**
  String get polo;

  /// No description provided for @trouser.
  ///
  /// In en, this message translates to:
  /// **'Trouser'**
  String get trouser;

  /// No description provided for @blazer.
  ///
  /// In en, this message translates to:
  /// **'Blazer'**
  String get blazer;

  /// No description provided for @suit2Pieces.
  ///
  /// In en, this message translates to:
  /// **'Suit 2 Pieces'**
  String get suit2Pieces;

  /// No description provided for @suit3Pieces.
  ///
  /// In en, this message translates to:
  /// **'Suit 3 Pieces'**
  String get suit3Pieces;

  /// No description provided for @jacket.
  ///
  /// In en, this message translates to:
  /// **'Jacket'**
  String get jacket;

  /// No description provided for @dress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get dress;

  /// No description provided for @washAndFold1020Pieces.
  ///
  /// In en, this message translates to:
  /// **'Wash & Fold 10-20 Pieces'**
  String get washAndFold1020Pieces;

  /// No description provided for @washAndFold2130Pieces.
  ///
  /// In en, this message translates to:
  /// **'Wash & Fold 21-30 Pieces'**
  String get washAndFold2130Pieces;

  /// No description provided for @washAndFold3140Pieces.
  ///
  /// In en, this message translates to:
  /// **'Wash & Fold 31-40 Pieces'**
  String get washAndFold3140Pieces;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @invalidItemCatalogLine.
  ///
  /// In en, this message translates to:
  /// **'Invalid item catalog line: \"{line}\". Use label|price|category|spec.'**
  String invalidItemCatalogLine(Object line);

  /// No description provided for @invalidItemCatalogRequired.
  ///
  /// In en, this message translates to:
  /// **'Invalid item catalog line: \"{line}\". Label and price are required.'**
  String invalidItemCatalogRequired(Object line);

  /// No description provided for @groupItemNeedsSpec.
  ///
  /// In en, this message translates to:
  /// **'Group item \"{label}\" needs a spec (4th value).'**
  String groupItemNeedsSpec(Object label);

  /// No description provided for @turnaroundHoursRange.
  ///
  /// In en, this message translates to:
  /// **'Turnaround hours must be between 1 and 168.'**
  String get turnaroundHoursRange;

  /// No description provided for @laundryServiceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Laundry service updated.'**
  String get laundryServiceUpdated;

  /// No description provided for @laundryServiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Laundry service created.'**
  String get laundryServiceCreated;

  /// No description provided for @editLaundryService.
  ///
  /// In en, this message translates to:
  /// **'Edit Laundry Service'**
  String get editLaundryService;

  /// No description provided for @itemCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'One per line: label|price|category|spec\ncategory: unit or group'**
  String get itemCatalogHint;

  /// No description provided for @editDoctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Doctor Profile'**
  String get editDoctorProfile;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @careModesLabel.
  ///
  /// In en, this message translates to:
  /// **'Care modes'**
  String get careModesLabel;

  /// No description provided for @weekdaysHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekdays hours'**
  String get weekdaysHoursLabel;

  /// No description provided for @saturdayHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturday hours'**
  String get saturdayHoursLabel;

  /// No description provided for @sundayHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunday hours'**
  String get sundayHoursLabel;

  /// No description provided for @uploadDoctorImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Doctor Image'**
  String get uploadDoctorImage;

  /// No description provided for @storefrontSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage storefront profile data for shopping, food, and pharmacy lanes.'**
  String get storefrontSnapshotSubtitle;

  /// No description provided for @providerSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service and laundry listings connected to this provider profile.'**
  String get providerSnapshotSubtitle;

  /// No description provided for @doctorSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consultation profile details currently active for this doctor account.'**
  String get doctorSnapshotSubtitle;

  /// No description provided for @couldNotLoadLiveProfileInsights.
  ///
  /// In en, this message translates to:
  /// **'Could not load live profile insights right now. You can still update profile settings below.'**
  String get couldNotLoadLiveProfileInsights;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @uploadServiceImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Service Image'**
  String get uploadServiceImage;

  /// No description provided for @storeControls.
  ///
  /// In en, this message translates to:
  /// **'Store Controls'**
  String get storeControls;

  /// No description provided for @serviceControls.
  ///
  /// In en, this message translates to:
  /// **'Service Controls'**
  String get serviceControls;

  /// No description provided for @clinicalControls.
  ///
  /// In en, this message translates to:
  /// **'Clinical Controls'**
  String get clinicalControls;

  /// No description provided for @dispatchControls.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Controls'**
  String get dispatchControls;

  /// No description provided for @tripControls.
  ///
  /// In en, this message translates to:
  /// **'Trip Controls'**
  String get tripControls;

  /// No description provided for @storeModules.
  ///
  /// In en, this message translates to:
  /// **'Store Modules'**
  String get storeModules;

  /// No description provided for @serviceWorkstreams.
  ///
  /// In en, this message translates to:
  /// **'Service Workstreams'**
  String get serviceWorkstreams;

  /// No description provided for @consultationWorkstreams.
  ///
  /// In en, this message translates to:
  /// **'Consultation Workstreams'**
  String get consultationWorkstreams;

  /// No description provided for @dispatchWorkstreams.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Workstreams'**
  String get dispatchWorkstreams;

  /// No description provided for @rideWorkstreams.
  ///
  /// In en, this message translates to:
  /// **'Ride Workstreams'**
  String get rideWorkstreams;

  /// No description provided for @laneShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Lane Shortcuts'**
  String get laneShortcuts;

  /// No description provided for @pipelineShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Pipeline Shortcuts'**
  String get pipelineShortcuts;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @storeTools.
  ///
  /// In en, this message translates to:
  /// **'Store Tools'**
  String get storeTools;

  /// No description provided for @shopHeroFallback.
  ///
  /// In en, this message translates to:
  /// **'Shop Hero'**
  String get shopHeroFallback;

  /// No description provided for @providerHeroFallback.
  ///
  /// In en, this message translates to:
  /// **'Provider Hero'**
  String get providerHeroFallback;

  /// No description provided for @doctorHeroFallback.
  ///
  /// In en, this message translates to:
  /// **'Doctor Hero'**
  String get doctorHeroFallback;

  /// No description provided for @deliveryHeroFallback.
  ///
  /// In en, this message translates to:
  /// **'Delivery Hero'**
  String get deliveryHeroFallback;

  /// No description provided for @riderHeroFallback.
  ///
  /// In en, this message translates to:
  /// **'Rider Hero'**
  String get riderHeroFallback;

  /// No description provided for @jobsQueueSubtitleFull.
  ///
  /// In en, this message translates to:
  /// **'Review service bookings and laundry jobs.'**
  String get jobsQueueSubtitleFull;

  /// No description provided for @jobsQueueSubtitleLaundry.
  ///
  /// In en, this message translates to:
  /// **'Review your laundry jobs.'**
  String get jobsQueueSubtitleLaundry;

  /// No description provided for @jobsQueueSubtitleServices.
  ///
  /// In en, this message translates to:
  /// **'Review bookings'**
  String get jobsQueueSubtitleServices;

  /// No description provided for @availabilitySubtitleFull.
  ///
  /// In en, this message translates to:
  /// **'Control which provider and laundry lanes are open.'**
  String get availabilitySubtitleFull;

  /// No description provided for @availabilitySubtitleLaundry.
  ///
  /// In en, this message translates to:
  /// **'Control which laundry lanes are open.'**
  String get availabilitySubtitleLaundry;

  /// No description provided for @availabilitySubtitleServices.
  ///
  /// In en, this message translates to:
  /// **'Manage your services'**
  String get availabilitySubtitleServices;

  /// No description provided for @servicesOnly.
  ///
  /// In en, this message translates to:
  /// **'Services Only'**
  String get servicesOnly;

  /// No description provided for @servicesOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the home services queue directly.'**
  String get servicesOnlySubtitle;

  /// No description provided for @laundryOnly.
  ///
  /// In en, this message translates to:
  /// **'Laundry Only'**
  String get laundryOnly;

  /// No description provided for @laundryOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the laundry pipeline directly.'**
  String get laundryOnlySubtitle;

  /// No description provided for @liveModuleInsights.
  ///
  /// In en, this message translates to:
  /// **'Live module insights'**
  String get liveModuleInsights;

  /// No description provided for @recentModuleActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Module Activity'**
  String get recentModuleActivity;

  /// No description provided for @highlightedRequest.
  ///
  /// In en, this message translates to:
  /// **'Highlighted Request'**
  String get highlightedRequest;

  /// No description provided for @shopDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your store orders and products'**
  String get shopDashboardSubtitle;

  /// No description provided for @orderQueue.
  ///
  /// In en, this message translates to:
  /// **'Order Queue'**
  String get orderQueue;

  /// No description provided for @shopManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Management'**
  String get shopManagementTitle;

  /// No description provided for @shopManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your inventory and fulfillment'**
  String get shopManagementSubtitle;

  /// No description provided for @handleActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Handle active orders'**
  String get handleActiveOrders;

  /// No description provided for @updateCatalog.
  ///
  /// In en, this message translates to:
  /// **'Update your catalog'**
  String get updateCatalog;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @noRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'No recent orders found.'**
  String get noRecentOrders;

  /// No description provided for @doctorDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clinical command center for appointments and consultations.'**
  String get doctorDashboardSubtitle;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @patientsToday.
  ///
  /// In en, this message translates to:
  /// **'Patients Today'**
  String get patientsToday;

  /// No description provided for @videoQueue.
  ///
  /// In en, this message translates to:
  /// **'Video Queue'**
  String get videoQueue;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @clinicalQueue.
  ///
  /// In en, this message translates to:
  /// **'Clinical Queue'**
  String get clinicalQueue;

  /// No description provided for @noLiveAppointments.
  ///
  /// In en, this message translates to:
  /// **'No live appointments available right now.'**
  String get noLiveAppointments;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @pendingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCountLabel(Object count);

  /// No description provided for @videoConsultsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} video consults'**
  String videoConsultsLabel(Object count);

  /// No description provided for @providerLiveMessage.
  ///
  /// In en, this message translates to:
  /// **'You are now live and can receive nearby bookings.'**
  String get providerLiveMessage;

  /// No description provided for @providerOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'You are now offline.'**
  String get providerOfflineMessage;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @workDone.
  ///
  /// In en, this message translates to:
  /// **'Work done'**
  String get workDone;

  /// No description provided for @startCleaning.
  ///
  /// In en, this message translates to:
  /// **'Start Cleaning'**
  String get startCleaning;

  /// No description provided for @sendOut.
  ///
  /// In en, this message translates to:
  /// **'Send Out'**
  String get sendOut;

  /// No description provided for @startDelivery.
  ///
  /// In en, this message translates to:
  /// **'Start Delivery'**
  String get startDelivery;

  /// No description provided for @workInProgress.
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get workInProgress;

  /// No description provided for @pipelineWorkboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get pipelineWorkboard;

  /// No description provided for @noPendingBookings.
  ///
  /// In en, this message translates to:
  /// **'No pending bookings to accept.'**
  String get noPendingBookings;

  /// No description provided for @moreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreCount(Object count);

  /// No description provided for @providerDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coordinate live service and laundry pipelines.'**
  String get providerDashboardSubtitle;

  /// No description provided for @goOnlineBeforeClaimingRides.
  ///
  /// In en, this message translates to:
  /// **'Please go online before claiming rides.'**
  String get goOnlineBeforeClaimingRides;

  /// No description provided for @rideRequestClaimedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ride request claimed successfully.'**
  String get rideRequestClaimedSuccessfully;

  /// No description provided for @couldNotClaimRide.
  ///
  /// In en, this message translates to:
  /// **'Could not claim ride: {error}'**
  String couldNotClaimRide(Object error);

  /// No description provided for @nextBestTrip.
  ///
  /// In en, this message translates to:
  /// **'Next best trip'**
  String get nextBestTrip;

  /// No description provided for @openFullQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'Open full queue'**
  String get openFullQueueLabel;

  /// No description provided for @onShift.
  ///
  /// In en, this message translates to:
  /// **'On Shift'**
  String get onShift;

  /// No description provided for @offShift.
  ///
  /// In en, this message translates to:
  /// **'Off Shift'**
  String get offShift;

  /// No description provided for @riderDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay online, claim nearby trips, and keep your completion pace.'**
  String get riderDashboardSubtitle;

  /// No description provided for @openRiderQueue.
  ///
  /// In en, this message translates to:
  /// **'Open rider queue'**
  String get openRiderQueue;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @noLiveRideLanes.
  ///
  /// In en, this message translates to:
  /// **'No live ride lanes available.'**
  String get noLiveRideLanes;

  /// No description provided for @doctorAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Dr. {name} Availability'**
  String doctorAvailabilityTitle(Object name);

  /// No description provided for @noDoctorProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No doctor profiles are currently bound to this pro account.'**
  String get noDoctorProfilesFound;

  /// No description provided for @doctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorLabel;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @doctorAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dr. {name} Appointments'**
  String doctorAppointmentsTitle(Object name);

  /// No description provided for @loadingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Loading appointments...'**
  String get loadingAppointments;

  /// No description provided for @noAppointmentsMatch.
  ///
  /// In en, this message translates to:
  /// **'No appointments match the current queue filters.'**
  String get noAppointmentsMatch;

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// No description provided for @messageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageAction;

  /// No description provided for @appointmentSupport.
  ///
  /// In en, this message translates to:
  /// **'Appointment support'**
  String get appointmentSupport;

  /// No description provided for @openVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Open Video'**
  String get openVideoAction;

  /// No description provided for @schedulePending.
  ///
  /// In en, this message translates to:
  /// **'Schedule pending'**
  String get schedulePending;

  /// No description provided for @doctorHomeCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Dr. {name} Home Care'**
  String doctorHomeCareTitle(Object name);

  /// No description provided for @loadingHomeCare.
  ///
  /// In en, this message translates to:
  /// **'Loading home care...'**
  String get loadingHomeCare;

  /// No description provided for @noHomeCareMatch.
  ///
  /// In en, this message translates to:
  /// **'No home care bookings match the current filters.'**
  String get noHomeCareMatch;

  /// No description provided for @homeCareBookingSupport.
  ///
  /// In en, this message translates to:
  /// **'Home care booking support'**
  String get homeCareBookingSupport;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @clinicVisit.
  ///
  /// In en, this message translates to:
  /// **'Clinic Visit'**
  String get clinicVisit;

  /// No description provided for @videoConsultation.
  ///
  /// In en, this message translates to:
  /// **'Video Consultation'**
  String get videoConsultation;

  /// No description provided for @phoneAdvice.
  ///
  /// In en, this message translates to:
  /// **'Phone Advice'**
  String get phoneAdvice;

  /// No description provided for @homeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home Visit'**
  String get homeVisit;

  /// No description provided for @doctorSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Doctor settings updated.'**
  String get doctorSettingsUpdated;

  /// No description provided for @uploadDoctorPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload doctor photo'**
  String get uploadDoctorPhoto;

  /// No description provided for @clinicArea.
  ///
  /// In en, this message translates to:
  /// **'Clinic or service area'**
  String get clinicArea;

  /// No description provided for @consultationModes.
  ///
  /// In en, this message translates to:
  /// **'Consultation modes'**
  String get consultationModes;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get workingHours;

  /// No description provided for @waitForImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Wait for image upload to finish first.'**
  String get waitForImageUpload;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @doctorSchedulingTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Scheduling'**
  String doctorSchedulingTitle(Object name);

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors are currently bound to this account.'**
  String get noDoctorsFound;

  /// No description provided for @modes.
  ///
  /// In en, this message translates to:
  /// **'Modes'**
  String get modes;

  /// No description provided for @noModesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No care modes configured'**
  String get noModesConfigured;

  /// No description provided for @monFri.
  ///
  /// In en, this message translates to:
  /// **'Mon-Fri'**
  String get monFri;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @setupPractice.
  ///
  /// In en, this message translates to:
  /// **'Setup Practice'**
  String get setupPractice;

  /// No description provided for @welcomeDoctor.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Dr. {name}!'**
  String welcomeDoctor(Object name);

  /// No description provided for @doctorOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s configure how you will provide care and consult with patients on EdaLab.'**
  String get doctorOnboardingSubtitle;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @servicesOffered.
  ///
  /// In en, this message translates to:
  /// **'Services Offered'**
  String get servicesOffered;

  /// No description provided for @inPersonClinicVisit.
  ///
  /// In en, this message translates to:
  /// **'In-Person Clinic Visit'**
  String get inPersonClinicVisit;

  /// No description provided for @clinicVisitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Patients book appointments and visit your physical clinic.'**
  String get clinicVisitSubtitle;

  /// No description provided for @videoConsultationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consult with patients remotely via in-app video calls.'**
  String get videoConsultationSubtitle;

  /// No description provided for @chatPhoneAdvice.
  ///
  /// In en, this message translates to:
  /// **'Chat & Phone Advice'**
  String get chatPhoneAdvice;

  /// No description provided for @chatPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide medical advice through secure messaging and calls.'**
  String get chatPhoneSubtitle;

  /// No description provided for @homeCareServices.
  ///
  /// In en, this message translates to:
  /// **'Home Care Services'**
  String get homeCareServices;

  /// No description provided for @homeCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You or your staff will visit the patient at their home.'**
  String get homeCareSubtitle;

  /// No description provided for @serviceAreaClinicLocation.
  ///
  /// In en, this message translates to:
  /// **'Service Area / Clinic Location'**
  String get serviceAreaClinicLocation;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @pleaseSelectSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Please select a specialty.'**
  String get pleaseSelectSpecialty;

  /// No description provided for @pleaseSelectService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service.'**
  String get pleaseSelectService;

  /// No description provided for @pleaseSelectCareMode.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one care mode.'**
  String get pleaseSelectCareMode;

  /// No description provided for @pleaseProvideLocation.
  ///
  /// In en, this message translates to:
  /// **'Please provide your base clinic or service area location.'**
  String get pleaseProvideLocation;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @cardiology.
  ///
  /// In en, this message translates to:
  /// **'Cardiology'**
  String get cardiology;

  /// No description provided for @dermatology.
  ///
  /// In en, this message translates to:
  /// **'Dermatology'**
  String get dermatology;

  /// No description provided for @neurology.
  ///
  /// In en, this message translates to:
  /// **'Neurology'**
  String get neurology;

  /// No description provided for @orthopedics.
  ///
  /// In en, this message translates to:
  /// **'Orthopedics'**
  String get orthopedics;

  /// No description provided for @pediatrics.
  ///
  /// In en, this message translates to:
  /// **'Pediatrics'**
  String get pediatrics;

  /// No description provided for @homeNursing.
  ///
  /// In en, this message translates to:
  /// **'Home Nursing'**
  String get homeNursing;

  /// No description provided for @physiotherapy.
  ///
  /// In en, this message translates to:
  /// **'Physiotherapy'**
  String get physiotherapy;

  /// No description provided for @mentalTherapy.
  ///
  /// In en, this message translates to:
  /// **'Mental Therapy'**
  String get mentalTherapy;

  /// No description provided for @dentalCare.
  ///
  /// In en, this message translates to:
  /// **'Dental Care'**
  String get dentalCare;

  /// No description provided for @optometry.
  ///
  /// In en, this message translates to:
  /// **'Optometry'**
  String get optometry;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @generalCheckup.
  ///
  /// In en, this message translates to:
  /// **'General Checkup'**
  String get generalCheckup;

  /// No description provided for @ecg.
  ///
  /// In en, this message translates to:
  /// **'ECG'**
  String get ecg;

  /// No description provided for @bloodTest.
  ///
  /// In en, this message translates to:
  /// **'Blood Test'**
  String get bloodTest;

  /// No description provided for @vaccination.
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get vaccination;

  /// No description provided for @woundDressing.
  ///
  /// In en, this message translates to:
  /// **'Wound Dressing'**
  String get woundDressing;

  /// No description provided for @injection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get injection;

  /// No description provided for @postSurgeryRehab.
  ///
  /// In en, this message translates to:
  /// **'Post-surgery Rehab'**
  String get postSurgeryRehab;

  /// No description provided for @physicalTherapy.
  ///
  /// In en, this message translates to:
  /// **'Physical Therapy'**
  String get physicalTherapy;

  /// No description provided for @psychologicalCounseling.
  ///
  /// In en, this message translates to:
  /// **'Psychological Counseling'**
  String get psychologicalCounseling;

  /// No description provided for @emergencyCare.
  ///
  /// In en, this message translates to:
  /// **'Emergency Care'**
  String get emergencyCare;

  /// No description provided for @routineMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Routine Monitoring'**
  String get routineMonitoring;

  /// No description provided for @prescriptionRefill.
  ///
  /// In en, this message translates to:
  /// **'Prescription Refill'**
  String get prescriptionRefill;

  /// No description provided for @waitingForPatient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}...'**
  String waitingForPatient(Object name);

  /// No description provided for @telemedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Telemedicine Session'**
  String get telemedicineTitle;

  /// No description provided for @startPrepAction.
  ///
  /// In en, this message translates to:
  /// **'Start Prep'**
  String get startPrepAction;

  /// No description provided for @dispatchAction.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatchAction;

  /// No description provided for @orderUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Order status updated to {status}.'**
  String orderUpdatedTo(Object status);

  /// No description provided for @shopQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Orders'**
  String shopQueueTitle(Object name);

  /// No description provided for @noOrdersMatch.
  ///
  /// In en, this message translates to:
  /// **'No orders match your filters.'**
  String get noOrdersMatch;

  /// No description provided for @orderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderLabel;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @prescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescriptionLabel;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdDate(Object date);

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @viewRxAction.
  ///
  /// In en, this message translates to:
  /// **'View Rx'**
  String get viewRxAction;

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @createStore.
  ///
  /// In en, this message translates to:
  /// **'Create Store'**
  String get createStore;

  /// No description provided for @allPharmacies.
  ///
  /// In en, this message translates to:
  /// **'All Pharmacies ({count})'**
  String allPharmacies(Object count);

  /// No description provided for @allStores.
  ///
  /// In en, this message translates to:
  /// **'All Stores ({count})'**
  String allStores(Object count);

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @searchMedicinesHint.
  ///
  /// In en, this message translates to:
  /// **'Search medicines, pharmacies, or dosage'**
  String get searchMedicinesHint;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products, stores, or categories'**
  String get searchProductsHint;

  /// No description provided for @noProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match the current filters.'**
  String get noProductsMatch;

  /// No description provided for @prescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Prescription required'**
  String get prescriptionRequired;

  /// No description provided for @pharmacyMedicinesTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Medicines'**
  String pharmacyMedicinesTitle(Object name);

  /// No description provided for @shopProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Products'**
  String shopProductsTitle(Object name);

  /// No description provided for @storeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeNameLabel;

  /// No description provided for @enterValidStoreName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid store name'**
  String get enterValidStoreName;

  /// No description provided for @taglineLabel.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get taglineLabel;

  /// No description provided for @taglineHint.
  ///
  /// In en, this message translates to:
  /// **'Short statement shown under the store name'**
  String get taglineHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about your store'**
  String get descriptionHint;

  /// No description provided for @uploadStoreImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Store Image'**
  String get uploadStoreImage;

  /// No description provided for @saveStoreSetup.
  ///
  /// In en, this message translates to:
  /// **'Save Store Setup'**
  String get saveStoreSetup;

  /// No description provided for @storeCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Store created and connected to your profile.'**
  String get storeCreatedSuccess;

  /// No description provided for @storeUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Store setup updated.'**
  String get storeUpdatedSuccess;

  /// No description provided for @addShoppingProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Shopping Product'**
  String get addShoppingProduct;

  /// No description provided for @noPharmacyConnected.
  ///
  /// In en, this message translates to:
  /// **'No pharmacy business connected.'**
  String get noPharmacyConnected;

  /// No description provided for @noStoreConnected.
  ///
  /// In en, this message translates to:
  /// **'No store business connected.'**
  String get noStoreConnected;

  /// No description provided for @medicineIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine identity and pharmacy binding.'**
  String get medicineIdentitySubtitle;

  /// No description provided for @catalogIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Core catalog identity and description.'**
  String get catalogIdentitySubtitle;

  /// No description provided for @pharmacyBusiness.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy business'**
  String get pharmacyBusiness;

  /// No description provided for @medicineCategory.
  ///
  /// In en, this message translates to:
  /// **'Medicine Category'**
  String get medicineCategory;

  /// No description provided for @catalogCategory.
  ///
  /// In en, this message translates to:
  /// **'Catalog Category'**
  String get catalogCategory;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @medicineDetails.
  ///
  /// In en, this message translates to:
  /// **'Medicine Details'**
  String get medicineDetails;

  /// No description provided for @medicalSpecSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dosage, package details, and prescription need.'**
  String get medicalSpecSubtitle;

  /// No description provided for @dosageLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage (optional)'**
  String get dosageLabel;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 500mg, 10ml'**
  String get dosageHint;

  /// No description provided for @packageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Package size (optional)'**
  String get packageSizeLabel;

  /// No description provided for @packageSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 30 Tablets, 200ml Bottle'**
  String get packageSizeHint;

  /// No description provided for @requiresPrescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Requires prescription'**
  String get requiresPrescriptionLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (\$)'**
  String get priceLabel;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @originalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Original price (optional)'**
  String get originalPriceLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get unitLabel;

  /// No description provided for @boxBottleStripHint.
  ///
  /// In en, this message translates to:
  /// **'box, bottle, strip...'**
  String get boxBottleStripHint;

  /// No description provided for @pieceBoxPairHint.
  ///
  /// In en, this message translates to:
  /// **'piece, box, pair...'**
  String get pieceBoxPairHint;

  /// No description provided for @badgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Badge (optional)'**
  String get badgeLabel;

  /// No description provided for @bestSellerNewHint.
  ///
  /// In en, this message translates to:
  /// **'Best Seller, New, Limited...'**
  String get bestSellerNewHint;

  /// No description provided for @mediaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Images and metadata.'**
  String get mediaSubtitle;

  /// No description provided for @uploadingPrimaryImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading Primary Image...'**
  String get uploadingPrimaryImage;

  /// No description provided for @uploadPrimaryImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Primary Image'**
  String get uploadPrimaryImage;

  /// No description provided for @primaryImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Primary image URL'**
  String get primaryImageUrl;

  /// No description provided for @galleryImageUrls.
  ///
  /// In en, this message translates to:
  /// **'Gallery image URLs'**
  String get galleryImageUrls;

  /// No description provided for @commaNewLineHint.
  ///
  /// In en, this message translates to:
  /// **'Comma or new-line separated URLs'**
  String get commaNewLineHint;

  /// No description provided for @uploadingGalleryImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading Gallery Image...'**
  String get uploadingGalleryImage;

  /// No description provided for @addGalleryImage.
  ///
  /// In en, this message translates to:
  /// **'Add Gallery Image'**
  String get addGalleryImage;

  /// No description provided for @colorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Colors (Comma separated)'**
  String get colorsLabel;

  /// No description provided for @colorsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Red, Blue, Black'**
  String get colorsHint;

  /// No description provided for @sizesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sizes (Comma separated)'**
  String get sizesLabel;

  /// No description provided for @sizesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., S, M, L, XL'**
  String get sizesHint;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (Comma separated)'**
  String get tagsLabel;

  /// No description provided for @tagsPharmacyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Flu, Pain relief, Generic'**
  String get tagsPharmacyHint;

  /// No description provided for @tagsShoppingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Organic, Fresh, Premium'**
  String get tagsShoppingHint;

  /// No description provided for @featuresLabel.
  ///
  /// In en, this message translates to:
  /// **'Features (New line/Comma separated)'**
  String get featuresLabel;

  /// No description provided for @featuresHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 100% Cotton, Waterproof'**
  String get featuresHint;

  /// No description provided for @savingMedicine.
  ///
  /// In en, this message translates to:
  /// **'Saving Medicine...'**
  String get savingMedicine;

  /// No description provided for @savingProduct.
  ///
  /// In en, this message translates to:
  /// **'Saving Product...'**
  String get savingProduct;

  /// No description provided for @createMedicine.
  ///
  /// In en, this message translates to:
  /// **'Create Medicine'**
  String get createMedicine;

  /// No description provided for @createProduct.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get createProduct;

  /// No description provided for @riderQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Ride Queue'**
  String riderQueueTitle(Object name);

  /// No description provided for @assignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get assignedToMe;

  /// No description provided for @loadingRideQueue.
  ///
  /// In en, this message translates to:
  /// **'Loading ride queue...'**
  String get loadingRideQueue;

  /// No description provided for @noRideRequests.
  ///
  /// In en, this message translates to:
  /// **'No ride requests match the current queue filter.'**
  String get noRideRequests;

  /// No description provided for @rideLabel.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get rideLabel;

  /// No description provided for @passengerLabel.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passengerLabel;

  /// No description provided for @requestedDate.
  ///
  /// In en, this message translates to:
  /// **'Requested: {date}'**
  String requestedDate(Object date);

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get working;

  /// No description provided for @openTripAction.
  ///
  /// In en, this message translates to:
  /// **'Open trip'**
  String get openTripAction;

  /// No description provided for @claimAction.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claimAction;

  /// No description provided for @deliveryDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Dispatch'**
  String deliveryDispatchTitle(Object name);

  /// No description provided for @noDeliveryRequests.
  ///
  /// In en, this message translates to:
  /// **'No delivery requests match the current queue filters.'**
  String get noDeliveryRequests;

  /// No description provided for @deliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryLabel;

  /// No description provided for @openJobAction.
  ///
  /// In en, this message translates to:
  /// **'Open Job'**
  String get openJobAction;

  /// No description provided for @moduleDeliverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{module} Delivery'**
  String moduleDeliverySubtitle(Object module);

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @updatedTo.
  ///
  /// In en, this message translates to:
  /// **'updated to'**
  String get updatedTo;

  /// No description provided for @dr.
  ///
  /// In en, this message translates to:
  /// **'Dr.'**
  String get dr;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @telemedicine.
  ///
  /// In en, this message translates to:
  /// **'Telemedicine'**
  String get telemedicine;

  /// No description provided for @homeCare.
  ///
  /// In en, this message translates to:
  /// **'Home Care'**
  String get homeCare;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredLabel;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// No description provided for @laneShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lane Shortcuts'**
  String get laneShortcutsTitle;

  /// No description provided for @workstreamTitle.
  ///
  /// In en, this message translates to:
  /// **'Workstream'**
  String get workstreamTitle;

  /// No description provided for @swipeToCompleteDelivery.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Complete Delivery'**
  String get swipeToCompleteDelivery;

  /// No description provided for @deliveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delivery Completed'**
  String get deliveryCompleted;

  /// No description provided for @swipeToStartDelivery.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Start Delivery'**
  String get swipeToStartDelivery;

  /// No description provided for @deliveryStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Delivery status updated to {status}.'**
  String deliveryStatusUpdated(Object status);

  /// No description provided for @couldNotUpdateDelivery.
  ///
  /// In en, this message translates to:
  /// **'Could not update delivery: {error}'**
  String couldNotUpdateDelivery(Object error);

  /// No description provided for @pickupPointFallback.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get pickupPointFallback;

  /// No description provided for @customerDestinationFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer destination'**
  String get customerDestinationFallback;

  /// No description provided for @courierLabel.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get courierLabel;

  /// No description provided for @etaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'ETA unavailable'**
  String get etaUnavailable;

  /// No description provided for @deliveryRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery route'**
  String get deliveryRouteTitle;

  /// No description provided for @loadingAssignedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Loading assigned delivery...'**
  String get loadingAssignedDelivery;

  /// No description provided for @openMapAction.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMapAction;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumberLabel(Object number);

  /// No description provided for @itemsCountEta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} • {eta}'**
  String itemsCountEta(num count, Object eta);

  /// No description provided for @callCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get callCustomerAction;

  /// No description provided for @deliveryInProgress.
  ///
  /// In en, this message translates to:
  /// **'Delivery in progress'**
  String get deliveryInProgress;

  /// No description provided for @waitingForPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}...'**
  String waitingForPatientLabel(Object name);

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @clinicLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Downtown Medical Center, Nairobi'**
  String get clinicLocationHint;

  /// No description provided for @rideSupport.
  ///
  /// In en, this message translates to:
  /// **'Ride support'**
  String get rideSupport;

  /// No description provided for @swipeToStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Start Trip'**
  String get swipeToStartTrip;

  /// No description provided for @swipeToCompleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Complete Trip'**
  String get swipeToCompleteTrip;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get tripCompleted;

  /// No description provided for @swipeToArrive.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Arrive'**
  String get swipeToArrive;

  /// No description provided for @rideStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Ride status updated to {status}.'**
  String rideStatusUpdated(Object status);

  /// No description provided for @couldNotUpdateRide.
  ///
  /// In en, this message translates to:
  /// **'Could not update ride: {error}'**
  String couldNotUpdateRide(Object error);

  /// No description provided for @pickupLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocationFallback;

  /// No description provided for @dropoffLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Dropoff location'**
  String get dropoffLocationFallback;

  /// No description provided for @assignedRiderFallback.
  ///
  /// In en, this message translates to:
  /// **'Assigned rider'**
  String get assignedRiderFallback;

  /// No description provided for @vehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleLabel;

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA: {eta}'**
  String etaLabel(Object eta);

  /// No description provided for @callPassengerAction.
  ///
  /// In en, this message translates to:
  /// **'Call passenger'**
  String get callPassengerAction;

  /// No description provided for @tripMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip map'**
  String get tripMapTitle;

  /// No description provided for @loadingAssignedTrip.
  ///
  /// In en, this message translates to:
  /// **'Loading assigned trip...'**
  String get loadingAssignedTrip;

  /// No description provided for @rideInProgressSupport.
  ///
  /// In en, this message translates to:
  /// **'Ride in progress'**
  String get rideInProgressSupport;

  /// No description provided for @medicinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicinesLabel;

  /// No description provided for @productsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsLabel;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @allPharmaciesCount.
  ///
  /// In en, this message translates to:
  /// **'All Pharmacies ({count})'**
  String allPharmaciesCount(Object count);

  /// No description provided for @allStoresCount.
  ///
  /// In en, this message translates to:
  /// **'All Stores ({count})'**
  String allStoresCount(Object count);

  /// No description provided for @pharmacyCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count})'**
  String pharmacyCountLabel(Object count, Object name);

  /// No description provided for @storeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count})'**
  String storeCountLabel(Object count, Object name);

  /// No description provided for @wasOriginalPrice.
  ///
  /// In en, this message translates to:
  /// **'was {price}'**
  String wasOriginalPrice(Object price);

  /// No description provided for @connectPharmacyMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect a pharmacy business before adding medicines.'**
  String get connectPharmacyMessage;

  /// No description provided for @createStoreFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a store first before adding products.'**
  String get createStoreFirstMessage;

  /// No description provided for @availabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityLabel;

  /// No description provided for @storeCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Store created and connected to your profile.'**
  String get storeCreatedSuccessfully;

  /// No description provided for @storeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Store setup updated.'**
  String get storeUpdatedSuccessfully;

  /// No description provided for @enterStoreNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid store name'**
  String get enterStoreNameError;

  /// No description provided for @storeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about your store'**
  String get storeDescriptionHint;

  /// No description provided for @shopStorefrontTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Storefront'**
  String shopStorefrontTitle(Object name);

  /// No description provided for @moduleFilter.
  ///
  /// In en, this message translates to:
  /// **'Module Filter'**
  String get moduleFilter;

  /// No description provided for @moduleControls.
  ///
  /// In en, this message translates to:
  /// **'{module} controls'**
  String moduleControls(Object module);

  /// No description provided for @searchFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Search your restaurants and menu activity'**
  String get searchFoodHint;

  /// No description provided for @searchPharmacyHint.
  ///
  /// In en, this message translates to:
  /// **'Search medicines in your pharmacy catalog'**
  String get searchPharmacyHint;

  /// No description provided for @searchStorefrontHint.
  ///
  /// In en, this message translates to:
  /// **'Search your storefront and inventory'**
  String get searchStorefrontHint;

  /// No description provided for @catalogEntries.
  ///
  /// In en, this message translates to:
  /// **'Catalog Entries'**
  String get catalogEntries;

  /// No description provided for @noStorefrontMatch.
  ///
  /// In en, this message translates to:
  /// **'No storefront items match your search yet.'**
  String get noStorefrontMatch;

  /// No description provided for @manageAvailabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage availability, review inventory, and jump into queue actions quickly.'**
  String get manageAvailabilitySubtitle;

  /// No description provided for @restaurantOpen.
  ///
  /// In en, this message translates to:
  /// **'Restaurant is open'**
  String get restaurantOpen;

  /// No description provided for @restaurantPaused.
  ///
  /// In en, this message translates to:
  /// **'Restaurant is paused'**
  String get restaurantPaused;

  /// No description provided for @storeOpen.
  ///
  /// In en, this message translates to:
  /// **'Store is open'**
  String get storeOpen;

  /// No description provided for @storePaused.
  ///
  /// In en, this message translates to:
  /// **'Store is paused'**
  String get storePaused;

  /// No description provided for @editPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Edit Pharmacy'**
  String get editPharmacy;

  /// No description provided for @editStoreSetup.
  ///
  /// In en, this message translates to:
  /// **'Edit Store Setup'**
  String get editStoreSetup;

  /// No description provided for @editRestaurantSetup.
  ///
  /// In en, this message translates to:
  /// **'Edit Restaurant Setup'**
  String get editRestaurantSetup;

  /// No description provided for @createRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Create Restaurant'**
  String get createRestaurant;

  /// No description provided for @createPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Create Pharmacy'**
  String get createPharmacy;

  /// No description provided for @noRestaurantBound.
  ///
  /// In en, this message translates to:
  /// **'No restaurant is bound to this shop profile yet.'**
  String get noRestaurantBound;

  /// No description provided for @noPharmacyBound.
  ///
  /// In en, this message translates to:
  /// **'No pharmacy business is bound to this shop profile yet.'**
  String get noPharmacyBound;

  /// No description provided for @noStoreBound.
  ///
  /// In en, this message translates to:
  /// **'No shopping store is bound to this shop profile yet.'**
  String get noStoreBound;

  /// No description provided for @restaurantConnectedNoMenu.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant is connected, but no menu records are available right now.'**
  String get restaurantConnectedNoMenu;

  /// No description provided for @pharmacyConnectedNoMedicines.
  ///
  /// In en, this message translates to:
  /// **'Your pharmacy is connected, but no medicines are listed yet.'**
  String get pharmacyConnectedNoMedicines;

  /// No description provided for @storeConnectedNoStorefront.
  ///
  /// In en, this message translates to:
  /// **'Your shopping store is connected, but no storefront records are available right now.'**
  String get storeConnectedNoStorefront;

  /// No description provided for @cuisineLabel.
  ///
  /// In en, this message translates to:
  /// **'Cuisine'**
  String get cuisineLabel;

  /// No description provided for @enterValidRestaurantNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid restaurant name first.'**
  String get enterValidRestaurantNameError;

  /// No description provided for @restaurantCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Restaurant created and connected to your profile.'**
  String get restaurantCreatedSuccessfully;

  /// No description provided for @restaurantUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Restaurant details updated.'**
  String get restaurantUpdatedSuccessfully;

  /// No description provided for @pharmacyConnectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy business connected to your profile.'**
  String get pharmacyConnectedSuccessfully;

  /// No description provided for @moduleStorefrontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{module} storefront'**
  String moduleStorefrontSubtitle(Object module);

  /// No description provided for @liveOperationalSummary.
  ///
  /// In en, this message translates to:
  /// **'Live operational summary'**
  String get liveOperationalSummary;

  /// No description provided for @confirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmedStatus;

  /// No description provided for @processingStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingStatus;

  /// No description provided for @dispatchedStatus.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get dispatchedStatus;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @appointmentUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Appointment updated to {status}.'**
  String appointmentUpdatedTo(Object status);

  /// No description provided for @homeCareUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Home care updated to {status}.'**
  String homeCareUpdatedTo(Object status);

  /// No description provided for @moduleDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Dispatch'**
  String moduleDispatchTitle(Object name);

  /// No description provided for @noDeliveryRequestsMatch.
  ///
  /// In en, this message translates to:
  /// **'No delivery requests match the current filters.'**
  String get noDeliveryRequestsMatch;

  /// No description provided for @startJob.
  ///
  /// In en, this message translates to:
  /// **'Start Job'**
  String get startJob;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @moduleJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Jobs'**
  String moduleJobsTitle(Object name);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pipelines.
  ///
  /// In en, this message translates to:
  /// **'Pipelines'**
  String get pipelines;

  /// No description provided for @noJobsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No jobs match the current filters.'**
  String get noJobsMatchFilters;

  /// No description provided for @jobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get jobLabel;

  /// No description provided for @detailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsAction;

  /// No description provided for @servicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesLabel;

  /// No description provided for @laundryLabel.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get laundryLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outLabel;

  /// No description provided for @ordersLabel.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersLabel;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @scheduleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule and active status updated.'**
  String get scheduleUpdated;

  /// No description provided for @acceptBookingsNow.
  ///
  /// In en, this message translates to:
  /// **'Accept bookings now'**
  String get acceptBookingsNow;

  /// No description provided for @activeVisibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active and visible to users'**
  String get activeVisibleSubtitle;

  /// No description provided for @pausedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedSubtitle;

  /// No description provided for @weeklyTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Weekly time slots'**
  String get weeklyTimeSlots;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get toLabel;

  /// No description provided for @useOperationsOnlyTip.
  ///
  /// In en, this message translates to:
  /// **'Use this screen for operations only: active status and time slots.'**
  String get useOperationsOnlyTip;

  /// No description provided for @providerSchedulingTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Scheduling'**
  String providerSchedulingTitle(Object name);

  /// No description provided for @servicesModuleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Services module is not enabled for this provider profile.'**
  String get servicesModuleDisabled;

  /// No description provided for @noServiceListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No offered service listing found yet for this provider account.'**
  String get noServiceListingsFound;

  /// No description provided for @openOfferedServices.
  ///
  /// In en, this message translates to:
  /// **'Open Offered Services'**
  String get openOfferedServices;

  /// No description provided for @manageOfferedServices.
  ///
  /// In en, this message translates to:
  /// **'Manage offered services and profile'**
  String get manageOfferedServices;

  /// No description provided for @manageOfferedServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Offered Services for listing/profile configuration. Scheduling is only for active status and time slots.'**
  String get manageOfferedServicesSubtitle;

  /// No description provided for @editTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Edit time slots'**
  String get editTimeSlots;

  /// No description provided for @turnOnLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to continue.'**
  String get turnOnLocationServices;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for service-zone matching.'**
  String get locationPermissionRequired;

  /// No description provided for @couldNotResolveLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve your current location yet. Move the map pin manually and continue.'**
  String get couldNotResolveLocation;

  /// No description provided for @couldNotAccessLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not access location permission right now.'**
  String get couldNotAccessLocation;

  /// No description provided for @couldNotLoadListing.
  ///
  /// In en, this message translates to:
  /// **'Could not load this service listing.'**
  String get couldNotLoadListing;

  /// No description provided for @completeHouseHelpCriteria.
  ///
  /// In en, this message translates to:
  /// **'Complete house-help criteria using the dedicated fields.'**
  String get completeHouseHelpCriteria;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @offeredServices.
  ///
  /// In en, this message translates to:
  /// **'Offered services'**
  String get offeredServices;

  /// No description provided for @bookingTypes.
  ///
  /// In en, this message translates to:
  /// **'Booking types'**
  String get bookingTypes;

  /// No description provided for @shiftDurations.
  ///
  /// In en, this message translates to:
  /// **'Shift durations'**
  String get shiftDurations;

  /// No description provided for @homeSizes.
  ///
  /// In en, this message translates to:
  /// **'Home sizes'**
  String get homeSizes;

  /// No description provided for @arrivalTargets.
  ///
  /// In en, this message translates to:
  /// **'Arrival targets'**
  String get arrivalTargets;

  /// No description provided for @supplyModes.
  ///
  /// In en, this message translates to:
  /// **'Supply modes'**
  String get supplyModes;

  /// No description provided for @laundryAvailability.
  ///
  /// In en, this message translates to:
  /// **'Laundry Availability'**
  String get laundryAvailability;

  /// No description provided for @serviceAvailability.
  ///
  /// In en, this message translates to:
  /// **'Your services'**
  String get serviceAvailability;

  /// No description provided for @addServiceListing.
  ///
  /// In en, this message translates to:
  /// **'Add service listing'**
  String get addServiceListing;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add listing'**
  String get addListing;

  /// No description provided for @serviceListingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Service listing updated.'**
  String get serviceListingUpdated;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @createHomeServiceListing.
  ///
  /// In en, this message translates to:
  /// **'Create Home-Service Listing'**
  String get createHomeServiceListing;

  /// No description provided for @chooseServiceCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a service category first. The rest of the setup adapts automatically.'**
  String get chooseServiceCategoryFirst;

  /// No description provided for @listingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing title'**
  String get listingTitle;

  /// No description provided for @startingPrice.
  ///
  /// In en, this message translates to:
  /// **'Starting price'**
  String get startingPrice;

  /// No description provided for @zoneRadius.
  ///
  /// In en, this message translates to:
  /// **'Zone radius'**
  String get zoneRadius;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create listing'**
  String get createListing;

  /// No description provided for @uploadListingImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Listing Image'**
  String get uploadListingImage;

  /// No description provided for @uploadingListingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading listing image...'**
  String get uploadingListingImage;

  /// No description provided for @waitForListingImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Wait for the listing image upload to finish.'**
  String get waitForListingImageUpload;

  /// No description provided for @enterValidStartingPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid starting price.'**
  String get enterValidStartingPrice;

  /// No description provided for @selectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Select at least one service.'**
  String get selectAtLeastOneService;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @serviceListingCreated.
  ///
  /// In en, this message translates to:
  /// **'Service listing created and linked.'**
  String get serviceListingCreated;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  String get houseHelp;
  String get homeCleaning;
  String get plumbing;
  String get electrical;
  String get acCooling;
  String get beautyAtHome;
  String get handyman;
  String get ecologicalCleaning;
  String get leakRepair;
  String get pipeInstallation;
  String get drainUnclogging;
  String get faucetSinkRepair;
  String get toiletRepair;
  String get waterHeaterService;
  String get socketSwitchRepair;
  String get lightingInstallation;
  String get wiringInspection;
  String get circuitBreakerService;
  String get fanInstallation;
  String get powerFaultDiagnosis;
  String get acMaintenance;
  String get acGasRefill;
  String get coolingFaultDiagnosis;
  String get acInstallation;
  String get filterCleaning;
  String get emergencyCoolingRepair;
  String get hairStyling;
  String get makeupService;
  String get nailCare;
  String get facialTreatment;
  String get hennaService;
  String get bridalBeauty;
  String get furnitureAssembly;
  String get curtainWallMounting;
  String get minorRepairs;
  String get doorLockFix;
  String get shelfInstallation;
  String get generalHomeTasks;
  String get generalHomeService;
  String get inspectionVisit;
  String get maintenanceSupport;
  String get ecoFriendlyCarWash;
  String get livingRoomFurnitureCleaning;
  String get officeBusinessCleaning;
  String get postConstructionCleaning;
  String get ecologicalDisinfection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
