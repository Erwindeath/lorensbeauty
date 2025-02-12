import 'package:flutter/material.dart';
import 'package:lorensbeauty/controller/auth_controller.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:lorensbeauty/widgets/horizontal_line.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  // final User? user;
  const ProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();

    //print(user);
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
              const SizedBox(
                height: 12.0,
              ),
              const HorizontalLine(),
              const SizedBox(
                height: 20.0,
              ),
              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 35,
                    //foregroundImage: NetworkImage(user!.photoURL.toString()),
                    foregroundImage: user?.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user!.userMetadata!['avatar_url'])
                        : null,
                    child: user?.userMetadata?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 35)
                        : null,
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.userMetadata?['full_name'] ?? "No Name",
                          //user.displayName.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          )),
                      Text(user?.email ?? "No Email",
                          //user.email.toString(),
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 40,
              ),
              const SectionCard(
                header: "My orders",
                desc: "Alreay have 12 orders",
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
                    await  Authentication.signOut(context: context);
                    await Provider.of<UserProvider>(context, listen: false)
                        .fetchUser();
                  },
                  child: const Text("Sign Out"))
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
