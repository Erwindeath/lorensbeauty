import 'package:flutter/material.dart';
import 'package:lorensbeauty/components/colors.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/screens/profile/settings.admin.dart';
import 'package:provider/provider.dart';

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
                              //foregroundImage: NetworkImage(user!.photoURL.toString()),
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
                                        "No Name",
                                    //user.displayName.toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text(user?.email ?? "No Email",
                                    //user.email.toString(),
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                            const Spacer(),
                            /* ForwardButton(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const EditAccountScreen(),
                                        ),
                                      );
                                    },
                                  )*/
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
              physics:
                  const NeverScrollableScrollPhysics(), // Para evitar conflictos con el ScrollView padre
              itemCount: settings.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 1), // Espaciado entre elementos
              itemBuilder: (context, index) {
                final setting = settings[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SettingItem(
                    title: setting['title'],
                    icon: setting['icon'],
                    bgColor: setting['bgColor'],
                    iconColor: setting['iconColor'],
                    value: setting['value'],
                    onTap: setting['onTap'],
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

final List<Map<String, dynamic>> settings = [
  {
    "title": "Language",
    "icon": Icons.wordpress,
    "bgColor": Colors.orange.shade100,
    "iconColor": Colors.orange,
    "value": "English",
    "onTap": () {},
  },
  {
    "title": "Notifications",
    "icon": Icons.notifications,
    "bgColor": Colors.blue.shade100,
    "iconColor": Colors.blue,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
  {
    "title": "Help",
    "icon": Icons.help,
    "bgColor": Colors.red.shade100,
    "iconColor": Colors.red,
    "onTap": () {},
  },
];
