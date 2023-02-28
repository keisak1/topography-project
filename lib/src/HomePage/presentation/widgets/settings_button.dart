import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:topography_project/src/SettingsPage/settingspage_screen.dart';

class SettingsButton extends StatefulWidget {

  const SettingsButton({super.key});

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton> {
  void _settingsPage(){
    Navigator.push(
      context!,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _settingsPage,
        child: new Icon(Icons.settings_outlined, ),
      ),
    );
  }
}