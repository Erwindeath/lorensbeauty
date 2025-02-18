import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:lorensbeauty/components/profile_menu.dart';
import 'package:lorensbeauty/controller/auth_controller.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/widgets/horizontal_line.dart';
import 'package:provider/provider.dart';

// Widget para el perfil normal (usuario no administrador)
class NormalProfileScreen extends StatelessWidget {
  const NormalProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Profile",
                style: TextStyle(
                    color: Color(0xff721c80),
                    fontWeight: FontWeight.bold,
                    fontSize: 32),
              ),
              const SizedBox(height: 12.0),
              const HorizontalLine(),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    foregroundImage: user?.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user!.userMetadata!['avatar_url'])
                        : null,
                    child: user?.userMetadata?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 35)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['full_name'] ?? "No Name",
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? "No Email",
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),
              const SectionCard(
                header: "My orders",
                desc: "Already have 12 orders",
              ),
              const SectionCard(
                header: "Shipping address",
                desc:
                    "Robert Robertson, 1234 NW Bobcat Lane, St. Robert, MO 65584-5678.",
              ),
              const SectionCard(
                header: "Payments method",
                desc: "Visa **34",
              ),
              const SectionCard(
                header: "Promocodes",
                desc: "You have special offers",
              ),
              const SectionCard(
                header: "My reviews",
                desc: "Reviews for 4 barbers",
              ),
              const SectionCard(
                header: "Settings",
                desc: "Notification, password",
              ),
              ElevatedButton(
                onPressed: () async {
                  await Authentication.signOut(context: context);
                  await Provider.of<UserProvider>(context, listen: false)
                      .fetchUser();
                },
                child: const Text("Sign Out"),
              ),
              // Opcionalmente, un botón para subir producto
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para el perfil de administrador (menú de configuración)
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Scaffold(
        body: Container(
          color: Colors.white54,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CardAdmin(
                  backgroundColor: Color(0xff721c80),
                  userName: user?.userMetadata?['full_name'] ?? "No Name",
                  userProfilePic: user?.userMetadata?['avatar_url'] != null
                      ? NetworkImage(user!.userMetadata!['avatar_url'])
                      : const AssetImage("assets/shop.png") as ImageProvider,
                  cardActionWidget: SettingsItem(
                    icons: Icons.edit,
                    iconStyle: IconStyle(
                      withBackground: true,
                      borderRadius: 50,
                      backgroundColor: Colors.yellow[600],
                    ),
                    title: "Modify",
                    subtitle: "Tap to change your data",
                    onTap: () {
                     
                    },
                  ),
                ),
              ),
              // Perfil del usuario (puedes adaptarlo a lo que necesites)
              /* Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    foregroundImage: user?.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user!.userMetadata!['avatar_url'])
                        : null,
                    child: user?.userMetadata?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 35)
                        : null,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.userMetadata?['full_name'] ?? "No Name",
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 26),
                  )
                ],
              ),*/

              // Aquí va el menú dinámico usando SettingsGroup
              Expanded(
                child: ListView(
                  children: [
                    SettingsGroup(
                      items: adminMenuItems(context)
                          .map(
                            (menuItem) => SettingsItem(
                              onTap: menuItem.onTap,
                              icons: menuItem.leadingIcon,
                              title: menuItem.title,
                              trailing: Icon(
                                menuItem.trailingIcon,
                                color: Colors.black54,
                              ),
                              // Opcional: puedes configurar el estilo del ícono
                              iconStyle: IconStyle(
                                withBackground: true,
                                backgroundColor:
                                    Colors.blueAccent.withOpacity(0.2),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String header;
  final String desc;
  const SectionCard({
    Key? key,
    required this.header,
    required this.desc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: const TextStyle(
              color: Color(0xff721c80),
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(desc,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
            )),
        const SizedBox(height: 12),
        const HorizontalLine(),
        const SizedBox(height: 12),
      ],
    );
  }
}
