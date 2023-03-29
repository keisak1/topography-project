import 'Bbox.dart';

class Zone {
  final int id;
  final String zoneLabel;
  final double centerLat;
  final double centerLong;
  final List<Bbox> bbox;

  const Zone({
    required this.id,
    required this.zoneLabel,
    required this.centerLat,
    required this.centerLong,
    required this.bbox,
  });

  factory Zone.fromJson(Map<String, dynamic> json){
    final List<dynamic> bboxJson = json['bbox'] ?? [];
    final List<Bbox> bbox = bboxJson.map((e) => Bbox.fromJson(e)).toList();

    return Zone(
        id: json['id'],
        zoneLabel: json['zone_label'],
        centerLat: json['center_lat'],
        centerLong: json['center_lng'],
        bbox: bbox,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'zone_label': zoneLabel,
    'center_lat': centerLat,
    'center_lng': centerLong,
    'bbox': bbox.map((bbox) => bbox.toJson()).toList(),
  };
}