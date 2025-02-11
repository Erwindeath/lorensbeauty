import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lorensbeauty/screens/introduction/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnimate = true;
  bool isClicked = false;

  final width = 50;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1), (() {
      setState(() {
        isAnimate = false;
      });
    }));

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: ((context) => const OnBoardingScreen())));
    });
    super.initState();
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
