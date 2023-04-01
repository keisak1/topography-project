import 'Zone.dart';

class Project {
  final String name;
  final double centerLat;
  final double centerLong;
  final int zoom;
  final int form;
  final List<Zone> zones;

  const Project({
    required this.name,
    required this.centerLat,
    required this.centerLong,
    required this.zoom,
    required this.form,
    required this.zones
  });

  factory Project.fromJson(Map<String, dynamic> json){
    final List<dynamic> zonesJson = json.containsKey('zones') ? json['zones'] : [];
    final List<Zone> zones = zonesJson.map((e) => Zone.fromJson(e)).toList();

    return Project(
      name: json['name'],
      centerLat: json['center_lat'],
      centerLong: json['center_long'],
      zoom: json['zoom'],
      form: json['form'],
      zones: zones
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'center_lat': centerLat,
    'center_long': centerLong,
    'zoom': zoom,
    'form': form,
    'zones': zones.map((zone) => zone.toJson()).toList(),
  };
}