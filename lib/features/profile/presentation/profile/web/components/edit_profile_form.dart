import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_text_field.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';

class EditProfileForm extends StatelessWidget {
  const EditProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state.userProfile;

        // Prepare values safely
        final fullName = user?.displayName ?? '';
        final nickname = user?.username ?? '';
        final email = user?.email ?? '';
        final phone = user?.phone ?? '';
        final gender = user?.gender ?? '';
        final dob = user?.birthDate != null
            ? "${user!.birthDate!.year}-${user.birthDate!.month.toString().padLeft(2, '0')}-${user.birthDate!.day.toString().padLeft(2, '0')}"
            : '';
        final location = user != null
            ? [
                if (user.location.city.isNotEmpty) user.location.city,
                if (user.location.country.isNotEmpty) user.location.country,
              ].join(', ')
            : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileTextField(
              label: 'Full name',
              icon: Icons.person_outline,
              initialValue: fullName,
            ),
            ProfileTextField(
              label: 'Nickname',
              icon: Icons.alternate_email,
              initialValue: nickname,
            ),
            ProfileTextField(
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              initialValue: email,
            ),
            ProfileTextField(
              label: 'Cell Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              initialValue: phone,
            ),
            ProfileTextField(
              label: 'Date of Birth',
              icon: Icons.date_range,
              readOnly: true,
              showArrow: false,
              initialValue: dob,
            ),
            ProfileTextField(
              label: 'Gender',
              icon: Icons.transgender,
              readOnly: true,
              showArrow: false,
              initialValue: gender,
            ),
            ProfileTextField(
              label: 'Location',
              icon: Icons.public,
              readOnly: true,
              showArrow: false,
              initialValue: location,
            ),
          ],
        );
      },
    );
  }
}
