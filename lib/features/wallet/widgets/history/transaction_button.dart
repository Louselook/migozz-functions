import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TransactionButton extends StatelessWidget {
  final String icon;
  final String text;
  final String route;

  const TransactionButton({super.key, required this.icon, required this.text, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(route);
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFDC44AA), Color(0xFF9022BA)],
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            UnconstrainedBox(
              child: SvgPicture.asset(
                icon,
                height: 20,
                width: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
