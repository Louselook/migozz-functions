import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

/// Pantalla que muestra un QR y permite compartir el enlace del perfil
/// de un usuario. Si no se pasa [userId], se usa el usuario logueado.
class ProfileQrScreen extends StatefulWidget {
  final String?
  userId; // Usuario objetivo (otro perfil). Si es null => current user
  final String?
  overrideUsername; // Permite pasar username directo y evitar fetch
  final String?
  overrideDisplayName; // Permite pasar displayName directo y evitar fetch

  const ProfileQrScreen({
    super.key,
    this.userId,
    this.overrideUsername,
    this.overrideDisplayName,
  });

  @override
  State<ProfileQrScreen> createState() => _ProfileQrScreenState();
}

enum BackgroundMode { emoji, colors, image }

class _ProfileQrScreenState extends State<ProfileQrScreen> {
  late Future<_ProfileData> _futureProfile;
  String? _selectedEmoji; // Track selected emoji
  Color _qrColor = const Color(0xFFD43AB6); // Default QR color
  BackgroundMode _currentMode = BackgroundMode.emoji; // Current mode
  List<Color>? _selectedGradient; // Track selected gradient
  String?
  _selectedImagePath; // Track selected image (file path for mobile, base64 for web)
  Uint8List? _selectedImageBytes; // Store image bytes for web
  final GlobalKey _screenshotKey = GlobalKey(); // Key for screenshot

  static const String _baseProfileUrl =
      'https://migozz-e2a21.web.app/u'; // Cambia a tu dominio real

  static const List<String> _emojiImages = [
    'assets/emojis/emoji_1.png',
    'assets/emojis/emoji_2.png',
  ];

  static const List<List<Color>> _gradientOptions = [
    [Color(0xFFD43AB6), Color(0xFFFF6B9D)], // Pink gradient
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)], // Red-Orange gradient
    [Color(0xFF4ECDC4), Color(0xFF44A08D)], // Teal gradient
    [Color(0xFFFFE66D), Color(0xFFFFAF40)], // Yellow-Orange gradient
    [Color(0xFF95E1D3), Color(0xFF38EF7D)], // Mint-Green gradient
    [Color(0xFFF38181), Color(0xFFFCE38A)], // Coral-Yellow gradient
    [Color(0xFFAA96DA), Color(0xFFFCBF49)], // Purple-Gold gradient
    [Color(0xFF667EEA), Color(0xFF764BA2)], // Blue-Purple gradient
    [Color(0xFF06FFA5), Color(0xFF00D4FF)], // Green-Cyan gradient
    [Color(0xFFFF0844), Color(0xFFFFB199)], // Red-Pink gradient
  ];

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfileData();
    _loadSavedState();
  }

  // Load all saved state from SharedPreferences
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved mode
    final savedMode = prefs.getString('background_mode');
    if (savedMode != null) {
      setState(() {
        _currentMode = BackgroundMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => BackgroundMode.emoji,
        );
      });
    }

    // Load saved emoji
    final savedEmoji = prefs.getString('selected_emoji_background');
    if (savedEmoji != null) {
      setState(() {
        _selectedEmoji = savedEmoji;
      });
      await _extractColorFromEmoji(savedEmoji);
    }

    // Load saved gradient
    final savedGradient = prefs.getStringList('selected_gradient');
    if (savedGradient != null && savedGradient.length == 2) {
      final gradient = [
        Color(int.parse(savedGradient[0])),
        Color(int.parse(savedGradient[1])),
      ];
      setState(() {
        _selectedGradient = gradient;
        _qrColor = gradient[0];
      });
    }

    // Load saved image path
    final savedImage = prefs.getString('selected_image_path');
    if (savedImage != null) {
      if (kIsWeb) {
        // For web, savedImage is base64 encoded
        try {
          final bytes = base64Decode(savedImage);
          setState(() {
            _selectedImagePath = savedImage;
            _selectedImageBytes = bytes;
          });
          await _extractColorFromImageBytes(bytes);
        } catch (e) {
          debugPrint('Error loading saved image on web: $e');
        }
      } else {
        // For mobile, check if file exists
        if (File(savedImage).existsSync()) {
          setState(() {
            _selectedImagePath = savedImage;
          });
          await _extractColorFromImage(savedImage);
        }
      }
    }
  }

  // Save current mode
  Future<void> _saveMode(BackgroundMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_mode', mode.toString());
  }

  // Extract dominant color from emoji image
  Future<void> _extractColorFromEmoji(String emojiPath) async {
    try {
      final ByteData data = await rootBundle.load(emojiPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Sample pixels from the center of the image
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      // Get center pixel color
      final int width = image.width;
      final int height = image.height;
      final int centerX = width ~/ 2;
      final int centerY = height ~/ 2;
      final int pixelIndex = (centerY * width + centerX) * 4;

      final int r = byteData.getUint8(pixelIndex);
      final int g = byteData.getUint8(pixelIndex + 1);
      final int b = byteData.getUint8(pixelIndex + 2);

      setState(() {
        _qrColor = Color.fromRGBO(r, g, b, 1.0);
      });
    } catch (e) {
      debugPrint('Error extracting color: $e');
      // Keep default color on error
    }
  }

  // Save selected emoji to SharedPreferences
  Future<void> _saveSelectedEmoji(String? emojiPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (emojiPath == null) {
      await prefs.remove('selected_emoji_background');
    } else {
      await prefs.setString('selected_emoji_background', emojiPath);
    }
  }

  // Save selected gradient
  Future<void> _saveSelectedGradient(List<Color>? gradient) async {
    final prefs = await SharedPreferences.getInstance();
    if (gradient == null) {
      await prefs.remove('selected_gradient');
    } else {
      final gradientStrings = gradient.map((c) => c.r.toString()).toList();
      await prefs.setStringList('selected_gradient', gradientStrings);
    }
  }

  // Save selected image path
  Future<void> _saveSelectedImage(String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    if (imagePath == null) {
      await prefs.remove('selected_image_path');
    } else {
      await prefs.setString('selected_image_path', imagePath);
    }
  }

  Future<_ProfileData> _loadProfileData() async {
    // Si ya vienen los datos, retornarlos sin ir a Firestore
    if (widget.overrideUsername != null && widget.overrideDisplayName != null) {
      final link = _buildUrl(widget.overrideUsername!);
      return _ProfileData(
        username: widget.overrideUsername!,
        displayName: widget.overrideDisplayName!,
        link: link,
      );
    }

    final current = FirebaseAuth.instance.currentUser;
    final targetId = widget.userId ?? current?.uid;
    if (targetId == null) {
      return _ProfileData(
        username: 'unknown',
        displayName: 'Unknown',
        link: _buildUrl('unknown'),
      );
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .get();
      final data = doc.data() ?? {};
      final usernameRaw = (data['username'] as String?) ?? 'user';
      final username = usernameRaw.replaceFirst('@', '');
      final displayName = (data['displayName'] as String?) ?? username;
      final link = _buildUrl(username);
      return _ProfileData(
        username: username,
        displayName: displayName,
        link: link,
      );
    } catch (e) {
      debugPrint('Error cargando perfil para QR: $e');
      return _ProfileData(
        username: 'error',
        displayName: 'Error',
        link: _buildUrl('error'),
      );
    }
  }

  String _buildUrl(String username) =>
      '$_baseProfileUrl/${username.toLowerCase()}';

  void _shareProfile(_ProfileData data) {
    Share.share(
      'Mira el perfil de ${data.displayName} en Migozz: ${data.link}',
      subject: 'Perfil de ${data.displayName}',
    );
  }

  // Toggle between modes
  void _toggleMode() {
    setState(() {
      switch (_currentMode) {
        case BackgroundMode.emoji:
          _currentMode = BackgroundMode.colors;
          break;
        case BackgroundMode.colors:
          _currentMode = BackgroundMode.image;
          break;
        case BackgroundMode.image:
          _currentMode = BackgroundMode.emoji;
          break;
      }
    });
    _saveMode(_currentMode);
  }

  // Get button label based on current mode
  String _getButtonLabel() {
    switch (_currentMode) {
      case BackgroundMode.emoji:
        return 'Emoji';
      case BackgroundMode.colors:
        return 'Colors';
      case BackgroundMode.image:
        return 'Image';
    }
  }

  // Handle background tap based on current mode
  void _handleBackgroundTap() {
    switch (_currentMode) {
      case BackgroundMode.emoji:
        _showEmojiPicker();
        break;
      case BackgroundMode.colors:
        _showColorPicker();
        break;
      case BackgroundMode.image:
        _showImagePicker();
        break;
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Emoji',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _emojiImages.length + 1, // +1 for default option
                itemBuilder: (context, index) {
                  // First item is "Default"
                  if (index == 0) {
                    final isSelected = _selectedEmoji == null;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = null;
                          _selectedGradient = null;
                          _selectedImagePath = null;
                          _qrColor = const Color(
                            0xFFD43AB6,
                          ); // Reset to default color
                        });
                        _saveSelectedEmoji(null);
                        _saveSelectedGradient(null);
                        _saveSelectedImage(null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD43AB6)
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                          gradient: const RadialGradient(
                            center: Alignment(-0.5, -0.5),
                            radius: 1.2,
                            colors: [
                              Color.fromARGB(255, 184, 107, 255),
                              Color.fromARGB(255, 243, 198, 35),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Emoji items
                  final emojiPath = _emojiImages[index - 1];
                  final isSelected = _selectedEmoji == emojiPath;

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedEmoji = emojiPath;
                        _selectedGradient = null;
                        _selectedImagePath = null;
                      });
                      _saveSelectedEmoji(emojiPath);
                      _saveSelectedGradient(null);
                      _saveSelectedImage(null);
                      await _extractColorFromEmoji(emojiPath);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD43AB6)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(emojiPath, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Colors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _gradientOptions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = _selectedGradient == null;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGradient = null;
                          _selectedEmoji = null;
                          _selectedImagePath = null;
                          _qrColor = const Color(0xFFD43AB6);
                        });
                        _saveSelectedGradient(null);
                        _saveSelectedEmoji(null);
                        _saveSelectedImage(null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD43AB6)
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                          gradient: const RadialGradient(
                            colors: [
                              Color.fromARGB(255, 184, 107, 255),
                              Color.fromARGB(255, 243, 198, 35),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final gradient = _gradientOptions[index - 1];
                  final isSelected = _selectedGradient == gradient;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGradient = gradient;
                        _selectedEmoji = null;
                        _selectedImagePath = null;
                        _qrColor = gradient[0]; // Use first color for QR
                      });
                      _saveSelectedGradient(gradient);
                      _saveSelectedEmoji(null);
                      _saveSelectedImage(null);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFD43AB6)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, read and save image bytes as base64
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _selectedImagePath = base64Image; // Store base64 for web
          _selectedImageBytes = bytes;
          _selectedEmoji = null;
          _selectedGradient = null;
        });

        _saveSelectedImage(base64Image);
        _saveSelectedEmoji(null);
        _saveSelectedGradient(null);
        await _extractColorFromImageBytes(bytes);
      } else {
        // For mobile, save file path
        final imagePath = pickedFile.path;
        setState(() {
          _selectedImagePath = imagePath;
          _selectedImageBytes = null;
          _selectedEmoji = null;
          _selectedGradient = null;
        });

        _saveSelectedImage(imagePath);
        _saveSelectedEmoji(null);
        _saveSelectedGradient(null);
        await _extractColorFromImage(imagePath);
      }
    }
  }

  Future<void> _extractColorFromImageBytes(Uint8List bytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      final int width = image.width;
      final int height = image.height;
      final int centerX = width ~/ 2;
      final int centerY = height ~/ 2;
      final int pixelIndex = (centerY * width + centerX) * 4;

      final int r = byteData.getUint8(pixelIndex);
      final int g = byteData.getUint8(pixelIndex + 1);
      final int b = byteData.getUint8(pixelIndex + 2);

      setState(() {
        _qrColor = Color.fromRGBO(r, g, b, 1.0);
      });
    } catch (e) {
      debugPrint('Error extracting color from image bytes: $e');
    }
  }

  Future<void> _extractColorFromImage(String imagePath) async {
    try {
      // For mobile, read from file
      final File imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      await _extractColorFromImageBytes(bytes);
    } catch (e) {
      debugPrint('Error extracting color from image: $e');
    }
  }

  Future<void> _captureAndSaveScreenshot() async {
    try {
      // Capture the screenshot
      RenderRepaintBoundary boundary =
          _screenshotKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // For web, trigger download
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'migozz_qr_${DateTime.now().millisecondsSinceEpoch}.png',
          )
          ..click();
        html.Url.revokeObjectUrl(url);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code downloaded!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Mobile: Save to app directory first
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final imagePath = '${directory.path}/migozz_qr_$timestamp.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(pngBytes);

        // Try to save to Downloads folder (Android/iOS)
        try {
          Directory? downloadsDir;
          if (Platform.isAndroid) {
            downloadsDir = Directory('/storage/emulated/0/Download');
            if (!await downloadsDir.exists()) {
              downloadsDir = await getExternalStorageDirectory();
            }
          } else if (Platform.isIOS) {
            downloadsDir = await getApplicationDocumentsDirectory();
          }

          if (downloadsDir != null) {
            final downloadPath =
                '${downloadsDir.path}/migozz_qr_$timestamp.png';
            final downloadFile = File(downloadPath);
            await downloadFile.writeAsBytes(pngBytes);
            debugPrint('Saved to: $downloadPath');
          }
        } catch (e) {
          debugPrint('Could not save to downloads: $e');
        }

        // Share the image
        await Share.shareXFiles([
          XFile(imagePath),
        ], text: 'Check out my Migozz profile!');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code saved and shared!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save QR Code'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        // Tintes y gradientes
        fit: StackFit.expand,
        children: [
          // Wrap the content to be captured in RepaintBoundary
          RepaintBoundary(
            key: _screenshotKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background with GestureDetector
                GestureDetector(
                  onTap: _handleBackgroundTap,
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Show background based on selection
                        if (_selectedImagePath != null)
                          Opacity(
                            opacity: 0.6,
                            child: kIsWeb
                                ? (_selectedImageBytes != null
                                      ? Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : const SizedBox())
                                : Image.file(
                                    File(_selectedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        else if (_selectedGradient != null)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _selectedGradient!,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          )
                        else if (_selectedEmoji != null)
                          Opacity(
                            opacity: 0.6,
                            child: Image.asset(
                              _selectedEmoji!,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          TintesGradients(
                            child: Container(height: bottomGradientHeight),
                          ),
                      ],
                    ),
                  ),
                ),
                // Foreground content (QR code, profile info) - doesn't block background taps
                IgnorePointer(
                  ignoring: false,
                  child: FutureBuilder<_ProfileData>(
                    future: _futureProfile,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (!snap.hasData) {
                        return const Text(
                          'No data',
                          style: TextStyle(color: Colors.white),
                        );
                      }
                      final data = snap.data!;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
                            width: 301,
                            height: 372,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      QrImageView(
                                        data: data.link,
                                        eyeStyle: QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: _qrColor,
                                        ),
                                        dataModuleStyle: QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: _qrColor,
                                        ),
                                        version: QrVersions.auto,
                                        size: 256,
                                      ),
                                      // Center logo
                                      Image.asset(
                                        'assets/images/Migozz.webp',
                                        width: 50,
                                        height: 50,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    data.displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${data.username}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Share Profile button positioned outside the screenshot area
          FutureBuilder<_ProfileData>(
            future: _futureProfile,
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final data = snap.data!;
              return Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareProfile(data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Profile'),
                  ),
                ),
              );
            },
          ),
          // Top buttons positioned outside the screenshot area
          Positioned(
            top: 40,
            left: 20,
            right: 20,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.save_alt, color: Colors.white),
                  onPressed: _captureAndSaveScreenshot,
                ),
                GestureDetector(
                  onTap: _toggleMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getButtonLabel(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  final String username;
  final String displayName;
  final String link;
  _ProfileData({
    required this.username,
    required this.displayName,
    required this.link,
  });
}
