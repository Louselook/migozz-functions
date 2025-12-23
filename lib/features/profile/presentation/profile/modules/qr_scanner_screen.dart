import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_search_screen.dart'
    as mobile_profile;
import 'package:migozz_app/features/profile/presentation/profile/web/profile_search_screen.dart'
    as web_profile;
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';
import 'package:migozz_app/features/profile/components/utils/Loader.dart';

/// QR Scanner screen to scan user profile QR codes
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extract username from scanned URL
  /// Expected format: https://migozz.com/profile/username or similar
  String? _extractUsername(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Look for username in path segments
      // Expected patterns:
      // - https://migozz.com/profile/username
      // - https://migozz.com/username
      if (pathSegments.isNotEmpty) {
        // Get the last segment as username
        final username = pathSegments.last;
        if (username.isNotEmpty) {
          return username.toLowerCase();
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error parsing URL: $e');
      return null;
    }
  }

  /// Fetch user data from Firestore by username
  Future<UserDTO?> _fetchUserByUsername(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Try with @ prefix
        final querySnapshot2 = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: '@$username')
            .limit(1)
            .get();

        if (querySnapshot2.docs.isEmpty) {
          return null;
        }

        final data = querySnapshot2.docs.first.data();
        return UserDTO.fromMap(data);
      }

      final data = querySnapshot.docs.first.data();
      return UserDTO.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  /// Handle scanned QR code
  Future<void> _handleQrCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Extract username from URL
      final username = _extractUsername(code);
      
      if (username == null) {
        _showError('profile.qrScanner.invalidFormat'.tr());
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (mounted) {
        showProfileLoader(
          context,
          message: 'edit.presentation.loadingProfile'.tr(),
        );
      }

      // Fetch user data
      final user = await _fetchUserByUsername(username);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (user == null) {
        _showError('profile.qrScanner.userNotFound'.tr());
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Navigate to user profile
      if (mounted) {
        // Close scanner screen
        Navigator.pop(context);
        
        // Navigate to profile based on screen size
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth >= 900) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => web_profile.ProfileSearchScreen(user: user),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => mobile_profile.ProfileSearchScreen(user: user, tutorialKeys: TutorialKeys(),),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling QR code: $e');
      _showError('profile.qrScanner.errorProcessing'.tr());
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    AlertGeneral.show(context, 4, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile.qrScanner.title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _handleQrCode(barcode.rawValue);
              }
            },
          ),
          
          // Overlay with scanning frame
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'profile.qrScanner.instruction'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw overlay with transparent center
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner borders
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      borderPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left, top + scanAreaSize - cornerLength),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
