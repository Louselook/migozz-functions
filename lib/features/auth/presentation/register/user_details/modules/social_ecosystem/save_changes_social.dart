import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

Future<void> saveSocialChanges(BuildContext context, String userId) async {
  final editCubit = context.read<EditCubit>();

  debugPrint('🔹 Guardando cambios...');
  debugPrint('🔹 socialEcosystem: ${editCubit.state.socialEcosystem}');

  await editCubit.saveAllPendingChanges(userId);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Changes saved successfully!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 5),
    ),
  );

  Navigator.of(context).pop();
}
