import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// CONTENEDOR RETRO
// ==========================================
class RetroContainer extends StatelessWidget {
  final Widget child;

  const RetroContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: child,
    );
  }
}

// ==========================================
// BOTÓN RETRO INTERACTIVO
// ==========================================
class RetroButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback onPressed;
  final Color color;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;

  const RetroButton({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.color = Colors.green,
    this.fullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: widget.fullWidth ? double.infinity : null,
          margin: EdgeInsets.only(
            top: _isPressed ? 4 : 0,
            left: _isPressed ? 4 : 0,
            bottom: _isPressed ? 0 : 4,
            right: _isPressed ? 0 : 4,
          ),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: _isPressed ? [] : [const BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: widget.child ??
              Text(
                widget.text ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Courier',
                ),
              ),
        ),
      ),
    );
  }
}

// ==========================================
// FORMATEADOR DE MAYÚSCULAS
// ==========================================
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}