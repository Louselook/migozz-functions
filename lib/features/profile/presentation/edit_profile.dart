import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class EditProfile extends StatelessWidget {
  const EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

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
          onPressed: () => context.go('/profile'),
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: 0,
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  profileImage(
                    source: Image.asset('assets/images/profileBackground.png'),
                    radius: screenWidth * 0.18,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: screenWidth * 0.048,
                      backgroundColor: Colors.deepPurple,
                      child: CircleAvatar(
                        backgroundColor: Colors.pinkAccent,
                        child: Icon(
                          Icons.edit,
                          size: screenWidth * 0.042,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),

              listBuildBox(
                text: 'Full name',
                icon: Icons.account_box,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: 'Nickname',
                icon: Icons.alternate_email,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: 'Email',
                icon: Icons.mail,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: 'Cell Phone',
                icon: Icons.phone,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: 'Date of birth',
                icon: Icons.calendar_today,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: 'Gender',
                icon: Icons.transgender,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              listBuildBox(
                text: 'Location',
                icon: Icons.public,
                textColorInside: Colors.white,
                iconColorInside: Colors.white,
              ),
              SizedBox(height: screenHeight * 0.025),

              // Sección de opciones adicionales
              Column(
                children: [
                  bottomOptions(
                    text: ' Edit Record',
                    icon: Icons.play_circle_outline,
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  bottomOptions(
                    text: ' Edit My Interes',
                    icon: Icons.handshake_outlined,
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  bottomOptions(
                    text: ' Edit Socials',
                    icon: Icons.share_outlined,
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.04),

              GradientButton(
                onPressed: () {},
                width: double.infinity,
                height: screenHeight * 0.065,
                radius: screenWidth * 0.02,
                gradient: AppColors.verticalOrangeRed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_outlined,
                      color: Colors.white,
                      size: screenWidth * 0.05,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.012),

              GradientButton(
                onPressed: () {},
                width: double.infinity,
                height: screenHeight * 0.065,
                radius: screenWidth * 0.02,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: screenHeight * 0.025,
              ), // Espacio adicional al final
            ],
          ),
        ),
      ),
    );
  }

  Widget profileImage({required Image source, double radius = 70}) {
    return ClipOval(
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1.15, 0, 0, 0, 0, // R
          0, 1.15, 0, 0, 0, // G
          0, 0, 1.25, 0, 0, // B
          0, 1, 1, 2, 0, // A
        ]),
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.asset(
            'assets/images/profileBackground.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          86,
          153,
          149,
          149,
        ).withValues(alpha: 0.08), // Fondo blanco muy transparente
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3), // Borde gris más visible
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8), // Bordes redondeados
      ),
      child: ListTile(
        textColor: textColorInside,
        iconColor: iconColorInside,
        leading: Icon(icon),
        title: Text(text),
      ),
    );
  }

  Widget bottomOptions({required IconData icon, required String text}) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Row(
          children: [
            Padding(padding: EdgeInsets.only(right: screenWidth * 0.04)),
            Icon(
              icon,
              color: Colors.white.withAlpha(200),
              size: screenWidth * 0.055,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: screenWidth * 0.04,
              ),
            ),
          ],
        );
      },
    );
  }
}
