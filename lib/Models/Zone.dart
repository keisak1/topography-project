class Zone {
  final String name;
  final double centerLat;
  final double centerLong;
  final double zoom;
  final int form;

  const Zone({
    required this.name,
    required this.centerLat,
    required this.centerLong,
    required this.zoom,
    required this.form,
  });

  factory Zone.fromJson(Map<String, dynamic> json){
    return Zone(
        name: json['name'],
        centerLat: json['center_lat'],
        centerLong: json['center_long'],
        zoom: json['zoom'],
        form: json['form']
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'centerLat': centerLat,
    'centerLong': centerLong,
    'zoom': zoom,
    'form': form,
  };
}