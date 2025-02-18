import 'package:flutter/material.dart';
import 'package:lorensbeauty/screens/profile/profile_admin.dart';

class ProfileScreen extends StatelessWidget {
  final int role; // 1: usuario normal, 2: administrador

  const ProfileScreen({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (role == 2) {
      return const AdminProfileScreen();
    } else {
      return const NormalProfileScreen();
    }
  }
}

