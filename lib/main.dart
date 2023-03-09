import 'package:shared_preferences/shared_preferences.dart';
import 'package:topography_project/src/Authentication/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';


class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en_EN');

  Locale get locale => _locale;

  void changeLocale(Locale? newLocale) {
    _locale = newLocale ?? const Locale('en_EN');
    notifyListeners();
  }
}


void main() async {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('pt'), // Portuguese
            ],
            locale: provider.locale,
            home: LoginScreen(
                locale: provider.locale,
                onLocaleChange: (newLocale) =>
                    provider.changeLocale(newLocale)),
          );
        }
    );
  }
}