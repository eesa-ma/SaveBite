import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);


  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Dashboard
      'dashboard_title': 'Restaurant Dashboard',
      'menu_items': 'Menu Items',
      'available': 'Available',
      'unavailable': 'Unavailable',
      'add_item': 'Add Item',
      'notifications': 'Notifications',
      
      // Restaurant Header
      'open': 'Open',
      'closed': 'Closed',
      
      // Menu
      'restaurant_details': 'Restaurant Details',
      'my_profile': 'My Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      
      // Actions
      'close': 'Close',
      'save': 'Save',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'edit_details': 'Edit Details',
      'edit_profile': 'Edit Profile',
      
      // Restaurant Details
      'restaurant_name': 'Restaurant Name',
      'address': 'Address',
      'phone': 'Phone',
      'email': 'Email',
      'operating_hours': 'Operating Hours',
      'rating': 'Rating',
      
      // Profile
      'name': 'Name',
      'role': 'Role',
      
      // Settings
      'notifications_subtitle': 'Receive order and review alerts',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'dark_mode_subtitle': 'Switch to dark theme',
      'help_support': 'Help & Support',
      'help_support_subtitle': 'Get help and contact us',
      
      // Messages
      'marked_as': 'marked as',
      'details_updated': 'Restaurant details updated successfully!',
      'profile_updated': 'Profile updated successfully!',
      'notifications_enabled': 'Notifications enabled',
      'notifications_disabled': 'Notifications disabled',
      'dark_mode_enabled': 'Dark mode enabled',
      'dark_mode_disabled': 'Dark mode disabled',
      'language_changed': 'Language changed to',
      'item_updated': 'Item updated successfully',
      'item_update_success': 'Item updated successfully',
      'receive_alerts': 'Receive order and review alerts',
      'confirm_logout': 'Are you sure you want to logout?',
      'error_logging_out': 'Error logging out',
      'logout_success': 'Logged out successfully',
      'restaurant_details_updated': 'Restaurant details updated successfully!',
      'error_saving_details': 'Error saving details',
      'menu': 'Menu',
      'restaurant_dashboard': 'Restaurant Dashboard',
      'view_all': 'View All',
      
      // Dialog
      'edit_menu_item': 'Edit Menu Item',
      'item_name': 'Item Name',
      'price': 'Price',
      'logout_confirm': 'Are you sure you want to logout?',
      'logged_out': 'Logged out successfully',
      
      // Help & Support
      'need_assistance': 'Need assistance? Contact us:',
      'live_chat': 'Live Chat',
      'available_hours': 'Available 9 AM - 6 PM',
      'select_language': 'Select Language',
      'opening_email_app': 'Opening email app...',
      'opening_phone_dialer': 'Opening phone dialer...',
      'opening_live_chat': 'Opening live chat...',
      'get_help_contact_us': 'Get help and contact us',
      'switch_to_dark_theme': 'Switch to dark theme',
    },
    'hi': {
      // Dashboard
      'dashboard_title': 'रेस्टोरेंट डैशबोर्ड',
      'menu_items': 'मेनू आइटम',
      'available': 'उपलब्ध',
      'unavailable': 'अनुपलब्ध',
      'add_item': 'आइटम जोड़ें',
      'notifications': 'सूचनाएं',
      
      // Restaurant Header
      'open': 'खुला',
      'closed': 'बंद',
      
      // Menu
      'restaurant_details': 'रेस्टोरेंट विवरण',
      'my_profile': 'मेरी प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'logout': 'लॉगआउट',
      
      // Actions
      'close': 'बंद करें',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'edit': 'संपादित करें',
      'edit_details': 'विवरण संपादित करें',
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      
      // Restaurant Details
      'restaurant_name': 'रेस्टोरेंट का नाम',
      'address': 'पता',
      'phone': 'फोन',
      'email': 'ईमेल',
      'operating_hours': 'संचालन समय',
      'rating': 'रेटिंग',
      
      // Profile
      'name': 'नाम',
      'role': 'भूमिका',
      
      // Settings
      'notifications_subtitle': 'ऑर्डर और समीक्षा अलर्ट प्राप्त करें',
      'language': 'भाषा',
      'dark_mode': 'डार्क मोड',
      'dark_mode_subtitle': 'डार्क थीम पर स्विच करें',
      'help_support': 'सहायता और समर्थन',
      'help_support_subtitle': 'सहायता प्राप्त करें और हमसे संपर्क करें',
      
      // Messages
      'marked_as': 'के रूप में चिह्नित',
      'details_updated': 'रेस्टोरेंट विवरण सफलतापूर्वक अपडेट किया गया!',
      'profile_updated': 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई!',
      'notifications_enabled': 'सूचनाएं सक्षम',
      'notifications_disabled': 'सूचनाएं अक्षम',
      'dark_mode_enabled': 'डार्क मोड सक्षम',
      'dark_mode_disabled': 'डार्क मोड अक्षम',
      'language_changed': 'भाषा बदली गई',
      'item_updated': 'आइटम सफलतापूर्वक अपडेट किया गया',
      'item_update_success': 'आइटम सफलतापूर्वक अपडेट किया गया',
      'receive_alerts': 'ऑर्डर और समीक्षा अलर्ट प्राप्त करें',
      'confirm_logout': 'क्या आप निश्चित रूप से लॉगआउट करना चाहते हैं?',
      'error_logging_out': 'लॉगआउट में त्रुटि',
      'logout_success': 'सफलतापूर्वक लॉगआउट किया गया',
      'restaurant_details_updated': 'रेस्टोरेंट विवरण सफलतापूर्वक अपडेट किए गए!',
      'error_saving_details': 'विवरण सहेजने में त्रुटि',
      'menu': 'मेनू',
      'restaurant_dashboard': 'रेस्टोरेंट डैशबोर्ड',
      'view_all': 'सभी देखें',
      
      // Dialog
      'edit_menu_item': 'मेनू आइटम संपादित करें',
      'item_name': 'आइटम का नाम',
      'price': 'कीमत',
      'logout_confirm': 'क्या आप निश्चित रूप से लॉगआउट करना चाहते हैं?',
      'logged_out': 'सफलतापूर्वक लॉगआउट किया गया',
      
      // Help & Support
      'need_assistance': 'सहायता की आवश्यकता है? हमसे संपर्क करें:',
      'live_chat': 'लाइव चैट',
      'available_hours': 'सुबह 9 बजे से शाम 6 बजे तक उपलब्ध',
      'select_language': 'भाषा चुनें',
      'opening_email_app': 'ईमेल ऐप खोल रहे हैं...',
      'opening_phone_dialer': 'फोन डायलर खोल रहे हैं...',
      'opening_live_chat': 'लाइव चैट खोल रहे हैं...',
      'get_help_contact_us': 'सहायता प्राप्त करें और हमसे संपर्क करें',
      'switch_to_dark_theme': 'डार्क थीम पर स्विच करें',
    },
    'pa': {
      // Dashboard
      'dashboard_title': 'ਰੈਸਟੋਰੈਂਟ ਡੈਸ਼ਬੋਰਡ',
      'menu_items': 'ਮੀਨੂ ਆਈਟਮਾਂ',
      'available': 'ਉਪਲਬਧ',
      'unavailable': 'ਅਣਉਪਲਬਧ',
      'add_item': 'ਆਈਟਮ ਜੋੜੋ',
      'notifications': 'ਸੂਚਨਾਵਾਂ',
      
      // Restaurant Header
      'open': 'ਖੁੱਲ੍ਹਾ',
      'closed': 'ਬੰਦ',
      
      // Menu
      'restaurant_details': 'ਰੈਸਟੋਰੈਂਟ ਵੇਰਵੇ',
      'my_profile': 'ਮੇਰੀ ਪ੍ਰੋਫਾਈਲ',
      'settings': 'ਸੈਟਿੰਗਾਂ',
      'logout': 'ਲਾੱਗਆਊਟ',
      
      // Actions
      'close': 'ਬੰਦ ਕਰੋ',
      'save': 'ਸੰਭਾਲੋ',
      'cancel': 'ਰੱਦ ਕਰੋ',
      'edit': 'ਸੰਪਾਦਿਤ ਕਰੋ',
      'edit_details': 'ਵੇਰਵੇ ਸੰਪਾਦਿਤ ਕਰੋ',
      'edit_profile': 'ਪ੍ਰੋਫਾਈਲ ਸੰਪਾਦਿਤ ਕਰੋ',
      
      // Restaurant Details
      'restaurant_name': 'ਰੈਸਟੋਰੈਂਟ ਦਾ ਨਾਮ',
      'address': 'ਪਤਾ',
      'phone': 'ਫੋਨ',
      'email': 'ਈਮੇਲ',
      'operating_hours': 'ਸੰਚਾਲਨ ਸਮਾਂ',
      'rating': 'ਰੇਟਿੰਗ',
      
      // Profile
      'name': 'ਨਾਮ',
      'role': 'ਭੂਮਿਕਾ',
      
      // Settings
      'notifications_subtitle': 'ਆਰਡਰ ਅਤੇ ਸਮੀਖਿਆ ਅਲਰਟ ਪ੍ਰਾਪਤ ਕਰੋ',
      'language': 'ਭਾਸ਼ਾ',
      'dark_mode': 'ਡਾਰਕ ਮੋਡ',
      'dark_mode_subtitle': 'ਡਾਰਕ ਥੀਮ ਤੇ ਸਵਿੱਚ ਕਰੋ',
      'help_support': 'ਮਦਦ ਅਤੇ ਸਹਾਇਤਾ',
      'help_support_subtitle': 'ਮਦਦ ਲਓ ਅਤੇ ਸਾਡੇ ਨਾਲ ਸੰਪਰਕ ਕਰੋ',
      
      // Messages
      'marked_as': 'ਵਜੋਂ ਚਿੰਨ੍ਹਿਤ',
      'details_updated': 'ਰੈਸਟੋਰੈਂਟ ਵੇਰਵੇ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤੇ ਗਏ!',
      'profile_updated': 'ਪ੍ਰੋਫਾਈਲ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤੀ ਗਈ!',
      'notifications_enabled': 'ਸੂਚਨਾਵਾਂ ਚਾਲੂ',
      'notifications_disabled': 'ਸੂਚਨਾਵਾਂ ਬੰਦ',
      'dark_mode_enabled': 'ਡਾਰਕ ਮੋਡ ਚਾਲੂ',
      'dark_mode_disabled': 'ਡਾਰਕ ਮੋਡ ਬੰਦ',
      'language_changed': 'ਭਾਸ਼ਾ ਬਦਲੀ ਗਈ',
      'item_updated': 'ਆਈਟਮ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤੀ ਗਈ',
      'item_update_success': 'ਆਈਟਮ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤੀ ਗਈ',
      'receive_alerts': 'ਆਰਡਰ ਅਤੇ ਸਮੀਖਿਆ ਸੂਚਨਾਵਾਂ ਪ੍ਰਾਪਤ ਕਰੋ',
      'confirm_logout': 'ਕੀ ਤੁਸੀਂ ਯਕੀਨੀ ਤੌਰ ਉੱਤੇ ਲਾੱਗਆਊਟ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?',
      'error_logging_out': 'ਲਾੱਗਆਊਟ ਅਰਆਸ',
      'logout_success': 'ਸਫਲਤਾਪੂਰਵਕ ਲਾੱਗਆਊਟ ਕੀਤਾ ਗਿਆ',
      'restaurant_details_updated': 'ਰੈਸਟੋਰੈਂਟ ਵੇਰਵੇ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤੇ ਗਏ!',
      'error_saving_details': 'ਵੇਰਵੇ ਸੰਭਾਲਣ ਾਲ ਅਰਆਸ',
      'menu': 'ਮੀਨੂ',
      'restaurant_dashboard': 'ਰੈਸਟੋਰੈਂਟ ਡੈਸ਼ਬੋਰਡ',
      'view_all': 'ਸਭ ਵੇਖੋ',
      'opening_email_app': 'ਈਮੇਲ ਐਪ ਖੋਲ ਰਹੇ ਹਨ...',
      'opening_phone_dialer': 'ਫੋਨ ਡਾਇਲਰ ਖੋਲ ਰਹੇ ਹਨ...',
      'opening_live_chat': 'ਲਾਈਵ ਚੈਟ ਖੋਲ ਰਹੇ ਹਨ...',
      'get_help_contact_us': 'ਮਦਦ ਲਓ ਅਤੇ ਸਾਡੇ ਨਾਲ ਸੰਪਰਕ ਕਰੋ',
      'switch_to_dark_theme': 'ਡਾਰਕ ਥੀਮ ਤੇ ਬਦਲੋ',
      
      // Dialog
      'edit_menu_item': 'ਮੀਨੂ ਆਈਟਮ ਸੰਪਾਦਿਤ ਕਰੋ',
      'item_name': 'ਆਈਟਮ ਦਾ ਨਾਮ',
      'price': 'ਕੀਮਤ',
      'logout_confirm': 'ਕੀ ਤੁਸੀਂ ਯਕੀਨੀ ਤੌਰ \'ਤੇ ਲਾੱਗਆਊਟ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?',
      'logged_out': 'ਸਫਲਤਾਪੂਰਵਕ ਲਾੱਗਆਊਟ ਕੀਤਾ ਗਿਆ',
      
      // Help & Support
      'need_assistance': 'ਮਦਦ ਚਾਹੀਦੀ ਹੈ? ਸਾਡੇ ਨਾਲ ਸੰਪਰਕ ਕਰੋ:',
      'live_chat': 'ਲਾਈਵ ਚੈਟ',
      'available_hours': 'ਸਵੇਰੇ 9 ਤੋਂ ਸ਼ਾਮ 6 ਵਜੇ ਤੱਕ ਉਪਲਬਧ',
      'select_language': 'ਭਾਸ਼ਾ ਚੁਣੋ',
    },
  };

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
  
  String get dashboardTitle => translate('dashboard_title');
  String get menuItems => translate('menu_items');
  String get available => translate('available');
  String get unavailable => translate('unavailable');
  String get addItem => translate('add_item');
  String get notifications => translate('notifications');
  String get open => translate('open');
  String get closed => translate('closed');
  String get restaurantDetails => translate('restaurant_details');
  String get myProfile => translate('my_profile');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get close => translate('close');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get edit => translate('edit');
  String get editDetails => translate('edit_details');
  String get editProfile => translate('edit_profile');
  String get restaurantName => translate('restaurant_name');
  String get address => translate('address');
  String get phone => translate('phone');
  String get email => translate('email');
  String get operatingHours => translate('operating_hours');
  String get rating => translate('rating');
  String get name => translate('name');
  String get role => translate('role');
  String get notificationsSubtitle => translate('notifications_subtitle');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get darkModeSubtitle => translate('dark_mode_subtitle');
  String get helpSupport => translate('help_support');
  String get helpSupportSubtitle => translate('help_support_subtitle');
  String get markedAs => translate('marked_as');
  String get detailsUpdated => translate('details_updated');
  String get profileUpdated => translate('profile_updated');
  String get notificationsEnabled => translate('notifications_enabled');
  String get notificationsDisabled => translate('notifications_disabled');
  String get darkModeEnabled => translate('dark_mode_enabled');
  String get darkModeDisabled => translate('dark_mode_disabled');
  String get languageChanged => translate('language_changed');
  String get itemUpdated => translate('item_updated');
  String get editMenuItem => translate('edit_menu_item');
  String get itemName => translate('item_name');
  String get price => translate('price');
  String get logoutConfirm => translate('logout_confirm');
  String get loggedOut => translate('logged_out');
  String get needAssistance => translate('need_assistance');
  String get liveChat => translate('live_chat');
  String get availableHours => translate('available_hours');
  String get selectLanguage => translate('select_language');
  
  // Additional keys
  String get itemUpdateSuccess => translate('item_update_success');
  String get receiveAlerts => translate('receive_alerts');
  String get confirmLogout => translate('confirm_logout');
  String get errorLoggingOut => translate('error_logging_out');
  String get logoutSuccess => translate('logout_success');
  String get restaurantDetailsUpdated => translate('restaurant_details_updated');
  String get errorSavingDetails => translate('error_saving_details');
  String get menu => translate('menu');
  String get restaurantDashboard => translate('restaurant_dashboard');
  String get viewAll => translate('view_all');
  String get openingEmailApp => translate('opening_email_app');
  String get openingPhoneDialer => translate('opening_phone_dialer');
  String get openingLiveChat => translate('opening_live_chat');
  String get getHelpContactUs => translate('get_help_contact_us');
  String get switchToDarkTheme => translate('switch_to_dark_theme');
  String get errorUpdatingProfile => translate('error_logging_out');
  
  // Method for dynamic language change message
  String languageChangedTo(String language) {
    return '${translate('language_changed')} $language';
  }  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations('en');
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'pa'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale.languageCode));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}