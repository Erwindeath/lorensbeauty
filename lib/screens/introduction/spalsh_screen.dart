import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lorensbeauty/components/role_based_navigation.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/screens/auth/reset_password_screen.dart';
import 'package:lorensbeauty/screens/introduction/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnimate = true;
  bool isClicked = false;
  bool _handlingPasswordRecovery = false;

  final width = 50;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1), (() {
      setState(() {
        isAnimate = false;
      });
    }));

    //Future.delayed(const Duration(seconds: 5), () {
    checkAuthState();
    /*final session = supabase.auth.currentSession;
      final isSessionExpired = session?.isExpired;

      if (isSessionExpired) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: ((context) => const OnBoardingScreen())));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => const BottomNavigationComponent()));
      }*/
    //});
    super.initState();
  }

  Future<void> checkAuthState() async {
    final supabase = Supabase.instance.client;

    // Escuchar cambios de autenticación incluyendo el estado inicial
    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // Recuperación de contraseña via deep link
      if (event == AuthChangeEvent.passwordRecovery) {
        _handlingPasswordRecovery = true;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          );
        }
        return;
      }

      // Ignorar eventos posteriores si ya se está manejando el reset de contraseña
      if (_handlingPasswordRecovery) return;

      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).fetchUser();
        }
      }
      if (event == AuthChangeEvent.initialSession) {
        if (session != null) {
          navigateTo(const RoleBasedNavigation());
        } else {
          navigateTo(const OnBoardingScreen());
        }
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        navigateTo(const RoleBasedNavigation());
      } else if (event != AuthChangeEvent.passwordRecovery) {
        navigateTo(const OnBoardingScreen());
      }
    });
  }

  void navigateTo(Widget screen) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 150),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedPadding(
                  padding: EdgeInsets.only(top: isAnimate ? 40 : 0),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: AnimatedOpacity(
                    opacity: isAnimate ? 0 : 1,
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInCubic,
                    child: Image.asset(
                      'assets/lorens_new.png',
                      width: MediaQuery.of(context).size.width / 0.5,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                AnimatedPadding(
                  padding: EdgeInsets.only(top: isAnimate ? 40 : 0),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: AnimatedOpacity(
                      opacity: isAnimate ? 0 : 1,
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInCubic,
                      child: const Image(
                        image: AssetImage('assets/Loren-s.gif'),
                      )),
                ),
              ],
            ),
          ),
        ));
  }
}
