import 'package:flutter/material.dart';
import 'package:lorensbeauty/controller/auth_controller.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class CardAdmin extends StatelessWidget {
  final Color? backgroundColor;
  final Color? settingColor;
  final double? cardRadius;
  final Color? backgroundMotifColor;
  final Widget? cardActionWidget;
  final String? userName;
  final Widget? userMoreInfo;
  final ImageProvider userProfilePic;

  CardAdmin({
    this.backgroundColor,
    this.settingColor,
    this.cardRadius = 30,
    required this.userName,
    this.backgroundMotifColor = Colors.white,
    this.cardActionWidget,
    this.userMoreInfo,
    required this.userProfilePic,
  });

  @override
  Widget build(BuildContext context) {
    var mediaQueryHeight = MediaQuery.of(context).size.height;
    return Container(
      height: mediaQueryHeight / 4,
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
            bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /*Align(
            alignment: Alignment.bottomLeft,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: backgroundMotifColor!.withOpacity(.1),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 400,
              backgroundColor: backgroundMotifColor!.withOpacity(.05),
            ),
          ),*/
          Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: (cardActionWidget != null)
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // User profile
                    Expanded(
                      child: CircleAvatar(
                        radius: mediaQueryHeight / 15,
                        backgroundImage: userProfilePic,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: mediaQueryHeight / 30,
                              color: Colors.white,
                            ),
                          ),
                          if (userMoreInfo != null) ...[
                            userMoreInfo!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: settingColor ?? Theme.of(context).cardColor,
                  ),
                  child: (cardActionWidget != null)
                      ? cardActionWidget
                      : Container(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final IconData leadingIcon;
  final String title;
  final IconData trailingIcon;
  final VoidCallback onTap;

  MenuItem({
    required this.leadingIcon,
    required this.title,
    required this.trailingIcon,
    required this.onTap,
  });
}

List<MenuItem> adminMenuItems(BuildContext context) {
  return [
    MenuItem(
      leadingIcon: Icons.category,
      title: 'Crear Categorías',
      trailingIcon: Icons.arrow_forward_ios_outlined,
      onTap: () {
        // Acción para crear categorías
      },
    ),
    MenuItem(
      leadingIcon: Icons.shopping_cart,
      title: 'Administrar Productos',
      trailingIcon: Icons.arrow_forward_ios_outlined,
      onTap: () {
        // Acción para administrar productos
      },
    ),
    MenuItem(
      leadingIcon: Icons.supervised_user_circle,
      title: 'Administrar Usuarios',
      trailingIcon: Icons.arrow_forward_ios_outlined,
      onTap: () {
        // Acción para administrar usuarios
      },
    ),
    MenuItem(
      leadingIcon: Icons.settings,
      title: 'Administrar Servicios',
      trailingIcon: Icons.arrow_forward_ios_outlined,
      onTap: () {
        // Acción para administrar servicios
      },
    ),
    MenuItem(
      leadingIcon: Icons.logout,
      title: 'Cerrar Sesión',
      trailingIcon: Icons.arrow_forward_ios_outlined,
      onTap: () async {
        await Authentication.signOut(context: context);
        await Provider.of<UserProvider>(context, listen: false).fetchUser();
      },
    ),
  ];
}
