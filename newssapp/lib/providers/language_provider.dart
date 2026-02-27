import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'english';
  String _contentLanguage = 'english';

  String get currentLanguage => _currentLanguage;
  String get contentLanguage => _contentLanguage;
  String get languageCode => _getLanguageCode(_currentLanguage);
  String get contentLanguageCode => _getLanguageCode(_contentLanguage);

  String _getLanguageCode(String lang) {
    switch (lang) {
      case 'hindi': return 'HIN';
      case 'bengali': return 'BEN';
      default: return 'EN';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'HIN': return 'hindi';
      case 'BEN': return 'bengali';
      default: return 'english';
    }
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final appCode = prefs.getString('appLanguage') ?? 'EN';
    final contentCode = prefs.getString('contentLanguage') ?? prefs.getString('language') ?? 'EN';
    _currentLanguage = _getLanguageName(appCode);
    _contentLanguage = _getLanguageName(contentCode);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _currentLanguage = _getLanguageName(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', code);
    notifyListeners();
  }

  Future<void> setContentLanguage(String code) async {
    _contentLanguage = _getLanguageName(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contentLanguage', code);
    await prefs.setString('language', code); // Keep for API compatibility
    notifyListeners();
  }

  String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
  }

  String getCategoryLabel(Map<String, dynamic> category) {
    final labels = category['labels'];
    if (labels != null && labels[_contentLanguage] != null && labels[_contentLanguage].toString().isNotEmpty) {
      return labels[_contentLanguage].toString();
    }
    return category['name']?.toString() ?? '';
  }

  String getNewsContent(Map<String, dynamic> news, String field) {
    final translations = news['translations'];
    if (translations != null && translations[_contentLanguage] != null) {
      final translated = translations[_contentLanguage][field];
      if (translated != null && translated.toString().isNotEmpty) {
        return translated.toString();
      }
    }
    return news[field]?.toString() ?? '';
  }

  String getReelContent(Map<String, dynamic> reel, String field) {
    final translations = reel['translations'];
    if (translations != null && translations[_contentLanguage] != null) {
      final translated = translations[_contentLanguage][field];
      if (translated != null && translated.toString().isNotEmpty) {
        return translated.toString();
      }
    }
    return reel[field]?.toString() ?? '';
  }
}

final Map<String, Map<String, String>> _translations = {
  'app_name': {'english': 'asiaze', 'hindi': 'asiaze', 'bengali': 'asiaze'},
  'tagline': {'english': 'Your World, Simplified', 'hindi': 'आपकी दुनिया, सरल', 'bengali': 'আপনার বিশ্ব, সরলীকৃত'},
  'login': {'english': 'Login', 'hindi': 'लॉगिन', 'bengali': 'লগইন'},
  'email_phone': {'english': 'Email or Phone', 'hindi': 'ईमेल या फोन', 'bengali': 'ইমেল বা ফোন'},
  'password': {'english': 'Password', 'hindi': 'पासवर्ड', 'bengali': 'পাসওয়ার্ড'},
  'signup': {'english': 'Sign Up', 'hindi': 'साइन अप', 'bengali': 'সাইন আপ'},
  'full_name': {'english': 'Full Name', 'hindi': 'पूरा नाम', 'bengali': 'সম্পূর্ণ নাম'},
  'continue': {'english': 'Continue', 'hindi': 'जारी रखें', 'bengali': 'চালিয়ে যান'},
  'or_continue_with': {'english': 'Or continue with', 'hindi': 'या जारी रखें', 'bengali': 'অথবা চালিয়ে যান'},
  'google': {'english': 'Google', 'hindi': 'गूगल', 'bengali': 'গুগল'},
  'dont_have_account': {'english': "Don't have an account?", 'hindi': 'खाता नहीं है?', 'bengali': 'অ্যাকাউন্ট নেই?'},
  'already_have_account': {'english': 'Already have an account?', 'hindi': 'पहले से खाता है?', 'bengali': 'ইতিমধ্যে অ্যাকাউন্ট আছে?'},
  'my_feed': {'english': 'My Feed', 'hindi': 'मेरा फ़ीड', 'bengali': 'আমার ফিড'},
  'my_state': {'english': 'My State', 'hindi': 'मेरा राज्य', 'bengali': 'আমার রাজ্য'},
  'story': {'english': 'Story', 'hindi': 'कहानी', 'bengali': 'গল্প'},
  'profile': {'english': 'Profile', 'hindi': 'प्रोफ़ाइल', 'bengali': 'প্রোফাইল'},
  'settings': {'english': 'Settings', 'hindi': 'सेटिंग्स', 'bengali': 'সেটিংস'},
  'language': {'english': 'Language', 'hindi': 'भाषा', 'bengali': 'ভাষা'},
  'notifications': {'english': 'Notifications', 'hindi': 'सूचनाएं', 'bengali': 'বিজ্ঞপ্তি'},
  'saved': {'english': 'Saved', 'hindi': 'सहेजा गया', 'bengali': 'সংরক্ষিত'},
  'reward': {'english': 'Reward', 'hindi': 'पुरस्कार', 'bengali': 'পুরস্কার'},
  'logout': {'english': 'Logout', 'hindi': 'लॉगआउट', 'bengali': 'লগআউট'},
  'search': {'english': 'Search news...', 'hindi': 'समाचार खोजें...', 'bengali': 'খবর খুঁজুন...'},
  'no_results': {'english': 'No results found', 'hindi': 'कोई परिणाम नहीं मिला', 'bengali': 'কোন ফলাফল পাওয়া যায়নি'},
  'breaking_news': {'english': 'Breaking News', 'hindi': 'ब्रेकिंग न्यूज़', 'bengali': 'ব্রেকিং নিউজ'},
  'choose_language': {'english': 'Choose Your Language', 'hindi': 'अपनी भाषा चुनें', 'bengali': 'আপনার ভাষা চয়ন করুন'},
  'select_interests': {'english': 'Select Your Interests', 'hindi': 'अपनी रुचियां चुनें', 'bengali': 'আপনার আগ্রহ নির্বাচন করুন'},
  'category_preferences': {'english': 'Category Preferences', 'hindi': 'श्रेणी प्राथमिकताएं', 'bengali': 'বিভাগ পছন্দ'},
  'privacy_policy': {'english': 'Privacy Policy', 'hindi': 'गोपनीयता नीति', 'bengali': 'গোপনীয়তা নীতি'},
  'terms_conditions': {'english': 'Terms & Conditions', 'hindi': 'नियम और शर्तें', 'bengali': 'শর্তাবলী'},
  'about_us': {'english': 'About Us', 'hindi': 'हमारे बारे में', 'bengali': 'আমাদের সম্পর্কে'},
  'reward_points': {'english': 'Reward Points', 'hindi': 'पुरस्कार अंक', 'bengali': 'পুরস্কার পয়েন্ট'},
  'invite_friends': {'english': 'Invite Friends', 'hindi': 'दोस्तों को आमंत्रित करें', 'bengali': 'বন্ধুদের আমন্ত্রণ জানান'},
  'articles': {'english': 'Articles', 'hindi': 'लेख', 'bengali': 'নিবন্ধ'},
  'reels': {'english': 'Reels', 'hindi': 'रील्स', 'bengali': 'রিলস'},
  'save': {'english': 'Save', 'hindi': 'सहेजें', 'bengali': 'সংরক্ষণ করুন'},
  'no_news': {'english': 'No news available', 'hindi': 'कोई समाचार उपलब्ध नहीं', 'bengali': 'কোন খবর উপলব্ধ নেই'},
  'no_reels': {'english': 'No reels available', 'hindi': 'कोई रील उपलब्ध नहीं', 'bengali': 'কোন রিল উপলব্ধ নেই'},
  'no_stories': {'english': 'No stories available', 'hindi': 'कोई कहानी उपलब्ध नहीं', 'bengali': 'কোন গল্প উপলব্ধ নেই'},
  'no_saved_articles': {'english': 'No saved articles yet', 'hindi': 'अभी तक कोई लेख सहेजा नहीं गया', 'bengali': 'এখনও কোন নিবন্ধ সংরক্ষিত নেই'},
  'no_saved_reels': {'english': 'No saved reels yet', 'hindi': 'अभी तक कोई रील सहेजी नहीं गई', 'bengali': 'এখনও কোন রিল সংরক্ষিত নেই'},
  'selected_interests': {'english': 'Selected Interests', 'hindi': 'चयनित रुचियां', 'bengali': 'নির্বাচিত আগ্রহ'},
  'all_categories': {'english': 'All Categories', 'hindi': 'सभी श्रेणियां', 'bengali': 'সমস্ত বিভাগ'},
  'your_state': {'english': 'Your State', 'hindi': 'आपका राज्य', 'bengali': 'আপনার রাজ্য'},
  'west_bengal': {'english': 'West Bengal', 'hindi': 'पश्चिम बंगाल', 'bengali': 'পশ্চিমবঙ্গ'},
  'points': {'english': 'Points', 'hindi': 'अंक', 'bengali': 'পয়েন্ট'},
  'redeem': {'english': 'Redeem', 'hindi': 'रिडीम करें', 'bengali': 'রিডিম করুন'},
  'available_rewards': {'english': 'Available Rewards', 'hindi': 'उपलब्ध पुरस्कार', 'bengali': 'উপলব্ধ পুরস্কার'},
  'share_earn': {'english': 'Share news or refer friends to earn more\npoints.', 'hindi': 'अधिक अंक अर्जित करने के लिए समाचार साझा करें या दोस्तों को रेफर करें।', 'bengali': 'আরও পয়েন্ট অর্জন করতে খবর শেয়ার করুন বা বন্ধুদের রেফার করুন।'},
  'no_categories': {'english': 'No categories available', 'hindi': 'कोई श्रेणी उपलब्ध नहीं', 'bengali': 'কোন বিভাগ উপলব্ধ নেই'},
  'select_one_interest': {'english': 'Please select at least one interest', 'hindi': 'कृपया कम से कम एक रुचि चुनें', 'bengali': 'অনুগ্রহ করে অন্তত একটি আগ্রহ নির্বাচন করুন'},
  'preferences_updated': {'english': 'Preferences updated!', 'hindi': 'प्राथमिकताएं अपडेट की गईं!', 'bengali': 'পছন্দ আপডেট হয়েছে!'},
  'content_language': {'english': 'Content Language (News, Stories, Reels)', 'hindi': 'सामग्री भाषा (समाचार, कहानियां, रील)', 'bengali': 'বিষয়বস্তু ভাষা (খবর, গল্প, রিল)'},
  'app_language': {'english': 'App Language (Interface & Options)', 'hindi': 'ऐप भाषा (इंटरफेस और विकल्प)', 'bengali': 'অ্যাপ ভাষা (ইন্টারফেস এবং বিকল্প)'},
  'other_news': {'english': 'Other News', 'hindi': 'अन्य समाचार', 'bengali': 'অন্যান্য খবর'},
};
