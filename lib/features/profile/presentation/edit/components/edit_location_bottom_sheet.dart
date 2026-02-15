import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';

/// Bottom sheet that lets the user choose between automatic GPS detection
/// or manual entry of their location. Supports unlimited re-requests of
/// the location permission.
class EditLocationBottomSheet extends StatefulWidget {
  /// Current stored location (may be empty).
  final LocationDTO currentLocation;

  /// Called with the chosen [LocationDTO] when the user confirms.
  final Future<void> Function(LocationDTO location) onSave;

  /// Called when the user wants to remove their location entirely.
  final Future<void> Function()? onRemove;

  const EditLocationBottomSheet({
    super.key,
    required this.currentLocation,
    required this.onSave,
    this.onRemove,
  });

  @override
  State<EditLocationBottomSheet> createState() =>
      _EditLocationBottomSheetState();
}

enum _LocationMode { choose, auto, manual }

class _EditLocationBottomSheetState extends State<EditLocationBottomSheet> {
  _LocationMode _mode = _LocationMode.choose;
  bool _loading = false;
  String? _errorMessage;
  bool _permDeniedForever = false;

  // Manual entry controllers
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  // Detected location (auto mode)
  LocationDTO? _detectedLocation;

  @override
  void initState() {
    super.initState();
    // Pre-fill manual fields if the user already has a location
    if (widget.currentLocation.hasData) {
      _cityCtrl.text = widget.currentLocation.city;
      _stateCtrl.text = widget.currentLocation.state;
      _countryCtrl.text = widget.currentLocation.country;
    }
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Auto-detect flow
  // ---------------------------------------------------------------------------
  Future<void> _startAutoDetect() async {
    setState(() {
      _mode = _LocationMode.auto;
      _loading = true;
      _errorMessage = null;
      _detectedLocation = null;
      _permDeniedForever = false;
    });

    try {
      final svc = LocationService();
      final lang = context.locale.languageCode == 'es' ? 'es' : 'en';
      final result = await svc.fetchAddressWithReason(lang: lang);

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _loading = false;
          _detectedLocation = result.location;
        });
        return;
      }

      // Handle specific failure reasons
      String msg;
      bool deniedForever = false;

      switch (result.failReason!) {
        case LocationFailReason.serviceDisabled:
          msg = 'edit.editLocation.serviceDisabled'.tr();
          break;
        case LocationFailReason.permissionDenied:
          msg = 'edit.editLocation.permissionDenied'.tr();
          break;
        case LocationFailReason.permissionDeniedForever:
          msg = 'edit.editLocation.permissionDeniedForever'.tr();
          deniedForever = true;
          break;
        case LocationFailReason.coordsFailed:
        case LocationFailReason.apiFailed:
        case LocationFailReason.unknown:
          msg = 'edit.editLocation.errorDetecting'.tr();
          break;
      }

      setState(() {
        _loading = false;
        _errorMessage = msg;
        _permDeniedForever = deniedForever;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'edit.editLocation.errorDetecting'.tr();
      });
    }
  }

  /// Opens the OS app settings so the user can grant location permission.
  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // ---------------------------------------------------------------------------
  // Manual save
  // ---------------------------------------------------------------------------
  Future<void> _saveManual() async {
    final city = _cityCtrl.text.trim();
    final country = _countryCtrl.text.trim();

    if (city.isEmpty) {
      setState(() => _errorMessage = 'edit.editLocation.cityRequired'.tr());
      return;
    }
    if (country.isEmpty) {
      setState(() => _errorMessage = 'edit.editLocation.countryRequired'.tr());
      return;
    }

    final location = LocationDTO(
      city: city,
      state: _stateCtrl.text.trim(),
      country: country,
      lat: 0.0,
      lng: 0.0,
    );

    setState(() => _loading = true);
    await widget.onSave(location);
    if (mounted) Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Confirm auto-detected
  // ---------------------------------------------------------------------------
  Future<void> _confirmDetected() async {
    if (_detectedLocation == null) return;
    setState(() => _loading = true);
    await widget.onSave(_detectedLocation!);
    if (mounted) Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Remove location
  // ---------------------------------------------------------------------------
  Future<void> _removeLocation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          'edit.editLocation.removeLocation'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'edit.editLocation.removeLocationConfirm'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'buttons.cancel'.tr(),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'buttons.confirm'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _loading = true);
      await widget.onRemove?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (_mode == _LocationMode.choose) _buildChooseMode(),
                if (_mode == _LocationMode.auto) _buildAutoMode(),
                if (_mode == _LocationMode.manual) _buildManualMode(),
                // Remove button (only if the user already has a location)
                if (widget.currentLocation.hasData &&
                    widget.onRemove != null &&
                    !_loading) ...[
                  const SizedBox(height: 12),
                  _buildRemoveButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    final title = _mode == _LocationMode.manual
        ? 'edit.editLocation.manualTitle'.tr()
        : 'edit.editLocation.sheetTitle'.tr();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_mode == _LocationMode.choose) ...[
                const SizedBox(height: 4),
                Text(
                  'edit.editLocation.sheetSubtitle'.tr(),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        if (_mode != _LocationMode.choose)
          IconButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _mode = _LocationMode.choose;
                    _errorMessage = null;
                    _detectedLocation = null;
                  }),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: 20,
            ),
          ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Choose mode (two big option cards)
  // ---------------------------------------------------------------------------
  Widget _buildChooseMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _optionCard(
          icon: Icons.gps_fixed,
          title: 'edit.editLocation.autoDetect'.tr(),
          subtitle: 'edit.editLocation.autoDetectDesc'.tr(),
          onTap: _startAutoDetect,
        ),
        const SizedBox(height: 12),
        _optionCard(
          icon: Icons.edit_location_alt_outlined,
          title: 'edit.editLocation.manualEntry'.tr(),
          subtitle: 'edit.editLocation.manualEntryDesc'.tr(),
          onTap: () => setState(() {
            _mode = _LocationMode.manual;
            _errorMessage = null;
          }),
        ),
      ],
    );
  }

  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Auto-detect mode
  // ---------------------------------------------------------------------------
  Widget _buildAutoMode() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'edit.editLocation.detecting'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Error state — allow retry, open settings, or switch to manual
    if (_errorMessage != null && _detectedLocation == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // When permission is denied forever → show "Open Settings" button
          if (_permDeniedForever) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _openAppSettings();
                  // After returning from settings, try again
                  if (mounted) _startAutoDetect();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.settings, size: 18),
                label: Text(
                  'edit.editLocation.openSettings'.tr(),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startAutoDetect,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    'edit.editLocation.autoDetect'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _mode = _LocationMode.manual;
                    _errorMessage = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(
                    'edit.editLocation.manualEntry'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Success — show detected location with confirm button
    if (_detectedLocation != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'edit.editLocation.title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_detectedLocation!.city}, ${_detectedLocation!.state}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _detectedLocation!.country,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _startAutoDetect,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'edit.editLocation.autoDetect'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  onPressed: _confirmDetected,
                  gradient: AppColors.primaryGradient,
                  radius: 10,
                  height: 48,
                  child: Text(
                    'buttons.confirm'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // Manual entry mode
  // ---------------------------------------------------------------------------
  Widget _buildManualMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
        _inputField(
          controller: _cityCtrl,
          hint: 'edit.editLocation.cityHint'.tr(),
          icon: Icons.location_city,
          autofocus: true,
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _stateCtrl,
          hint: 'edit.editLocation.stateHint'.tr(),
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _countryCtrl,
          hint: 'edit.editLocation.countryHint'.tr(),
          icon: Icons.public,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onPressed: _loading ? null : _saveManual,
            gradient: AppColors.primaryGradient,
            radius: 10,
            height: 48,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'buttons.save'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textInputAction: TextInputAction.next,
      onChanged: (_) {
        if (_errorMessage != null) setState(() => _errorMessage = null);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Remove button
  // ---------------------------------------------------------------------------
  Widget _buildRemoveButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _removeLocation,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'edit.editLocation.removeLocation'.tr(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
