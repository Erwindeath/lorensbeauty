import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lorensbeauty/components/colors.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/screens/introduction/spalsh_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

const supabaseUrl = 'https://cxicibtkgzegooknaoab.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4aWNpYnRrZ3plZ29va25hb2FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyODc4ODYsImV4cCI6MjA1NDg2Mzg4Nn0.F0TXx-dFQKpfQhK4j28qrNrkoZ_UVeSFLeJqWCm4ADE';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
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
