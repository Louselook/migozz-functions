import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class ProfileTest extends StatelessWidget {
  const ProfileTest({super.key});

  @override

  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () {
              // Acción al presionar el ícono de configuración
            },
          ),
        ],
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            children: [
        
              Stack(
                children: [
                  profileImage(source: Image.asset('assets/images/profileBackground.png')),  
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurple,
                      child: CircleAvatar(
                        backgroundColor: Colors.pinkAccent,
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                ],
              ),        
              SizedBox(height: 20),
        
              listBuildBox(text: 'Full name', icon: Icons.account_box, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              listBuildBox(text: 'Nickname', icon: Icons.alternate_email, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              listBuildBox(text: 'Email', icon: Icons.mail, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              listBuildBox(text: 'Cell Phone', icon: Icons.phone, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              listBuildBox(text: 'Date of birth', icon: Icons.calendar_today, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              listBuildBox(text: 'Gender', icon: Icons.transgender, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              listBuildBox(text: 'Location', icon: Icons.public, colorbackground: Colors.grey.withAlpha(50), textColorInside: Colors.white, iconColorInside: Colors.white),
              SizedBox(height: 10),
               Expanded(
                child: ListView.separated(
                  itemCount: 3,
                  cacheExtent: 0,
                  separatorBuilder: (context, index) => SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    final items = [
                      {'text': ' Edit Record', 'icon': Icons.play_circle_outline},
                      {'text': ' Edit My Interes', 'icon': Icons.handshake_outlined},
                      {'text': ' Edit Socials', 'icon': Icons.share_outlined},
                    ];
                    return bottomOptions(
                      text: items[index]['text'] as String,
                      icon: items[index]['icon'] as IconData,
                    );
                  },
                ),
              ),

              GradientButton(
                onPressed: () {},
                width: double.infinity,
                height: 50,
                radius: 8,
                gradient: AppColors.verticalOrangeRed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_outlined, color: Colors.white),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),   

              GradientButton(
                onPressed: () {},
                width: double.infinity,
                height: 50,
                radius: 8,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Widget profileImage({required Image source}) {
    return CircleAvatar(
      radius: 70,
      backgroundImage: source.image, // Imagen de perfil
    );
  }

  Widget listBuildBox({
    required String text, 
    Align? align, // Opcional
    IconData? icon, // Opcional
    Color colorbackground = Colors.white, // Valores por defecto
    Color textColorInside = Colors.black,
    Color iconColorInside = Colors.black,
    }) {
    return Card(
      color: colorbackground,
      child: ListTile(
        textColor: textColorInside,
        iconColor: iconColorInside,
        leading: Icon(icon),
        title: Text(text),
        )
      );
  }

  Widget bottomOptions({required IconData icon, required String text}) {
    return Row(children: [
      Padding(padding:  EdgeInsets.only(right: 15)),
      Icon(icon, color: Colors.white.withAlpha(200)),
      Text(text, style: TextStyle(color: Colors.white.withAlpha(200))),
      ]
    );
  }
}