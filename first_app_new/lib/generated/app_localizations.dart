import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Use S class as AppLocalizations for backward compatibility
typedef AppLocalizations = S;

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();

    // We're setting the default locale instead of trying to load messages
    Intl.defaultLocale = name;
    final instance = S();
    S._current = instance;
    return Future.value(instance);
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  // FOOD APP TRANSLATIONS
  String get appName => Intl.message('FOODINI');
  String get orderNow => Intl.message('ORDER NOW');
  String get slogan =>
      Intl.message('Order, Eat, Enjoy Foodini Delivers Magic to Your Door.');
  String get name => Intl.message('Name');
  String get email => Intl.message('Email');
  String get password => Intl.message('Password');
  String get confirmPassword => Intl.message('Confirm Password');
  String get signUp => Intl.message('Sign Up');
  String get alreadyHaveAccount => Intl.message('Already have an account?');
  String get signIn => Intl.message('Sign In');
  String get enterName => Intl.message('Please enter your name');
  String get enterEmail => Intl.message('Please enter your email');
  String get validEmail => Intl.message('Please enter a valid email address');
  String get enterPassword => Intl.message('Please enter your password');
  String get confirmPasswordValidation =>
      Intl.message('Please confirm your password');
  String get passwordValidation =>
      Intl.message('Password must be at least 6 characters');
  String get signUpSuccess => Intl.message('Sign up success');
  String get emailOrNameInUse => Intl.message('Email or name already in use');
  String get somethingWentWrong => Intl.message('Something went wrong');
  String get dontHaveAccount => Intl.message('Don\'t have an account?');
  String get failedSignIn => Intl.message('Failed to sign in');
  String get haveAccount => Intl.message('Have an account?');
  String get restaurants => Intl.message('Restaurants');
  String get editProfile => Intl.message('Edit Profile');
  String get notification => Intl.message('Notification');
  String get payment => Intl.message('Payment');
  String get security => Intl.message('Security');
  String get language => Intl.message('Language');
  String get darkMode => Intl.message('Dark Mode');
  String get privacyPolicy => Intl.message('Privacy Policy');
  String get inviteFriends => Intl.message('Invite Friends');
  String get logout => Intl.message('Logout');
  String get changeProfilePicture => Intl.message('Change profile picture');
  String get fullName => Intl.message('Full name');
  String get firstName => Intl.message('First name');
  String get lastName => Intl.message('Last name');
  String get address => Intl.message('Address');
  String get street => Intl.message('Street');
  String get changePassword => Intl.message('Change password');
  String get currentPassword => Intl.message('Current password');
  String get newPassword => Intl.message('New password');
  String get saveChanges => Intl.message('Save changes');
  String get discard => Intl.message('Discard');
  String get orderStatus => Intl.message('Order Status');
  String get delivery => Intl.message('Delivery');
  String get dineIn => Intl.message('Dine in');
  String get takeAway => Intl.message('Take Away');
  String get pending => Intl.message('Pending');
  String get onTheWay => Intl.message('On the Way');
  String get delivered => Intl.message('Delivered');
  String get prepared => Intl.message('Prepared');
  String get phoneNumber => Intl.message('Phone Number');
  String get forgotPassword => Intl.message('Forgot password?');
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
