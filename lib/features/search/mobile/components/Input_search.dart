import 'package:flutter/material.dart';

/// InputSearch ahora permite pasar un [TextEditingController] y un [onChanged]
/// para notificar cambios al padre (SearchScreen) y así alternar entre
/// sugerencias y resultados.
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

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
    }
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
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
    final topSpacing = (40.0 * scale).clamp(28.0, 100.0);
    final bottomSpacing = (20.0 * scale).clamp(8.0, 40.0);
    final horizontalPadding = (16.0 * scale).clamp(8.0, 28.0);
    final iconSize = (35.0 * scale).clamp(20.0, 48.0);
    final prefixIconSize = (18.0 * scale).clamp(14.0, 26.0);
    final borderRadius = (20.0 * scale).clamp(10.0, 32.0);
    final enabledBorderWidth = (1.0 * scale).clamp(0.8, 2.0);
    final focusedBorderWidth = (2.0 * scale).clamp(1.2, 3.0);
    final contentHorizontal = (16.0 * scale).clamp(8.0, 24.0);

    return Column(
      children: [
        SizedBox(height: topSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: iconSize,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.text,
                  autofocus: true,
                  cursorColor: Theme.of(context).primaryColor,
                  decoration: InputDecoration(
                    hintText: 'Search...',
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
        ),
        SizedBox(height: bottomSpacing),

        // Si se pasa un child, lo mostramos aquí (permite compatibilidad con llamadas anteriores)
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
