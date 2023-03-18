import 'package:flutter/material.dart';

class SaveFormPopup extends StatefulWidget {
  final Function(String value) onConfirm;
  const SaveFormPopup({required this.onConfirm});

  @override
  _SaveFormPopupState createState() => _SaveFormPopupState();
}

String handleSave(String name) {
  return name;
}

class _SaveFormPopupState extends State<SaveFormPopup> {
  final _formKey = GlobalKey<FormState>();
  late String _formName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Form'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Form Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for the form';
                }
                return null;
              },
              onSaved: (value) {
                _formName = value!;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  widget.onConfirm(_formName);
                  Navigator.of(context).pop(_formName);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
