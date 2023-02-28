import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/sidebar_button.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/map.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/settings_button.dart';
import 'package:topography_project/src/SettingsPage/settingspage_screen.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  MapController controller = MapController.withPosition(
    initPosition: GeoPoint(
      latitude: 41.171667,
      longitude: -8.611667,
    ),
    areaLimit: BoundingBox(
      east: 41.171860,
      north: 41.172770,
      south: 41.171005,
      west: 41.171812,
    ),
  );

  void _settingsPage(){
    Navigator.push(
      context!,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Sidebar'),
          ),
          ListTile(
            /*leading: Icon(
              Icons.home,
            ),*/
            title: const Text('Zona 1'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            /*leading: Icon(
              Icons.train,
            ),*/
            title: const Text('Zona 2'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            left: 10,
            top: 20,
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Center(
            child: OSMFlutter(
              controller: controller,
              trackMyPosition: false,
              initZoom: 16,
              minZoomLevel: 12,
              maxZoomLevel: 19,
              stepZoom: 1.0,
              userLocationMarker: UserLocationMaker(
                personMarker: MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    size: 48,
                  ),
                ),
              ),
              roadConfiguration: RoadOption(
                roadColor: Colors.yellowAccent,
              ),
              markerOption: MarkerOption(
                  defaultMarker: MarkerIcon(
                    icon: Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 56,
                    ),
                  )),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _settingsPage,
        child: new Icon(Icons.settings_outlined, ),
      ),
    );
  }
}