import 'package:flutter/material.dart';

class PinPromptDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;

  const PinPromptDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinPromptDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  @override
  State<PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<PinPromptDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isObscured = true;
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  void _onConfirm() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() {
        _errorText = 'Please enter your PIN';
      });
      return;
    }
    if (pin.length != 4) {
      setState(() {
        _errorText = 'PIN must be 4 digits';
      });
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorText = 'PIN must contain only numbers';
      });
      return;
    }

    Navigator.of(context).pop(pin);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'M-Pesa PIN',
              hintText: '••••',
              errorText: _errorText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _toggleVisibility,
              ),
            ),
            keyboardType: TextInputType.number,
            obscureText: _isObscured,
            maxLength: 4,
            onChanged: (value) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            onSubmitted: (_) => _onConfirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _onCancel,
          child: Text(widget.cancelText ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: Text(widget.confirmText ?? 'Confirm'),
        ),
      ],
    );
  }
}