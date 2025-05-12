import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(EffortEstimatorApp());
}

class EffortEstimatorApp extends StatelessWidget {
  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadToken(),
      builder: (context, snapshot) {
        final initialRoute =
            (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null)
                ? '/home'
                : '/login';

        return MaterialApp(
          title: 'Code Effort Estimator',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
              backgroundColor: Colors.indigo,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
              backgroundColor: Colors.grey[900],
            ),
          ),
          themeMode: ThemeMode.system,
          initialRoute: initialRoute,
          routes: {
            '/login': (context) => LoginScreen(),
            '/home': (context) => HomeScreen(),
            '/history': (context) => HistoryScreen(),
          },
        );
      },
    );
  }
}
