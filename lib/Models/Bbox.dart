class Bbox {
  final double lat;
  final double lng;

  const Bbox({
    required this.lat,
    required this.lng,
  });

  factory Bbox.fromJson(Map<String, dynamic> json){
    return Bbox(
        lat: json['lat'],
        lng: json['lng'],
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
  };
}