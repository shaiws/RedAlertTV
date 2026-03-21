import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/alert_provider.dart';
import 'screens/home_screen.dart';
import 'services/platform_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape on TV, allow any orientation on mobile.
  final isTV = await PlatformService.isAndroidTV();
  if (isTV) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AlertProvider()..setIsTV(isTV),
      child: const RedAlertApp(),
    ),
  );
}

class RedAlertApp extends StatelessWidget {
  const RedAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'Red Alert TV',
          debugShowCheckedModeBanner: false,
          locale: Locale(provider.language),
          supportedLocales: const [
            Locale('en'),
            Locale('he'),
            Locale('ru'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            tabBarTheme: const TabBarTheme(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
              bodyLarge: TextStyle(color: Colors.white),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
