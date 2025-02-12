import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lorensbeauty/screens/introduction/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Authentication {
  final supabase = Supabase.instance.client;

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        signInOption: SignInOption.standard, // Fuerza selector de cuentas
        forceCodeForRefreshToken: true,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print("El usuario canceló el inicio de sesión.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthResponse response =
          await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );
      print(response);

      if (response.session != null) {
        print("Inicio de sesión exitoso con Supabase.");
        return response.user; // Devuelve el usuario autenticado
      } else {
        print("Error al iniciar sesión con Supabase.");
        return null;
      }
    } catch (e) {
      print("Error en la autenticación con Google: $e");
      return null;
    }
  }

  static Future<void> signOut({required BuildContext context}) async {
        final GoogleSignIn googleSignIn = GoogleSignIn();
    Supabase.instance.client.auth.signOut();

    await googleSignIn.signOut();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnBoardingScreen()),
    );
    print("Sesión cerrada exitosamente.");
  }
}

/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authentication {
  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        print(e);
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ["profile", "email"],
      );
      /* try {
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          print("Nombre: ${googleUser.displayName}");
          print("Correo: ${googleUser.email}");
        } else {
          print("El usuario canceló el inicio de sesión.");
        }
      } catch (e) {
        print("Error durante el inicio de sesión: $e");
      }*/
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);

          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
          } else if (e.code == 'invalid-credential') {}
        }
      }
    }
    // print(user);
    return user;
  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e);
    }
  }
}*/
