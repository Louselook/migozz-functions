import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../services/landing_service.dart';
import 'landing_alert.dart';

/// Hero section — "JOIN MIGOZZ!" — White card with username/email form.
/// Mirrors the React JoinMigozz component.
class JoinMigozzSection extends StatefulWidget {
  const JoinMigozzSection({super.key});

  @override
  State<JoinMigozzSection> createState() => _JoinMigozzSectionState();
}

class _JoinMigozzSectionState extends State<JoinMigozzSection> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isUsernameAvailable = false;
  bool _showEmailInput = false;
  String _emailError = '';
  String _usernameError = '';
  bool _isCheckingUsername = false;
  bool _isLoading = false;
  Timer? _debounceTimer;

  // Alert state
  bool _alertOpen = false;
  AlertType _alertType = AlertType.info;
  String _alertMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _showAlert(AlertType type, String message) {
    setState(() {
      _alertOpen = true;
      _alertType = type;
      _alertMessage = message;
    });
  }

  void _closeAlert() {
    setState(() => _alertOpen = false);
  }

  void _onUsernameChanged(String value) {
    setState(() {
      _usernameError = '';
      if (value.trim().isEmpty) {
        _isUsernameAvailable = false;
        _showEmailInput = false;
        _isCheckingUsername = false;
        return;
      }
      _isCheckingUsername = true;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (value.trim().isEmpty) return;
      try {
        final exists = await LandingService.checkUsernameExists(value.trim());
        if (!mounted) return;
        setState(() {
          if (exists) {
            _usernameError = 'landing.alerts.username_taken'.tr(
              namedArgs: {'username': value},
            );
            _isUsernameAvailable = false;
          } else {
            _isUsernameAvailable = true;
          }
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isUsernameAvailable = false;
          _usernameError = 'landing.alerts.check_user_error'.tr();
        });
      } finally {
        if (mounted) setState(() => _isCheckingUsername = false);
      }
    });
  }

  Future<void> _handleClaim() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showAlert(AlertType.warning, 'landing.alerts.enter_username'.tr());
      return;
    }
    if (_usernameError.isNotEmpty) {
      _showAlert(AlertType.error, _usernameError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final exists = await LandingService.checkUsernameExists(username);
      if (!mounted) return;
      if (exists) {
        final msg = 'landing.alerts.username_taken'.tr(
          namedArgs: {'username': username},
        );
        _showAlert(AlertType.error, msg);
        setState(() {
          _usernameError = msg;
          _isUsernameAvailable = false;
        });
      } else {
        _showAlert(
          AlertType.success,
          'landing.alerts.username_available'.tr(
            namedArgs: {'username': username},
          ),
        );
        setState(() => _isUsernameAvailable = true);
      }
    } catch (error) {
      if (!mounted) return;
      final msg = 'landing.alerts.check_user_error'.tr();
      _showAlert(AlertType.error, msg);
      setState(() {
        _usernameError = msg;
        _isUsernameAvailable = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePreSave() async {
    if (!_showEmailInput) {
      if (!_isUsernameAvailable) {
        _handleClaim();
        return;
      }
      setState(() => _showEmailInput = true);
      return;
    }

    // Validate email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      final msg = 'landing.alerts.enter_email'.tr();
      _showAlert(AlertType.warning, msg);
      setState(() => _emailError = msg);
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      final msg = 'landing.alerts.invalid_email'.tr();
      _showAlert(AlertType.warning, msg);
      setState(() => _emailError = msg);
      return;
    }

    setState(() {
      _emailError = '';
      _isLoading = true;
    });

    try {
      // Recheck username
      final userExists = await LandingService.checkUsernameExists(
        _usernameController.text.trim(),
      );
      if (!mounted) return;
      if (userExists) {
        final msg = 'landing.alerts.username_taken_late'.tr(
          namedArgs: {'username': _usernameController.text},
        );
        _showAlert(AlertType.error, msg);
        setState(() {
          _isUsernameAvailable = false;
          _showEmailInput = false;
        });
        return;
      }

      // Check email
      final emailExists = await LandingService.checkEmailExists(email);
      if (!mounted) return;
      if (emailExists) {
        final msg = 'landing.alerts.email_registered'.tr();
        _showAlert(AlertType.error, msg);
        setState(() => _emailError = msg);
        return;
      }

      // Pre-register
      final locale = context.locale.languageCode;
      await LandingService.preRegister(
        username: _usernameController.text.trim(),
        email: email,
        language: locale,
      );
      if (!mounted) return;

      _showAlert(AlertType.success, 'landing.alerts.verification_sent'.tr());
      setState(() {
        _showEmailInput = false;
        _usernameController.clear();
        _emailController.clear();
        _emailError = '';
        _usernameError = '';
        _isUsernameAvailable = false;
      });
    } catch (error) {
      if (!mounted) return;
      final msg = 'landing.alerts.process_error'.tr();
      _showAlert(AlertType.error, msg);
      setState(() => _emailError = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: screenHeight * 0.7, // 70vh like React original
          ),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/landing/backgroundSectionOne.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            // Dark overlay
            color: Colors.black.withValues(alpha: 0.4),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 80 : 100,
              horizontal: isMobile ? 16 : 32,
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 800,
                ),
                padding: EdgeInsets.all(isMobile ? 24 : 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
                      ).createShader(bounds),
                      child: Text(
                        'landing.join_title'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Inter',
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 4),
                    Text(
                      'landing.join_subtitle_one'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 21,
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'landing.join_subtitle_two'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 21,
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // Input section
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: !_showEmailInput
                          ? _buildUsernameInput(isMobile)
                          : _buildEmailInput(isMobile),
                    ),

                    SizedBox(height: isMobile ? 20 : 32),

                    // Pre-Save button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        decoration: BoxDecoration(
                          gradient: (_isUsernameAvailable && !_isLoading)
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF9564),
                                    Color(0xFF9E1B9F),
                                  ],
                                )
                              : null,
                          color: (!_isUsernameAvailable || _isLoading)
                              ? Colors.grey.shade300
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isUsernameAvailable
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF9E1B9F,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed:
                              (_isUsernameAvailable &&
                                  !(_showEmailInput && _isLoading))
                              ? _handlePreSave
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 16 : 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: (_showEmailInput && _isLoading)
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'landing.pre_save_btn'.tr(),
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: isMobile ? 16 : 24),

                    // Security note
                    Text(
                      'landing.security_note_part_1'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 21,
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Alert overlay
        if (_alertOpen)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: LandingAlert(
                type: _alertType,
                message: _alertMessage,
                onClose: _closeAlert,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUsernameInput(bool isMobile) {
    return Column(
      key: const ValueKey('username'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
            border: _usernameError.isNotEmpty
                ? Border.all(color: const Color(0xFFEF4444), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: isMobile
              ? _buildMobileUsernameLayout()
              : _buildDesktopUsernameLayout(),
        ),
        if (_usernameError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _usernameError,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopUsernameLayout() {
    return Row(
      children: [
        // Migozz icon box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF841595), Color(0xFFE02E8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/migozz_icon/Migozz512.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // URL prefix + input
        const Text(
          'migozz.com/',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _usernameController,
            onChanged: _onUsernameChanged,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'landing.username_placeholder'.tr(),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Claim button
        _buildClaimButton(),
      ],
    );
  }

  Widget _buildMobileUsernameLayout() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'migozz.com/',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  onChanged: _onUsernameChanged,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'landing.username_placeholder'.tr(),
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: _buildClaimButton()),
      ],
    );
  }

  Widget _buildClaimButton() {
    Color bgStart = const Color(0xFF841595);
    Color bgEnd = const Color(0xFFE02E8A);

    if (_usernameError.isNotEmpty) {
      bgStart = const Color(0xFFEF4444);
      bgEnd = const Color(0xFFDC2626);
    } else if (_isUsernameAvailable) {
      bgStart = const Color(0xFF10B981);
      bgEnd = const Color(0xFF059669);
    }

    String label;
    if (_usernameError.isNotEmpty) {
      label = 'Not available';
    } else if (_isUsernameAvailable) {
      label = 'Available';
    } else {
      label = 'landing.claim_btn'.tr();
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: (_isLoading || _isCheckingUsername) ? null : _handleClaim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: (_isLoading || _isCheckingUsername)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput(bool isMobile) {
    return Column(
      key: const ValueKey('email'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
            border: _emailError.isNotEmpty
                ? Border.all(color: const Color(0xFFEF4444), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Email icon box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF841595), Color(0xFFE02E8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailError.isNotEmpty) {
                      setState(() => _emailError = '');
                    }
                  },
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'landing.email_placeholder'.tr(),
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_emailError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _emailError,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
