import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _showAttachments = false;
  late final AudioRecorderManager _audioManager;
  Timer? _holdTimer;
  OverlayEntry? _tooltipEntry;
  bool _isLongPressValid = false;
  final GlobalKey _micButtonKey = GlobalKey();

  // ✅ Variables simples para el teléfono
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;

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

    // ✅ Limpiar audio antes de dispose
    _audioManager
        .reset()
        .then((_) {
          _audioManager.dispose();
        })
        .catchError((e) {
          debugPrint('Error en dispose: $e');
          _audioManager.dispose();
        });

    widget.controller.removeListener(() {});
    super.dispose();
  }

  void _clearInputVisual() {
    // Si estamos en modo teléfono, limpiar el campo de teléfono
    if (widget.showPhoneInput) {
      setState(() {
        _completePhoneNumber = '';
        _isPhoneValid = false;
      });
    } else {
      // Para input de texto normal, limpiar el controller
      widget.controller.clear();
    }

    // Quitar foco / teclado para que la UI vuelva a su estado original
    try {
      FocusScope.of(context).unfocus();
    } catch (_) {}
  }

  void _toggleAttachments() {
    setState(() => _showAttachments = !_showAttachments);
  }

  void _handleSendAudio() async {
    if (_audioManager.audioPath != null) {
      final audioPath = _audioManager.audioPath!;

      try {
        final tempPlayer = PlayerController();
        await tempPlayer.preparePlayer(
          path: audioPath,
          shouldExtractWaveform: false,
        );

        final freshDurationMs = tempPlayer.maxDuration;
        final durationInSeconds = freshDurationMs / 1000.0;
        tempPlayer.dispose();

        if (durationInSeconds < 5.0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El audio es muy corto (${durationInSeconds.toStringAsFixed(1)} segundos). Debe durar entre 5 y 10 segundos',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          await _audioManager.reset();
          if (mounted) setState(() {});
          return;
        }

        if (durationInSeconds > 10.0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El audio es muy largo (${durationInSeconds.toStringAsFixed(1)} segundos). Debe durar entre 5 y 10 segundos',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          await _audioManager.reset();
          if (mounted) setState(() {});
          return;
        }

        debugPrint('✅ Audio válido (${durationInSeconds.toStringAsFixed(1)}s), enviando...');

        // ✅ Enviar el audio (el handler creará la copia)
        widget.onSendAudio?.call(audioPath);

        // ✅ Solo limpiar visual, NO resetear el audio manager todavía
        _clearInputVisual();

        // ❌ NO RESETEAR AQUÍ - se hará después de la confirmación
        // await _audioManager.reset();
        if (mounted) setState(() {});
        
      } catch (e) {
        debugPrint('❌ Error al validar duración: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo validar la duración. Enviando audio sin validar.',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        widget.onSendAudio?.call(audioPath);
        _clearInputVisual();
        // ❌ NO RESETEAR AQUÍ tampoco
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> resetAudioManager() async {
    await _audioManager.reset();
    if (mounted) setState((){});
  }

  void _handleMainButton() {
    // ✅ Si es input de teléfono, usar el número completo
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

    // Flujo normal para texto
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (hasText) {
      widget.onSend();
    } else if (_audioManager.audioPath != null) {
      _handleSendAudio();
    }
  }

  void _startRecordingPress() async {
    await _audioManager.startRecording();
    setState(() {});
  }

  void _stopRecordingRelease() async {
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _showAttachments
              ? ChatAttachmentGrid(
                  onSendImage: (path) {
                    widget.onSendImage?.call(path);
                    setState(() => _showAttachments = false);
                  },
                )
              : null,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
          child: Row(
            children: [
              Expanded(child: _buildInputArea()),
              const SizedBox(width: 6),
              _buildMainButton(hasText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    // 🎙️ Grabando audio
    if (_audioManager.isRecording) {
      return RecordingDisplay(
        duration: _audioManager.duration,
        waveController: _audioManager.waveController,
      );
    }

    // 🎵 Audio grabado listo para enviar
    // En _buildInputArea() de ChatInputWidget
    if (_audioManager.audioPath != null) {
      return AudioPlayerDisplay(
        playerController: _audioManager.playerController,
        duration: _audioManager.duration,
        maxDuration: _audioManager.maxDuration,
        isPlaying: _audioManager.isPlaying,
        onPlayPause: () {
          if (_audioManager.isPlaying) {
            _audioManager.stopPlaying();
          } else {
            _audioManager.playRecording();
          }
        },
        onSeek: (position) =>
            _audioManager.seekToPosition(position), // ✅ Ya está correcto
        onDelete: () async {
          await _audioManager.reset();
          if (mounted) setState(() {});
        },
      );
    }

    // 📞 Input de teléfono con selector de país (MISMO DISEÑO que CustomTextField)
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
            dropdownDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            keyboardType: TextInputType.phone,
            disableLengthCheck: true,
          ),
        ),
      );
    }

    // ⌨️ Input de texto normal
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
        suffixIcon: IconButton(
          icon: Icon(
            _showAttachments ? Icons.close : Icons.attach_file,
            color: _showAttachments ? Colors.red : Colors.grey,
          ),
          onPressed: _toggleAttachments,
        ),
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
        _micButtonKey.currentContext!.findRenderObject() as RenderBox;
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

    // ✅ Botón unificado para texto Y teléfono
    if (widget.showPhoneInput) {
      // Para teléfono, mostrar botón de enviar cuando el número es válido
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

    // Botón normal con audio/texto
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
