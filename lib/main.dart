import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topography_project/src/Authentication/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:topography_project/src/HomePage/presentation/homepage_screen.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en_EN');

  Locale get locale => _locale;

  void changeLocale(Locale? newLocale) {
    _locale = newLocale ?? const Locale('en_EN');
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterMapTileCaching.initialise();
  final store = FlutterMapTileCaching.instance('savedTiles');
  store.manage.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: AppContainer(),
    ),
  );
}

Future<String> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  return token;
}

class AppContainer extends StatelessWidget {
  const AppContainer({
    Key? key,
  }) : super(key: key);

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
          home: FutureBuilder<String>(
            future: _getToken(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final token = snapshot.data;
              print(token);
              if (token == null || token.isEmpty) {
                return LoginScreen(
                  locale: provider.locale,
                  onLocaleChange: (newLocale) =>
                      provider.changeLocale(newLocale),
                );
              } else {
                return MyHomePage(
                  locale: provider.locale,
                  onLocaleChange: (newLocale) =>
                      provider.changeLocale(newLocale),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
}
