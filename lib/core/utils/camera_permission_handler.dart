import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized camera permission handler
/// Handles camera permissions properly:
/// - Shows native permission prompt if status is notDetermined
/// - Redirects to Settings only if permission is already denied/permanentlyDenied
class CameraPermissionHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Request camera permission and open camera if granted
  /// Returns the captured image file path, or null if cancelled/denied
  static Future<String?> openCamera({
    int imageQuality = 80,
    BuildContext? context,
  }) async {
    // Check current permission status
    final status = await Permission.camera.status;

    debugPrint('📷 [CameraPermission] Current status: $status');

    // If permission is already granted, open camera directly
    if (status.isGranted) {
      return await _captureImage(imageQuality);
    }

    // If permission is permanently denied, show dialog and redirect to settings
    if (status.isPermanentlyDenied) {
      debugPrint('⛔ [CameraPermission] Permission permanently denied');
      if (context != null && context.mounted) {
        await _showSettingsDialog(context);
      } else {
        await openAppSettings();
      }
      return null;
    }

    // If permission is restricted (iOS parental controls, etc.)
    if (status.isRestricted) {
      debugPrint('⛔ [CameraPermission] Permission restricted');
      if (context != null && context.mounted) {
        await _showSettingsDialog(context);
      }
      return null;
    }

    // If permission is limited (iOS limited access)
    if (status.isLimited) {
      return await _captureImage(imageQuality);
    }

    // If permission is denied or notDetermined, request it
    // This will show the native iOS/Android permission dialog
    debugPrint('🔔 [CameraPermission] Requesting permission (status: $status)');
    final requestResult = await Permission.camera.request();

    debugPrint('📷 [CameraPermission] Request result: $requestResult');

    if (requestResult.isGranted) {
      return await _captureImage(imageQuality);
    } else if (requestResult.isPermanentlyDenied) {
      debugPrint('⛔ [CameraPermission] Permission permanently denied after request');
      if (context != null && context.mounted) {
        await _showSettingsDialog(context);
      }
      return null;
    } else if (requestResult.isDenied) {
      // User denied the permission - just return without showing dialog
      // This allows them to try again later or proceed with other options
      debugPrint('⚠️ [CameraPermission] Permission denied by user');
      return null;
    } else {
      debugPrint('⚠️ [CameraPermission] Permission request returned: $requestResult');
      return null;
    }
  }

  /// Capture image using camera
  static Future<String?> _captureImage(int imageQuality) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
      );

      if (photo != null) {
        debugPrint('✅ [CameraPermission] Photo captured: ${photo.path}');
        return photo.path;
      } else {
        debugPrint('⚠️ [CameraPermission] No photo captured (user cancelled)');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [CameraPermission] Error capturing photo: $e');
      return null;
    }
  }

  /// Show dialog to redirect user to settings
  static Future<void> _showSettingsDialog(BuildContext context) async {
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
            'Camera access is needed to take profile photos and share images in chats. Please enable camera permission in Settings.',
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

  /// Request gallery/photos permission and open gallery if granted
  /// For Android 13+ uses READ_MEDIA_IMAGES (Permission.photos)
  /// For older versions uses READ_EXTERNAL_STORAGE (Permission.storage)
  /// Returns the selected image file path, or null if cancelled/denied
  static Future<String?> openGallery({
    int imageQuality = 80,
    BuildContext? context,
  }) async {
    // Check current permission status (try photos first for Android 13+)
    PermissionStatus status = await Permission.photos.status;

    debugPrint('📸 [GalleryPermission] Photos status: $status');

    // If permission is already granted, open gallery directly
    if (status.isGranted) {
      return await _selectImage(imageQuality);
    }

    // Check storage permission for Android < 13
    final storageStatus = await Permission.storage.status;
    debugPrint('📸 [GalleryPermission] Storage status: $storageStatus');

    if (storageStatus.isGranted) {
      return await _selectImage(imageQuality);
    }

    // If permission is permanently denied, show dialog and redirect to settings
    if (status.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      debugPrint('⛔ [GalleryPermission] Permission permanently denied');
      if (context != null && context.mounted) {
        await _showGallerySettingsDialog(context);
      } else {
        await openAppSettings();
      }
      return null;
    }

    // If permission is restricted (iOS parental controls, etc.)
    if (status.isRestricted || storageStatus.isRestricted) {
      debugPrint('⛔ [GalleryPermission] Permission restricted');
      if (context != null && context.mounted) {
        await _showGallerySettingsDialog(context);
      }
      return null;
    }

    // If permission is limited (iOS limited photo access)
    if (status.isLimited) {
      return await _selectImage(imageQuality);
    }

    // If permission is denied or notDetermined, request it
    // This will show the native iOS/Android permission dialog
    debugPrint('🔔 [GalleryPermission] Requesting permission (status: $status)');

    // Try photos permission first (Android 13+, iOS)
    PermissionStatus requestResult = await Permission.photos.request();

    debugPrint('📸 [GalleryPermission] Photos request result: $requestResult');

    // If photos permission not granted, try storage permission (Android < 13)
    if (!requestResult.isGranted && !requestResult.isLimited) {
      debugPrint('🔔 [GalleryPermission] Trying storage permission (Android < 13)');
      requestResult = await Permission.storage.request();
      debugPrint('📸 [GalleryPermission] Storage request result: $requestResult');
    }

    if (requestResult.isGranted || requestResult.isLimited) {
      return await _selectImage(imageQuality);
    } else if (requestResult.isPermanentlyDenied) {
      debugPrint('⛔ [GalleryPermission] Permission permanently denied after request');
      if (context != null && context.mounted) {
        await _showGallerySettingsDialog(context);
      }
      return null;
    } else if (requestResult.isDenied) {
      // User denied the permission - just return without showing dialog
      // This allows them to try again later or proceed with other options
      debugPrint('⚠️ [GalleryPermission] Permission denied by user');
      return null;
    } else {
      debugPrint('⚠️ [GalleryPermission] Permission request returned: $requestResult');
      return null;
    }
  }

  /// Select image from gallery
  static Future<String?> _selectImage(int imageQuality) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (image != null) {
        debugPrint('✅ [GalleryPermission] Image selected: ${image.path}');
        return image.path;
      } else {
        debugPrint('⚠️ [GalleryPermission] No image selected (user cancelled)');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [GalleryPermission] Error selecting image: $e');
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
            'Gallery access is needed to select photos. Please enable gallery permission in Settings.',
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

