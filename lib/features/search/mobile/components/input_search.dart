import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class InputSearch extends StatefulWidget {
  final Widget? child;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const InputSearch({super.key, this.child, this.controller, this.onChanged});

  @override
  State<InputSearch> createState() => _InputSearchState();
}

class _InputSearchState extends State<InputSearch> {
  TextEditingController? _internalController;
  bool _hasText = false;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
    }
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 375.0;
    final topSpacing = (0 * scale).clamp(28.0, 100.0);
    final iconSize = (35.0 * scale).clamp(20.0, 48.0);
    final prefixIconSize = (18.0 * scale).clamp(14.0, 26.0);
    final borderRadius = 12.0;
    final enabledBorderWidth = (1.0 * scale).clamp(0.8, 2.0);
    final focusedBorderWidth = (2.0 * scale).clamp(1.2, 3.0);
    final contentHorizontal = (16.0 * scale).clamp(8.0, 24.0);

    return Column(
      children: [
        SizedBox(height: topSpacing),
        Row(
          children: [
            // Botón animado que aparece/desaparece
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_circle_left_outlined,
                        size: iconSize,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _controller.clear();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.text,
                // autofocus: true,
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  hintText: "search.searchText".tr(),
                  prefixIcon: Icon(Icons.search, size: prefixIconSize),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: enabledBorderWidth,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).disabledColor,
                      width: focusedBorderWidth,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(75, 238, 238, 238),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: contentHorizontal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
