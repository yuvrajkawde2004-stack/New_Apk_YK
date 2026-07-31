import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'shop_settings': 'Shop Settings',
      'security': 'Security',
      'preferences': 'Preferences',
      'printer_settings': 'Printer Settings',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'pin_lock': 'PIN Lock',
      'fingerprint': 'Fingerprint',
      'sign_out': 'Sign Out',
      'about_app': 'About App',
      'shop_name': 'Shop Name',
      'shop_address': 'Shop Address',
      'gstin': 'GSTIN',
      'currency': 'Currency',
      'good_morning': 'Good Morning ☀️',
      'good_afternoon': 'Good Afternoon 🌤️',
      'good_evening': 'Good Evening 🌙',
      'new_bill': 'New Bill',
      'add_customer': 'Add Customer',
      'total_products': 'Total Products',
      'today_sales': 'Today\'s Sales',
      'monthly_sales': 'Monthly Sales',
      'low_stock': 'Low Stock',
    },
    'mr': {
      'settings': 'सेटिंग्ज',
      'shop_settings': 'दुकान सेटिंग्ज',
      'security': 'सुरक्षा',
      'preferences': 'प्राधान्ये',
      'printer_settings': 'प्रिंटर सेटिंग्ज',
      'language': 'भाषा (Language)',
      'dark_mode': 'डार्क मोड',
      'notifications': 'सूचना (Notifications)',
      'pin_lock': 'पिन लॉक',
      'fingerprint': 'फिंगरप्रिंट',
      'sign_out': 'साइन आउट',
      'about_app': 'अॅप बद्दल',
      'shop_name': 'दुकानाचे नाव',
      'shop_address': 'दुकानाचा पत्ता',
      'gstin': 'जीएसटी (GSTIN)',
      'currency': 'चलन',
      'good_morning': 'शुभ सकाळ ☀️',
      'good_afternoon': 'शुभ दुपार 🌤️',
      'good_evening': 'शुभ संध्याकाळ 🌙',
      'new_bill': 'नवीन बिल',
      'add_customer': 'ग्राहक जोडा',
      'total_products': 'एकूण उत्पादने',
      'today_sales': 'आजची विक्री',
      'monthly_sales': 'महिन्याची विक्री',
      'low_stock': 'कमी साठा',
    },
    'hi': {
      'settings': 'सेटिंग्स',
      'shop_settings': 'दुकान की सेटिंग्स',
      'security': 'सुरक्षा',
      'preferences': 'प्राथमिकताएं',
      'printer_settings': 'प्रिंटर सेटिंग्स',
      'language': 'भाषा (Language)',
      'dark_mode': 'डार्क मोड',
      'notifications': 'सूचनाएं',
      'pin_lock': 'पिन लॉक',
      'fingerprint': 'फिंगरप्रिंट',
      'sign_out': 'साइन आउट',
      'about_app': 'ऐप के बारे में',
      'shop_name': 'दुकान का नाम',
      'shop_address': 'दुकान का पता',
      'gstin': 'जीएसटी (GSTIN)',
      'currency': 'मुद्रा',
      'good_morning': 'सुप्रभात ☀️',
      'good_afternoon': 'शुभ दोपहर 🌤️',
      'good_evening': 'शुभ संध्या 🌙',
      'new_bill': 'नया बिल',
      'add_customer': 'ग्राहक जोड़ें',
      'total_products': 'कुल उत्पाद',
      'today_sales': 'आज की बिक्री',
      'monthly_sales': 'महीने की बिक्री',
      'low_stock': 'कम स्टॉक',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'mr', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
