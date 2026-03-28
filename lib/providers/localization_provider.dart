import 'package:flutter/material.dart';

class LocalizationProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  final Map<String, String> languageNames = {
    'en': 'English',
    'ml': 'മലയാളം',
    'hi': 'हिंदी',
    'ta': 'தமிழ்',
    'kn': 'ಕನ್ನಡ',
  };

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'dashboard': 'POS Dashboard',
      'newBill': 'New Bill',
      'products': 'Products',
      'customers': 'Customers',
      'salesHistory': 'Sales History',
      'changeLanguage': 'Change Language',
      'logout': 'Logout',
      'billSaved': 'Bill saved successfully!',
      'loginError': 'Login failed. Please check credentials.',
      'productUpdated': 'Product Updated!',
      'productCreated': 'Product Created!',
      'noDecimalItems': 'Decimals not allowed for unit-based items.',
      'onlyStockAvailable': 'Only {count} {unit} available',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'help_support': 'Help & Support',
    },
    'ml': {
      'dashboard': 'ഡാഷ്ബോർഡ്',
      'newBill': 'പുതിയ ബിൽ',
      'products': 'ഉൽപ്പന്നങ്ങൾ',
      'customers': 'ഉപഭോക്താക്കൾ',
      'salesHistory': 'വിൽപന ചരിത്രം',
      'changeLanguage': 'ഭാഷ മാറ്റുക',
      'logout': 'ലോഗൗട്ട്',
      'billSaved': 'ബിൽ വിജയകരമായി സേവ് ചെയ്തു!',
      'loginError': 'ലോഗിൻ പരാജയപ്പെട്ടു. വിവരങ്ങൾ പരിശോധിക്കുക.',
      'productUpdated': 'ഉൽപ്പന്നം പുതുക്കി!',
      'productCreated': 'ഉൽപ്പന്നം ചേർത്തു!',
      'noDecimalItems': 'യൂണിറ്റ് ഉൽപ്പന്നങ്ങൾക്ക് ദശാംശങ്ങൾ അനുവദനീയമല്ല.',
      'onlyStockAvailable': '{count} {unit} മാത്രമേ ലഭ്യമാകൂ',
      'profile': 'പ്രൊഫൈൽ',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'language': 'ഭാഷ',
      'help_support': 'സഹായവും പിന്തുണയും',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'newBill': 'नया बिल',
      'products': 'उत्पाद',
      'customers': 'ग्राहक',
      'salesHistory': 'बिक्री इतिहास',
      'changeLanguage': 'भाषा बदलें',
      'logout': 'लॉग आउट',
      'billSaved': 'बिल सफलतापूर्वक सहेजा गया!',
      'loginError': 'लॉगिन विफल. विवरण जांचें.',
      'productUpdated': 'उत्पाद अद्यतन!',
      'productCreated': 'उत्पाद बनाया गया!',
      'noDecimalItems': 'यूनिट उत्पादों के लिए दशमलव की अनुमति नहीं है।',
      'onlyStockAvailable': 'केवल {count} {unit} उपलब्ध है',
      'profile': 'प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'help_support': 'सहायता और समर्थन',
    },
    'ta': {
      'dashboard': 'டாஷ்போர்டு',
      'newBill': 'புதிய பில்',
      'products': 'தயாரிப்புகள்',
      'customers': 'வாடிக்கையாளர்கள்',
      'salesHistory': 'விற்பனை வரலாறு',
      'changeLanguage': 'மொழியை மாற்று',
      'logout': 'வெளியேறு',
      'billSaved': 'பில் வெற்றிகரமாகச் சேமிக்கப்பட்டது!',
      'loginError': 'உள்நுழைவு தோல்வியடைந்தது. விவரங்களைச் சரிபார்க்கவும்.',
      'productUpdated': 'தயாரிப்பு புதுப்பிக்கப்பட்டது!',
      'productCreated': 'தயாரிப்பு உருவாக்கப்பட்டது!',
      'noDecimalItems': 'யூனிட் பொருட்களுக்கு தசமங்கள் அனுமதிக்கப்படாது.',
      'onlyStockAvailable': 'மட்டும் {count} {unit} கிடைக்கிறது',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'language': 'மொழி',
      'help_support': 'உதவி மற்றும் ஆதரவு',
    },
    'kn': {
      'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'newBill': 'ಹೊಸ ಬಿಲ್',
      'products': 'ಉತ್ಪನ್ನಗಳು',
      'customers': 'ಗ್ರಾಹಕರು',
      'salesHistory': 'ಮಾರಾಟದ ಇತಿಹಾಸ',
      'changeLanguage': 'ಭಾಷೆ ಬದಲಾಯಿಸಿ',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'billSaved': 'ಬಿಲ್ ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ!',
      'loginError': 'ಲಾಗಿನ್ ವಿಫಲವಾಗಿದೆ. ವಿವರಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
      'productUpdated': 'ಉತ್ಪನ್ನವನ್ನು ನವೀಕರಿಸಲಾಗಿದೆ!',
      'productCreated': 'ಉತ್ಪನ್ನವನ್ನು ರಚಿಸಲಾಗಿದೆ!',
      'noDecimalItems': 'ಯೂನಿಟ್ ಉತ್ಪನ್ನಗಳಿಗೆ ದಶಮಾಂಶಗಳನ್ನು ಅನುಮತಿಸುವುದಿಲ್ಲ.',
      'onlyStockAvailable': 'ಕೇವಲ {count} {unit} ಲಭ್ಯವಿದೆ',
      'profile': 'ಪ್ರೊಫೈಲ್',
      'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'language': 'ಭಾಷೆ',
      'help_support': 'ಸಹಾಯ ಮತ್ತು ಬೆಂಬಲ',
    },
  };

  void setLanguage(String languageCode) {
    if (_localizedStrings.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }

  String translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ?? _localizedStrings['en']![key] ?? key;
  }

  String translateStockError(String count, String unit) {
    String base = translate('onlyStockAvailable');
    return base.replaceAll('{count}', count).replaceAll('{unit}', unit);
  }
}
