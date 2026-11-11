import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'logic/memory.dart';
import 'logic/profile.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.open();
  runApp(AstroWayApp(store: store));
}

/// Общие настройки приложения: профиль, тон, крупный шрифт.
class AppState extends ChangeNotifier {
  final Store store;
  final WitchMemory memory;
  AppState(this.store) : memory = WitchMemory(store.prefs);

  Profile? get profile => store.profile;
  bool get easy => store.easyTone;

  bool get large {
    final saved = store.largeFont;
    if (saved != null) return saved;
    final p = profile;
    return p != null && p.ageOn(DateTime.now()) >= 50; // авто для 50+
  }

  Future<void> saveProfile(Profile p) async {
    await store.saveProfile(p);
    await store.setLargeFont(p.ageOn(DateTime.now()) >= 50);
    notifyListeners();
  }

  Future<void> setEasy(bool v) async {
    await store.setEasyTone(v);
    notifyListeners();
  }

  Future<void> setLarge(bool v) async {
    await store.setLargeFont(v);
    notifyListeners();
  }
}

class AstroWayApp extends StatefulWidget {
  final Store store;
  const AstroWayApp({super.key, required this.store});
  @override
  State<AstroWayApp> createState() => _AstroWayAppState();
}

class _AstroWayAppState extends State<AstroWayApp> {
  late final AppState app = AppState(widget.store);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'AstroWay',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(14) / 14 * (app.large ? 1.18 : 1.0)),
          ),
          child: child!,
        ),
        home: app.profile == null ? OnboardingScreen(app: app) : HomeScreen(app: app),
      ),
    );
  }
}
