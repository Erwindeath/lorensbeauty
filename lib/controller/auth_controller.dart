import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      print("*********************************************");
      print(googleSignIn);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print("El usuario canceló el inicio de sesión.");
        return null;
      }
      print("asdjaosdjuklasjkdakjsldjklaskjdlaskjld");
      print(googleUser);
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

  static Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await Supabase.instance.client.auth.signOut();

    await googleSignIn.signOut();
print("Sesión cerrada exitosamente.");
  }

  // ============================================
  // MÉTODOS DE AUTENTICACIÓN CON EMAIL/PASSWORD
  // ============================================

  /// Registro de cliente con email y password
  /// Solo clientes pueden auto-registrarse
  static Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print("🔵 Iniciando registro para: $email");

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      print("🔵 Respuesta de signUp: ${response.user?.id}");
      print("🔵 Session: ${response.session != null}");

      if (response.user != null) {
        print("✅ Registro exitoso: ${response.user!.email}");
        print("✅ User ID: ${response.user!.id}");
        // El trigger handle_new_user() creará automáticamente el perfil con role='client'

        // Verificar si el perfil se creó
        try {
          final profile = await Supabase.instance.client
              .from('user_profiles')
              .select()
              .eq('id', response.user!.id)
              .single();
          print("✅ Perfil creado: ${profile['role']}");
        } catch (e) {
          print("⚠️ Error al verificar perfil: $e");
        }
      } else {
        print("⚠️ No se obtuvo usuario en la respuesta");
      }

      return response.user;
    } catch (e, stackTrace) {
      print("❌ Error en registro con email: $e");
      print("❌ Stack trace: $stackTrace");
      rethrow; // Lanzar el error para que la UI lo maneje
    }
  }

  /// Login con email y password
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print("Login exitoso: ${response.user!.email}");
      }

      return response.user;
    } catch (e) {
      print("Error en login con email: $e");
      return null;
    }
  }

  /// Recuperar contraseña
  static Future<bool> resetPassword({required String email}) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.lorensbeauty://login-callback/',
      );
      print("Email de recuperación enviado a: $email");
      return true;
    } catch (e) {
      print("Error al enviar email de recuperación: $e");
      return false;
    }
  }

  // ============================================
  // MÉTODOS SOLO PARA ADMIN
  // ============================================

  /// Crear empleado (Solo admin puede hacerlo)
  /// Este método debe ser llamado desde el panel de admin
  static Future<User?> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final auth = Supabase.instance.client.auth;
      final previousSession = auth.currentSession;
      final previousUserId = auth.currentUser?.id;

      // Crear usuario en auth.users
      final response = await auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        // Actualizar el rol a 'employee' en user_profiles
        await Supabase.instance.client.from('user_profiles').update({
          'role': 'employee',
          'phone': phone,
        }).eq('id', response.user!.id);

        // Evitar que el admin quede logueado como el empleado creado.
        if (previousSession?.refreshToken != null &&
            auth.currentUser?.id != previousUserId) {
          await auth.setSession(previousSession!.refreshToken!);
        }

        print("Empleado creado exitosamente: ${response.user!.email}");
      }

      return response.user;
    } catch (e) {
      print("Error al crear empleado: $e");
      return null;
    }
  }

  /// Cambiar rol de usuario (Solo admin)
  static Future<bool> changeUserRole({
    required String userId,
    required String newRole, // 'admin', 'employee', 'client'
  }) async {
    try {
      await Supabase.instance.client.from('user_profiles').update({
        'role': newRole,
      }).eq('id', userId);

      print("Rol actualizado a: $newRole");
      return true;
    } catch (e) {
      print("Error al cambiar rol: $e");
      return false;
    }
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

  static Future<void> signOut() async {
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

