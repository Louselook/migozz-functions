import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized camera permission handler
/// Uses image_picker directly which handles native permission dialogs automatically
class CameraPermissionHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Open camera - image_picker handles permission dialogs automatically
  /// Returns the captured image file path, or null if cancelled/denied
  static Future<String?> openCamera({
    int imageQuality = 80,
    BuildContext? context,
  }) async {
    debugPrint('📷 [CameraPermission] Opening camera directly via image_picker...');

    try {
      // image_picker automatically shows native permission dialog on iOS/Android
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );

      if (photo != null) {
        debugPrint('✅ [CameraPermission] Photo captured: ${photo.path}');
        return photo.path;
      } else {
        debugPrint('⚠️ [CameraPermission] No photo captured (user cancelled or denied)');
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('❌ [CameraPermission] Platform exception: ${e.code} - ${e.message}');

      // If permission denied, show settings dialog
      if (e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied' ||
          e.message?.toLowerCase().contains('denied') == true) {
        if (context != null && context.mounted) {
          await _showCameraSettingsDialog(context);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CameraPermission] Error: $e');
      return null;
    }
  }

  /// Show dialog to redirect user to settings for camera permission
  static Future<void> _showCameraSettingsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Camera Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Camera access is needed to take photos. Please enable camera permission in Settings.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Open gallery - image_picker handles permission dialogs automatically
  /// Returns the selected image file path, or null if cancelled/denied
  static Future<String?> openGallery({
    int imageQuality = 80,
    BuildContext? context,
  }) async {
    debugPrint('📸 [GalleryPermission] Opening gallery directly via image_picker...');

    try {
      // image_picker automatically shows native permission dialog on iOS/Android
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (image != null) {
        debugPrint('✅ [GalleryPermission] Image selected: ${image.path}');
        return image.path;
      } else {
        debugPrint('⚠️ [GalleryPermission] No image selected (user cancelled or denied)');
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('❌ [GalleryPermission] Platform exception: ${e.code} - ${e.message}');

      // If permission denied, show settings dialog
      if (e.code == 'photo_access_denied' ||
          e.message?.toLowerCase().contains('denied') == true) {
        if (context != null && context.mounted) {
          await _showGallerySettingsDialog(context);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [GalleryPermission] Error: $e');
      return null;
    }
  }

  /// Show dialog to redirect user to settings for gallery permission
  static Future<void> _showGallerySettingsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Gallery Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Gallery access is needed to select photos. Please enable photo library permission in Settings.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        );
      },
    );
  }
}

