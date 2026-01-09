import 'package:flutter/material.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/screens/profile/settings.admin.dart';
import 'package:lorensbeauty/screens/introduction/spalsh_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    return Scaffold(
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: MediaQuery.of(context).size.height / 5.3,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff721c80),
                      Color.fromARGB(255, 196, 103, 169),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 35.0, horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              foregroundImage:
                                  user?.userMetadata?['avatar_url'] != null
                                      ? NetworkImage(
                                          user!.userMetadata!['avatar_url'])
                                      : null,
                              child: user?.userMetadata?['avatar_url'] == null
                                  ? const Icon(Icons.person, size: 35)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    user?.userMetadata?['full_name'] ??
                                        "Administrador",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text(user?.email ?? "No Email",
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: getSettings(context).length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 1),
              itemBuilder: (context, index) {
                final setting = getSettings(context)[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: setting['onTap'],
                    child: SettingItem(
                      title: setting['title'],
                      icon: setting['icon'],
                      bgColor: setting['bgColor'],
                      iconColor: setting['iconColor'],
                      value: setting['value'],
                      onTap: setting['onTap'],
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    ));
  }
}

List<Map<String, dynamic>> getSettings(BuildContext context) => [
      {
        "title": "Notificaciones",
        "icon": Icons.notifications,
        "bgColor": Colors.blue.shade100,
        "iconColor": Colors.blue,
        "value": null,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente')),
          );
        },
      },
      {
        "title": "Privacidad",
        "icon": Icons.privacy_tip,
        "bgColor": Colors.green.shade100,
        "iconColor": Colors.green,
        "value": null,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente')),
          );
        },
      },
      {
        "title": "Ayuda y Soporte",
        "icon": Icons.help_outline,
        "bgColor": Colors.orange.shade100,
        "iconColor": Colors.orange,
        "value": null,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Contacta a soporte@lorensbeauty.com')),
          );
        },
      },
      {
        "title": "Acerca de",
        "icon": Icons.info_outline,
        "bgColor": Colors.purple.shade100,
        "iconColor": Colors.purple,
        "value": null,
        "onTap": () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Loren\'s Beauty'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sistema de Gestión de Salón de Belleza'),
                  SizedBox(height: 8),
                  Text('Versión: 1.0.0'),
                  SizedBox(height: 8),
                  Text('© 2024 Loren\'s Beauty'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        },
      },
      {
        "title": "Cerrar Sesión",
        "icon": Icons.logout,
        "bgColor": Colors.red.shade100,
        "iconColor": Colors.red,
        "value": null,
        "onTap": () async {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cerrar Sesión'),
              content:
                  const Text('¿Estás seguro de que quieres cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const SplashScreen()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al cerrar sesión: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          );
        },
      },
    ];
