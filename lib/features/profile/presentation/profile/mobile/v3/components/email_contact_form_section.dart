import 'package:flutter/material.dart';

class EmailContactFormSection extends StatelessWidget {
  final bool isOwnProfile;

  const EmailContactFormSection({super.key, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Email Contact Form',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // const SizedBox(width: 8),
                  // Container(
                  //   padding: EdgeInsets.all(3),
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,gradient:AppColors.verticalPinkPurple,
                  //   ),
                  //   child:Icon(Icons.edit,color: Colors.white,size: 7,),
                  // ),
                ],
              ),

              GestureDetector(
                onTap: () {
                  // TODO: Editar bio
                  debugPrint('Editar bio');
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white70,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Visitors can share their email with you through a contact form on your profile.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
