import 'package:flutter/material.dart';

Future<String?> showDisplayNameDialog(BuildContext context) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _NameDialog(controller: controller),
  );
  controller.dispose();
  return name;
}

Future<String?> showJoinRoomDialog(BuildContext context) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unirse a una sala'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Código de sala'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Unirse'),
        ),
      ],
    ),
  );
  controller.dispose();
  return code;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.controller});
  final TextEditingController controller;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  bool _isSubmitting = false;

  void _submit() {
    final name = widget.controller.text.trim();
    if (name.isEmpty || _isSubmitting) return;

    _isSubmitting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isValid = widget.controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('¿Cómo te llamas?'),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Tu nombre'),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        FilledButton(
          onPressed: isValid ? _submit : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
