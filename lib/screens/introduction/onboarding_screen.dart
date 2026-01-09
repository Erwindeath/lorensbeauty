import 'package:flutter/material.dart';
import 'package:lorensbeauty/components/role_based_navigation.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/screens/auth/login_screen.dart';
import 'package:lorensbeauty/screens/auth/register_screen.dart';
import 'package:provider/provider.dart';

import '../../controller/auth_controller.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);
  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  ScrollController controller = ScrollController();
  double controllerOffset = 0.0;
  int index = 0;
  void move() {
    controller.animateTo(controllerOffset + 392,
        curve: Curves.easeIn, duration: const Duration(milliseconds: 500));
  }

  bool isRev = false;
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      move();
      setState(() {
        controllerOffset += 392;
      });
    });

    Future.delayed(const Duration(seconds: 8), () {
      move();
      setState(() {
        controllerOffset += 392;
      });
    });
    super.initState();
  }

  List imgUrl = [
    "https://thumbs.dreamstime.com/b/hairdresser-protective-mask-cutting-hair-curly-african-american-client-beauty-salon-free-space-195792989.jpg",
    "https://as2.ftcdn.net/v2/jpg/02/65/48/75/1000_F_265487582_hg1t4uvUI33fhRDTdxVyHTNjv0F5WdX4.jpg",
    "https://www.nextinsurance.com/wp-content/uploads/2018/05/shutterstock_256912663-802x454.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SingleChildScrollView(
              reverse: isRev,
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: imgUrl
                      .map((e) => BannerImages(
                            height: height,
                            width: width,
                            image: e,
                          ))
                      .toList()),
            ),
            SingleChildScrollView(
              reverse: isRev,
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.fastOutSlowIn,
                      height: 5,
                      width: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: controllerOffset < 300
                              ? const Color(0xff721c80).withOpacity(0.8)
                              : Colors.grey.withOpacity(0.8)),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.fastOutSlowIn,
                      height: 5,
                      width: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              300 < controllerOffset && controllerOffset < 600
                                  ? const Color(0xff721c80).withOpacity(0.8)
                                  : Colors.grey.withOpacity(0.8)),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.fastOutSlowIn,
                      height: 5,
                      width: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              600 < controllerOffset && controllerOffset < 800
                                  ? const Color(0xff721c80).withOpacity(0.8)
                                  : Colors.grey.withOpacity(0.8)),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              "Loren's Beauty",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Reserva tus citas de belleza de forma fácil y rápida",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.normal),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Botón de Iniciar Sesión con Email
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff721c80),
                            Color.fromARGB(255, 196, 103, 169),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Iniciar Sesión",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón de Registrarse
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff721c80), width: 2),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Text(
                          "Registrarse",
                          style: TextStyle(
                              color: Color(0xff721c80),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón de Google
                  GestureDetector(
                    onTap: () {
                      Authentication.signInWithGoogle(context: context)
                          .then(((value) {
                        if (value != null) {
                          userProvider.fetchUser();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => const RoleBasedNavigation()),
                          );
                        }
                      }));
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google_logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback si no hay imagen local
                              return const Icon(Icons.account_circle, size: 24, color: Colors.grey);
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Continuar con Google",
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        ));
  }
}

class BannerImages extends StatelessWidget {
  final String image;
  const BannerImages({
    Key? key,
    required this.image,
    required this.height,
    required this.width,
  }) : super(key: key);

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.8 * (height / 3),
      width: width,
      child: Image.network(
        image,
        fit: BoxFit.cover,
      ),
    );
  }
}
