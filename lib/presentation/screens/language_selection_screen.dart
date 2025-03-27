import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/locale_viewmodel.dart';
import '../../core/localization/app_localizations.dart';

/// 언어 선택 화면
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeViewModel = Provider.of<LocaleViewModel>(context);
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('select_language')),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: AppLocalizations.supportedLocales.length,
        itemBuilder: (context, index) {
          final locale = AppLocalizations.supportedLocales[index];
          final isSelected = locale.languageCode == localeViewModel.locale.languageCode &&
              locale.countryCode == localeViewModel.locale.countryCode;
          
          return ListTile(
            title: Text(localeViewModel.getLanguageName(locale)),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              localeViewModel.changeLocale(locale);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

/// 앱바에 표시할 언어 선택 드롭다운 버튼
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeViewModel = Provider.of<LocaleViewModel>(context);
    
    return PopupMenuButton<Locale>(
      tooltip: AppLocalizations.of(context).translate('change_language'),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 4),
          Text(localeViewModel.currentLanguageName),
        ],
      ),
      onSelected: (Locale locale) {
        localeViewModel.changeLocale(locale);
      },
      itemBuilder: (BuildContext context) {
        return AppLocalizations.supportedLocales.map((Locale locale) {
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localeViewModel.getLanguageName(locale)),
                if (locale.languageCode == localeViewModel.locale.languageCode &&
                    locale.countryCode == localeViewModel.locale.countryCode)
                  const Icon(Icons.check, color: Colors.green),
              ],
            ),
          );
        }).toList();
      },
    );
  }
} 