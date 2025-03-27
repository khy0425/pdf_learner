import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/base/base_viewmodel.dart';

class LocaleViewModel extends BaseViewModel {
  static const String _localePrefsKey = 'preferred_locale';
  
  Locale _locale = const Locale('en', '');
  final SharedPreferences _prefs;
  bool _initialized = false;
  
  LocaleViewModel({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences {
    _initViewModel();
  }
  
  Future<void> _initViewModel() async {
    try {
      setLoading(true);
      await _loadSavedLocale();
      setLoading(false);
    } catch (e) {
      setError('Failed to load locale: $e');
    }
  }
  
  Locale get locale => _locale;
  bool get isInitialized => _initialized;
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;
  
  Future<void> _loadSavedLocale() async {
    final savedLocaleString = _prefs.getString(_localePrefsKey);
    
    if (savedLocaleString != null) {
      final parts = savedLocaleString.split('_');
      if (parts.isNotEmpty) {
        final languageCode = parts[0];
        final countryCode = parts.length > 1 ? parts[1] : '';
        
        _locale = Locale(languageCode, countryCode);
      }
    }
    
    _initialized = true;
    notifyListeners();
  }
  
  Future<void> changeLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    
    try {
      setLoading(true);
      _locale = newLocale;
      
      final localeString = newLocale.countryCode != null && newLocale.countryCode!.isNotEmpty
          ? '${newLocale.languageCode}_${newLocale.countryCode}'
          : newLocale.languageCode;
      
      await _prefs.setString(_localePrefsKey, localeString);
      
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError('Failed to change locale: $e');
    }
  }
  
  String getLanguageName(Locale locale) {
    final localeKey = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    
    return AppLocalizations.countryNames[localeKey] ?? 'Unknown';
  }
  
  String get currentLanguageName {
    return getLanguageName(_locale);
  }
} 