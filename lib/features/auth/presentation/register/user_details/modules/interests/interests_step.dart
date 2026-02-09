import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

class Interest {
  final String id;
  final Map<String, String> name;
  final String emoji;
  final int order;
  final String status;

  Interest({
    required this.id,
    required this.name,
    required this.emoji,
    required this.order,
    required this.status,
  });

  String getLocalizedName(String languageCode) =>
      name[languageCode] ?? name['en'] ?? id;
}

class InterestsStep extends StatefulWidget {
  final PageController controller;
  final MoreUserDetailsMode mode;
  const InterestsStep({
    super.key,
    required this.controller,
    this.mode = MoreUserDetailsMode.register,
  });

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  Set<String> selectedInterests = {};
  List<Interest> allInterests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollection();
    _initializeSelectedInterests();
  }

  void _initializeSelectedInterests() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Map<String, List<String>> existingInterests = {};
      if (widget.mode == MoreUserDetailsMode.register) {
        existingInterests = context.read<RegisterCubit>().state.interests ?? {};
      } else {
        existingInterests = context.read<EditCubit>().state.interests ?? {};
      }
      setState(() {
        selectedInterests = existingInterests.values
            .expand((list) => list)
            .toSet();
      });
    });
  }

  Future<void> fetchCollection() async {
    try {
      setState(() => isLoading = true);
      final snapshot = await FirebaseFirestore.instance
          .collection('interests_catalog_new')
          .get();
      final List<Interest> fetchedInterests = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'active') continue;
        fetchedInterests.add(
          Interest(
            id: doc.id,
            name: data['name'] is Map
                ? Map<String, String>.from(data['name'])
                : {'en': data['name'], 'es': data['name']},
            emoji: data['emoji']?.toString() ?? '',
            order: data['order'] ?? 0,
            status: data['status'] ?? 'active',
          ),
        );
      }
      fetchedInterests.sort((a, b) => a.order.compareTo(b.order));
      setState(() {
        allInterests = fetchedInterests;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // En iPhone 16 (height > 800) daremos más aire, en otros apretaremos.
    final bool isSmallDevice = screenHeight < 750;

    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  // Margen superior dinámico
                  SizedBox(height: isSmallDevice ? 10.h : 25.h),

                  PrimaryText(
                    'interestSelect.choose'.tr(),
                    fontSize: 22,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  SecondaryText(
                    'interestSelect.desc'.tr(),
                    fontSize: 14,
                    color: Colors.grey,
                    textAlign: TextAlign.center,
                  ),

                  // ESPACIO FLEXIBLE CENTRAL
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      alignment: Alignment.center,
                      // FittedBox es la magia: si el Wrap es muy grande, lo escala hacia abajo
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 8.w,
                            runSpacing: 10.h,
                            children: allInterests.map((interest) {
                              return _interestChip(
                                name: interest.getLocalizedName(
                                  context.locale.languageCode,
                                ),
                                emoji: interest.emoji,
                                selected: selectedInterests.contains(
                                  interest.id,
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedInterests.contains(interest.id)
                                        ? selectedInterests.remove(interest.id)
                                        : selectedInterests.add(interest.id);
                                  });
                                  _updateCubit();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // BOTÓN SIEMPRE VISIBLE
                  Padding(
                    padding: EdgeInsets.only(bottom: 15.h, top: 10.h),
                    child: _buildActionButton(),
                  ),
                ],
              ),
            ),
    );
  }

  void _updateCubit() {
    final res = {'interests': selectedInterests.toList()};
    widget.mode == MoreUserDetailsMode.register
        ? context.read<RegisterCubit>().setInterests(res)
        : context.read<EditCubit>().updateInterests(res);
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: () {
        _updateCubit();
        Navigator.of(context).pop('done');
      },
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59A3C), Color(0xFFB646F6)],
          ),
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Center(
          child: Text(
            widget.mode == MoreUserDetailsMode.register ? 'Continue' : 'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _interestChip({
    required String name,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFF59A3C), Color(0xFFB646F6)],
                )
              : null,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji.isNotEmpty)
                Text(emoji, style: TextStyle(fontSize: 15.sp)),
              SizedBox(width: 4.w),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
