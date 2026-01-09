import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorensbeauty/components/colors.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/screens/introduction/spalsh_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;

const supabaseUrl = 'https://biqrpdzypljvwbbphhyr.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpcXJwZHp5cGxqdndiYnBoaHlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MTk0MjcsImV4cCI6MjA4MzI5NTQyN30.F5iU8a8IitLKHegNq_brloKbg4W3IBeGYLNGu1GkO8c';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    postgrestOptions: const PostgrestClientOptions(
      schema: 'public',
    ),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
    storageOptions: const StorageClientOptions(
      retryAttempts: 10,
    ),
  );

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<UserProvider>(
              create: ((context) => UserProvider()))
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Loren's Beauty",
          theme: ThemeData(
            primarySwatch: Colores.esquemaColor,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }

  ThemeData _buildCustomTheme() {
    const Color primaryColor = Color(0xff721c80);
    const Color scaffoldBackground = Colors.white;

    return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: Colors.grey[300]!,
        ),
        scaffoldBackgroundColor: scaffoldBackground,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ));
  }
}
