import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final t = AppLocalizations.of(context);
    
    // 번역이 없으면 기본 아이콘만 표시
    if (t == null) {
      return const Icon(Icons.language);
    }
    
    return PopupMenuButton<Locale>(
      tooltip: t.changeLanguage,
      icon: const Icon(Icons.language),
      onSelected: (Locale locale) {
        localeProvider.setLocale(locale);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('ko', 'KR'),
          child: Row(
            children: [
              const Text('🇰🇷 '),
              Text(t.korean),
              if (localeProvider.locale.languageCode == 'ko')
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('en', 'US'),
          child: Row(
            children: [
              const Text('🇺🇸 '),
              Text(t.english),
              if (localeProvider.locale.languageCode == 'en')
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: InkWell(
            onTap: () {
              localeProvider.setSystemLocale(context);
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                const Icon(Icons.phone_android, size: 20),
                const SizedBox(width: 8),
                Text(t.systemDefault),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 