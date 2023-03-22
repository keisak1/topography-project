import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../HomePage/presentation/homepage_screen.dart';


class locallySavedMarkers extends StatefulWidget {

  const locallySavedMarkers({super.key});

  @override
  State<locallySavedMarkers> createState() => _locallySavedMarkersState();
}

class _locallySavedMarkersState extends State<locallySavedMarkers> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          ),
        ),
        title:  Text(AppLocalizations.of(context)!.locallySavedMarkers,
        ),
        backgroundColor: Colors.black,
      ),
      body:  Center(
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('This is the settings page',),
          ],
        ),
      ),
    );
  }
}