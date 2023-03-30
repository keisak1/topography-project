class Markers {
  final String fullID;
  final double osmID;
  final int id;
  final double yLat;
  final double xLong;
  final int mainZoneID;
  final int subZoneID;
  final int status;

  const Markers({
    required this.fullID,
    required this.osmID,
    required this.id,
    required this.yLat,
    required this.xLong,
    required this.mainZoneID,
    required this.subZoneID,
    required this.status
  });

  factory Markers.fromJson(Map<String, dynamic> json){
    return Markers(
      fullID: json['full_id'],
      osmID: json['osm_id'],
      id: json['id'],
      yLat: json['y_lat'],
      xLong: json['x_long'],
      mainZoneID: json['main_zone_id'],
      subZoneID: json['sub_zone_id'],
      status: json['status']
    );
  }

  Map<String, dynamic> toJson() => {
    'full_id': fullID,
    'osm_id': osmID,
    'id': id,
    'y_lat': yLat,
    'x_long': xLong,
    'main_zone_id': mainZoneID,
    'sub_zone_id': subZoneID,
    'status': status
  };
}