// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

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
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
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

  /// `FOODINI`
  String get FOODINI {
    return Intl.message('FOODINI', name: 'FOODINI', desc: '', args: []);
  }

  /// `ORDER NOW`
  String get ORDER_NOW {
    return Intl.message('ORDER NOW', name: 'ORDER_NOW', desc: '', args: []);
  }

  /// `Order, Eat, Enjoy Foodini Delivers Magic to Your Door.`
  String get SLOGAN {
    return Intl.message(
      'Order, Eat, Enjoy Foodini Delivers Magic to Your Door.',
      name: 'SLOGAN',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get NAME {
    return Intl.message('Name', name: 'NAME', desc: '', args: []);
  }

  /// `Email`
  String get EMAIL {
    return Intl.message('Email', name: 'EMAIL', desc: '', args: []);
  }

  /// `Password`
  String get PASSWORD {
    return Intl.message('Password', name: 'PASSWORD', desc: '', args: []);
  }

  /// `Confirm Password`
  String get CONFIRM_PASSWORD {
    return Intl.message(
      'Confirm Password',
      name: 'CONFIRM_PASSWORD',
      desc: '',
      args: [],
    );
  }

  /// `Sign Up`
  String get SIGN_UP {
    return Intl.message('Sign Up', name: 'SIGN_UP', desc: '', args: []);
  }

  /// `Already have an account?`
  String get ALREADY_HAVE_ACCOUNT {
    return Intl.message(
      'Already have an account?',
      name: 'ALREADY_HAVE_ACCOUNT',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get SIGN_IN {
    return Intl.message('Sign In', name: 'SIGN_IN', desc: '', args: []);
  }

  /// `Please enter your name`
  String get ENTER_NAME {
    return Intl.message(
      'Please enter your name',
      name: 'ENTER_NAME',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your email`
  String get ENTER_EMAIL {
    return Intl.message(
      'Please enter your email',
      name: 'ENTER_EMAIL',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid email address`
  String get VALID_EMAIL {
    return Intl.message(
      'Please enter a valid email address',
      name: 'VALID_EMAIL',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your password`
  String get ENTER_PASSWORD {
    return Intl.message(
      'Please enter your password',
      name: 'ENTER_PASSWORD',
      desc: '',
      args: [],
    );
  }

  /// `Please confirm your password`
  String get CONFIRM_PASSWORD_VALIDATION {
    return Intl.message(
      'Please confirm your password',
      name: 'CONFIRM_PASSWORD_VALIDATION',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 6 characters`
  String get PASSWORD_VALIDATION {
    return Intl.message(
      'Password must be at least 6 characters',
      name: 'PASSWORD_VALIDATION',
      desc: '',
      args: [],
    );
  }

  /// `Sign up success`
  String get SIGN_UP_SUCCESS {
    return Intl.message(
      'Sign up success',
      name: 'SIGN_UP_SUCCESS',
      desc: '',
      args: [],
    );
  }

  /// `Email or name already in use`
  String get EMAIL_OR_NAME_IN_USE {
    return Intl.message(
      'Email or name already in use',
      name: 'EMAIL_OR_NAME_IN_USE',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong`
  String get SOMETHING_WENT_WRONG {
    return Intl.message(
      'Something went wrong',
      name: 'SOMETHING_WENT_WRONG',
      desc: '',
      args: [],
    );
  }

  /// `Don’t have an account?`
  String get DONT_HAVE_ACCOUNT {
    return Intl.message(
      'Don’t have an account?',
      name: 'DONT_HAVE_ACCOUNT',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sign in`
  String get FAILED_SIGN_IN {
    return Intl.message(
      'Failed to sign in',
      name: 'FAILED_SIGN_IN',
      desc: '',
      args: [],
    );
  }

  /// `Have an account?`
  String get HAVE_ACCOUNT {
    return Intl.message(
      'Have an account?',
      name: 'HAVE_ACCOUNT',
      desc: '',
      args: [],
    );
  }

  /// `Restaurants`
  String get Restaurants {
    return Intl.message('Restaurants', name: 'Restaurants', desc: '', args: []);
  }

  /// `Edit Profile`
  String get EDIT_PROFILE {
    return Intl.message(
      'Edit Profile',
      name: 'EDIT_PROFILE',
      desc: '',
      args: [],
    );
  }

  /// `Notification`
  String get NOTIFICATION {
    return Intl.message(
      'Notification',
      name: 'NOTIFICATION',
      desc: '',
      args: [],
    );
  }

  /// `Payment`
  String get PAYMENT {
    return Intl.message('Payment', name: 'PAYMENT', desc: '', args: []);
  }

  /// `Security`
  String get SECURITY {
    return Intl.message('Security', name: 'SECURITY', desc: '', args: []);
  }

  /// `Language`
  String get LANGUAGE {
    return Intl.message('Language', name: 'LANGUAGE', desc: '', args: []);
  }

  /// `Dark Mode`
  String get DARK_MODE {
    return Intl.message('Dark Mode', name: 'DARK_MODE', desc: '', args: []);
  }

  /// `Privacy Policy`
  String get PRIVACY_POLICY {
    return Intl.message(
      'Privacy Policy',
      name: 'PRIVACY_POLICY',
      desc: '',
      args: [],
    );
  }

  /// `Invite Friends`
  String get INVITE_FRIENDS {
    return Intl.message(
      'Invite Friends',
      name: 'INVITE_FRIENDS',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get LOGOUT {
    return Intl.message('Logout', name: 'LOGOUT', desc: '', args: []);
  }

  /// `Change profile picture`
  String get CHANGE_PROFILE_PICTURE {
    return Intl.message(
      'Change profile picture',
      name: 'CHANGE_PROFILE_PICTURE',
      desc: '',
      args: [],
    );
  }

  /// `Full name`
  String get FULL_NAME {
    return Intl.message('Full name', name: 'FULL_NAME', desc: '', args: []);
  }

  /// `First name`
  String get FIRST_NAME {
    return Intl.message('First name', name: 'FIRST_NAME', desc: '', args: []);
  }

  /// `Last name`
  String get LAST_NAME {
    return Intl.message('Last name', name: 'LAST_NAME', desc: '', args: []);
  }

  /// `Address`
  String get ADDRESS {
    return Intl.message('Address', name: 'ADDRESS', desc: '', args: []);
  }

  /// `Street`
  String get STREET {
    return Intl.message('Street', name: 'STREET', desc: '', args: []);
  }

  /// `Change password`
  String get CHANGE_PASSWORD {
    return Intl.message(
      'Change password',
      name: 'CHANGE_PASSWORD',
      desc: '',
      args: [],
    );
  }

  /// `Current password`
  String get CURRENT_PASSWORD {
    return Intl.message(
      'Current password',
      name: 'CURRENT_PASSWORD',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get NEW_PASSWORD {
    return Intl.message(
      'New password',
      name: 'NEW_PASSWORD',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get SAVE_CHANGES {
    return Intl.message(
      'Save changes',
      name: 'SAVE_CHANGES',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get DISCARD {
    return Intl.message('Discard', name: 'DISCARD', desc: '', args: []);
  }

  /// `Order Status`
  String get ORDER_STATUS {
    return Intl.message(
      'Order Status',
      name: 'ORDER_STATUS',
      desc: '',
      args: [],
    );
  }

  /// `Delivery`
  String get DELIVERY {
    return Intl.message('Delivery', name: 'DELIVERY', desc: '', args: []);
  }

  /// `Dine in`
  String get DINE_IN {
    return Intl.message('Dine in', name: 'DINE_IN', desc: '', args: []);
  }

  /// `Take Away`
  String get TAKE_AWAY {
    return Intl.message('Take Away', name: 'TAKE_AWAY', desc: '', args: []);
  }

  /// `Pending`
  String get PENDING {
    return Intl.message('Pending', name: 'PENDING', desc: '', args: []);
  }

  /// `On the Way`
  String get ON_THE_WAY {
    return Intl.message('On the Way', name: 'ON_THE_WAY', desc: '', args: []);
  }

  /// `Delivered`
  String get DELIVERED {
    return Intl.message('Delivered', name: 'DELIVERED', desc: '', args: []);
  }

  /// `Prepared`
  String get PREPARED {
    return Intl.message('Prepared', name: 'PREPARED', desc: '', args: []);
  }

  /// `Phone Number`
  String get PHONE_NUMBER {
    return Intl.message(
      'Phone Number',
      name: 'PHONE_NUMBER',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get FORGOT_PASSWORD {
    return Intl.message(
      'Forgot password?',
      name: 'FORGOT_PASSWORD',
      desc: '',
      args: [],
    );
  }
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
