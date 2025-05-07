import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../state/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Colors.black54),
      onSelected: (Locale locale) {
        languageProvider.setLocale(locale);
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<Locale>>[
            PopupMenuItem<Locale>(
              value: const Locale('en'),
              child: Row(
                children: [
                  if (languageProvider.isEnglish)
                    const Icon(Icons.check, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(l10n.english),
                ],
              ),
            ),
            PopupMenuItem<Locale>(
              value: const Locale('zh'),
              child: Row(
                children: [
                  if (languageProvider.isChinese)
                    const Icon(Icons.check, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(l10n.chinese),
                ],
              ),
            ),
          ],
    );
  }
}
