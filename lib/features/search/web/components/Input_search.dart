import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/search/web/components/back_button.dart' as custom;
import 'package:migozz_app/features/search/web/components/search_text_field.dart';


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
    final topSpacing = (16.0 * scale).clamp(12.0, 24.0);
    final iconSize = (24.0 * scale).clamp(20.0, 32.0);
    final prefixIconSize = (20.0 * scale).clamp(16.0, 24.0);
    final borderRadius = (24.0 * scale).clamp(16.0, 32.0);
    final textFieldHeight = (44.0 * scale).clamp(40.0, 56.0);

    return Container(
      padding: EdgeInsets.only(top: topSpacing, bottom: 8.0),
      child: SizedBox(
        height: textFieldHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Botón de retroceso
            custom.BackButton(
              onTap: () => context.go('/profile'),
              iconSize: iconSize,
            ),
            const SizedBox(width: 8),
            // Campo de búsqueda
            Expanded(
              child: SearchTextField(
                controller: _controller,
                borderRadius: borderRadius,
                prefixIconSize: prefixIconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
