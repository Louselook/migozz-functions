import 'dart:async';
import 'package:flutter/material.dart';
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

  const ChatInputWidget({
    super.key,
    this.keyboardType = TextInputType.text,
    required this.controller,
    required this.onSend,
    this.onSendAudio,
    this.onSendImage,
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
    _audioManager.dispose();
    widget.controller.removeListener(() {});
    super.dispose();
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
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El audio es muy corto (${durationInSeconds.toStringAsFixed(1)} segundos). Debe durar entre 5 y 10 segundos',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          _audioManager.reset();
          setState(() {});
          return;
        }

        if (durationInSeconds > 10.0) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El audio es muy largo (${durationInSeconds.toStringAsFixed(1)} segundos). Debe durar entre 5 y 10 segundos',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          _audioManager.reset();
          setState(() {});
          return;
        }

        // ✅ Audio válido (5-10 segundos)
        debugPrint(
          '✅ Audio válido (${durationInSeconds.toStringAsFixed(1)}s), enviando...',
        );
        widget.onSendAudio?.call(audioPath);
        _audioManager.reset();
        setState(() {});
      } catch (e) {
        debugPrint('❌ Error al validar duración: $e');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo validar la duración. Enviando audio sin validar.',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        widget.onSendAudio?.call(audioPath);
        _audioManager.reset();
        setState(() {});
      }
    }
  }

  void _handleMainButton() {
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
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panel de adjuntos
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

        // Barra de input
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
        onSeek: (position) => _audioManager.seekToPosition(position),
        onDelete: () {
          // 🗑️ Eliminar audio grabado
          _audioManager.reset();
          setState(() {});
        },
      );
    }

    // ⌨️ Input de texto normal
    return CustomTextField(
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
