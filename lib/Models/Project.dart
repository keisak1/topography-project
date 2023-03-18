import 'Zone.dart';

class Project {
  final String name;
  final List<Zone> zones;

  const Project({
    required this.name,
    required this.zones
  });

  factory Project.fromJson(Map<String, dynamic> json){
    final List<dynamic> zonesJson = json['zones'] ?? [];
    final List<Zone> zones = zonesJson.map((e) => Zone.fromJson(e)).toList();

    return Project(
      name: json['name'],
      zones: zones
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'zones': zones.map((zone) => zone.toJson()).toList(),
  };
}