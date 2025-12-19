import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_attachment_sheet.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/core/components/compuestos/custom_tooltip.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'audio_recorder_manager.dart';
import 'recording_display.dart';
import 'audio_player_display.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(String path)? onSendAudio;
  final void Function(String path)? onSendImage;
  final TextInputType keyboardType;
  final bool showPhoneInput;

  const ChatInputWidget({
    super.key,
    this.keyboardType = TextInputType.text,
    required this.controller,
    required this.onSend,
    this.onSendAudio,
    this.onSendImage,
    this.showPhoneInput = false,
  });

  @override
  State<ChatInputWidget> createState() => ChatInputWidgetState();
}

class ChatInputWidgetState extends State<ChatInputWidget> {
  bool _showAttachments = false;
  late final AudioRecorderManager _audioManager;
  Timer? _holdTimer;
  OverlayEntry? _tooltipEntry;
  bool _isLongPressValid = false;
  final GlobalKey _micButtonKey = GlobalKey();
  final GlobalKey _attachButtonKey = GlobalKey();

  String _completePhoneNumber = '';
  bool _isPhoneValid = false;

  GlobalKey get attachButtonKey => _attachButtonKey;
  GlobalKey get micButtonKey => _micButtonKey;

  @override
  void initState() {
    super.initState();

    _audioManager = AudioRecorderManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _tooltipEntry?.remove();
    _tooltipEntry = null;

    _audioManager.dispose();

    widget.controller.removeListener(() {});
    super.dispose();
  }

  void _clearInputVisual() {
    if (widget.showPhoneInput) {
      setState(() {
        _completePhoneNumber = '';
        _isPhoneValid = false;
      });
    } else {
      widget.controller.clear();
    }
    try {
      FocusScope.of(context).unfocus();
    } catch (_) {}
  }

  void _toggleAttachments() {
    // Solo permitir abrir attachments en MOBILE
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "If you'd like to add images or audio, please use the app!",
          ),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    setState(() => _showAttachments = !_showAttachments);
  }

  void _handleSendAudio() async {
    // Si estamos en web, avisar y no enviar audio
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "If you'd like to add images or audio, please use the app!",
          ),
          backgroundColor: Colors.blue,
        ),
      );
      await _audioManager.reset(); // En web sí borrar
      if (mounted) setState(() {});
      return;
    }

    if (_audioManager.audioPath != null) {
      final audioPath = _audioManager.audioPath!;

      debugPrint('🎤 [ChatInput] Iniciando envío de audio: $audioPath');

      try {
        final tempPlayer = PlayerController();
        await tempPlayer.preparePlayer(
          path: audioPath,
          shouldExtractWaveform: false,
        );

        final freshDurationMs = tempPlayer.maxDuration;
        final durationInSeconds = freshDurationMs / 1000.0;
        tempPlayer.dispose();

        if (durationInSeconds < 1.0 || durationInSeconds > 10.0) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                durationInSeconds < 1.0
                    ? "register.validations.audioMinLimit".tr()
                    : "register.validations.audioMaxLimit".tr(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          await _audioManager.reset(); // Aquí sí borrar porque no se usará
          if (mounted) setState(() {});
          return;
        }

        debugPrint('📤 [ChatInput] Enviando audio...');

        // PRIMERO: Enviar el audio (AudioChatHandler creará su copia)
        widget.onSendAudio?.call(audioPath);

        debugPrint('🧹 [ChatInput] Limpiando UI (preservando archivo)...');

        // SEGUNDO: Limpiar solo las referencias del UI (NO el archivo)
        await _audioManager.clearReferences();
        _clearInputVisual();

        debugPrint(
          '✅ [ChatInput] UI limpiado, archivo preservado para AudioChatHandler',
        );

        // TERCERO: Actualizar el UI
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('❌ Error al validar duración: $e');

        // En caso de error, también enviar y limpiar solo el UI
        widget.onSendAudio?.call(audioPath);
        await _audioManager.clearReferences();
        _clearInputVisual();

        if (mounted) setState(() {});
      }
    }
  }

  Future<void> resetAudioManager() async {
    debugPrint('🔄 [ChatInput] resetAudioManager llamado desde controller');
    await _audioManager
        .clearReferences(); // Usar clearReferences en vez de reset
    if (mounted) setState(() {});
  }

  void _handleMainButton() {
    if (widget.showPhoneInput) {
      if (_isPhoneValid && _completePhoneNumber.isNotEmpty) {
        widget.controller.text = _completePhoneNumber;
        widget.onSend();
        setState(() {
          _completePhoneNumber = '';
          _isPhoneValid = false;
        });
      }
      return;
    }

    final hasText = widget.controller.text.trim().isNotEmpty;

    if (hasText) {
      widget.onSend();
    } else if (_audioManager.audioPath != null) {
      // Llamar a _handleSendAudio que ya tiene la lógica de limpiar
      _handleSendAudio();
    } else {
      // Si no hay texto ni audio, abrir tooltip instruccional
      _showTooltip(context, "Mantén pulsado para grabar");
    }
  }

  void _startRecordingPress() async {
    // En web, no permitimos grabar (mostramos mensaje)
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "If you'd like to add images or audio, please use the app!",
          ),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    await _audioManager.startRecording();
    setState(() {});
  }

  void _stopRecordingRelease() async {
    if (kIsWeb) return;
    await _audioManager.stopRecording();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.showPhoneInput
        ? (_isPhoneValid && _completePhoneNumber.isNotEmpty)
        : widget.controller.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // attachments only on mobile
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: (!_showAttachments || kIsWeb)
              ? null
              : ChatAttachmentGrid(
                  onSendImage: (path) {
                    // if web safety: won't be reachable cause _toggleAttachments blocks on web
                    widget.onSendImage?.call(path);
                    setState(() => _showAttachments = false);
                  },
                ),
        ),

        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
            child: Row(
              children: [
                Expanded(child: _buildInputArea()),
                // Solo mostrar botón de acción en móvil o si hay texto
                if (!kIsWeb || hasText) ...[
                  const SizedBox(width: 6),
                  _buildMainButton(hasText),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    if (_audioManager.isRecording) {
      return RecordingDisplay(duration: _audioManager.duration);
    }

    if (_audioManager.audioPath != null) {
      return AudioPlayerDisplay(
        playerController: _audioManager.waveformPlayerController,
        duration: _audioManager.duration,
        maxDuration: _audioManager.maxDuration,
        isPlaying: _audioManager.isPlaying,
        onPlayPause: () async {
          if (_audioManager.isPlaying) {
            await _audioManager.stopPlaying();
          } else {
            await _audioManager.playRecording();
          }
          if (mounted) setState(() {});
        },
        onSeek: (pos) => _audioManager.seekToPosition(pos),
        onDelete: () async {
          await _audioManager.reset();
          if (mounted) setState(() {});
        },
      );
    }

    if (widget.showPhoneInput) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
        child: Container(
          key: const ValueKey('phone_input'),
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IntlPhoneField(
            decoration: InputDecoration(
              hintText: '1234',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              counterText: '',
            ),
            showDropdownIcon: false,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            dropdownTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            onChanged: (phone) {
              setState(() {
                _completePhoneNumber = phone.completeNumber;
                _isPhoneValid = phone.number.length >= 4;
              });
            },
            onSubmitted: (value) {
              // Cuando el usuario presiona Enter
              if (_isPhoneValid && _completePhoneNumber.isNotEmpty) {
                _handleMainButton();
              }
            },
            textInputAction: TextInputAction.send,
            dropdownDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            keyboardType: TextInputType.phone,
            disableLengthCheck: true,
            pickerDialogStyle: PickerDialogStyle(
              width: 350,
              countryCodeStyle: const TextStyle(color: Colors.black),
              countryNameStyle: const TextStyle(color: Colors.black87),
              searchFieldInputDecoration: const InputDecoration(
                hintText: 'Search country',
                hintStyle: TextStyle(color: Colors.black87),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: CustomTextField(
        key: const ValueKey('text_input'),
        controller: widget.controller,
        hintText: "Escribe algo...",
        radius: 8,
        keyboardType: widget.keyboardType,
        textInputAction: TextInputAction.send,
        onSubmitted: (value) {
          // Cuando el usuario presiona Enter (o Send en el teclado), enviar si hay texto
          if (value.trim().isNotEmpty) {
            widget.onSend();
            try {
              widget.controller.clear();
            } catch (_) {}
          }
        },
        // Solo mostrar botón de adjuntar en móvil
        suffixIcon: !kIsWeb
            ? IconButton(
                key: _attachButtonKey,
                icon: Icon(
                  _showAttachments ? Icons.close : Icons.attach_file,
                  color: _showAttachments ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleAttachments,
              )
            : null,
      ),
    );
  }

  void _showTooltip(BuildContext context, String message) {
    if (_tooltipEntry != null) {
      _tooltipEntry!.remove();
      _tooltipEntry = null;
    }

    final overlay = Overlay.of(context);
    final renderBox =
        _micButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const tooltipWidth = 180.0;
    const margin = 8.0;

    final showAbove = offset.dy > screenHeight / 2;
    double left = offset.dx + size.width / 2 - tooltipWidth / 2;

    if (left < margin) left = margin;
    if (left + tooltipWidth > screenWidth - margin) {
      left = screenWidth - tooltipWidth - margin;
    }

    final arrowOffset = offset.dx + size.width / 2 - left;

    _tooltipEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: left,
        top: showAbove ? offset.dy - 75 : offset.dy + size.height + 12,
        width: tooltipWidth,
        child: Material(
          color: Colors.transparent,
          child: CustomTooltip(
            message: message,
            onClose: () {
              _tooltipEntry?.remove();
              _tooltipEntry = null;
            },
            showAbove: showAbove,
            arrowOffset: arrowOffset,
          ),
        ),
      ),
    );

    overlay.insert(_tooltipEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      _tooltipEntry?.remove();
      _tooltipEntry = null;
    });
  }

  Widget _buildMainButton(bool hasText) {
    IconData icon;

    if (hasText) {
      icon = Icons.send_outlined;
    } else if (_audioManager.isRecording) {
      icon = Icons.stop;
    } else if (_audioManager.audioPath != null) {
      icon = Icons.send;
    } else {
      icon = Icons.mic;
    }

    // Phone input send button
    if (widget.showPhoneInput) {
      return Container(
        height: 48,
        width: 50,
        decoration: BoxDecoration(
          gradient: hasText
              ? AppColors.verticalPinkPurple
              : LinearGradient(
                  colors: [Colors.grey.shade700, Colors.grey.shade600],
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.send_outlined, color: Colors.white),
          onPressed: hasText ? _handleMainButton : null,
        ),
      );
    }

    // Send / recording container
    if (hasText ||
        _audioManager.audioPath != null ||
        _audioManager.isRecording) {
      return Container(
        height: 48,
        width: 50,
        decoration: BoxDecoration(
          gradient: AppColors.verticalPinkPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: _handleMainButton,
        ),
      );
    }

    // Default: long-press recording (mobile) or tooltip (web)
    return Listener(
      onPointerDown: (_) {
        _isLongPressValid = false;
        _holdTimer = Timer(const Duration(milliseconds: 300), () {
          _isLongPressValid = true;
          _startRecordingPress();
        });
      },
      onPointerUp: (_) {
        _holdTimer?.cancel();
        if (_isLongPressValid) {
          _stopRecordingRelease();
        } else {
          _showTooltip(context, "Mantén pulsado para grabar");
        }
      },
      onPointerCancel: (_) {
        _holdTimer?.cancel();
        if (_isLongPressValid) {
          _stopRecordingRelease();
        }
      },
      child: Container(
        key: _micButtonKey,
        height: 48,
        width: 50,
        decoration: BoxDecoration(
          gradient: AppColors.verticalPinkPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 24)),
      ),
    );
  }
}
