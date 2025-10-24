import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_text_field.dart';

class EditProfileForm extends StatelessWidget {
  const EditProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        ProfileTextField(
          label: 'Full name',
          icon: Icons.person_outline,
          initialValue: '',
        ),
        ProfileTextField(
          label: 'Nickname',
          icon: Icons.alternate_email,
          initialValue: '',
        ),
        ProfileTextField(
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          initialValue: '',
        ),
        ProfileTextField(
          label: 'Cell Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          initialValue: '',
        ),
        ProfileTextField(
          label: 'Date of Birth',
          icon: Icons.date_range,
          readOnly: true,
          showArrow: false,
          initialValue: '',
        ),
        ProfileTextField(
          label: 'Gender',
          icon: Icons.transgender,
          readOnly: true,
          showArrow: false,
          initialValue: '',
        ),
        ProfileTextField(
          label: 'Location',
          icon: Icons.public,
          readOnly: true,
          showArrow: false,
          initialValue: '',
        ),
      ],
    );
  }
}
