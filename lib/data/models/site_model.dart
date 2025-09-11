class SiteModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<ZoneModel> zones;

  SiteModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.zones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'zones': zones.map((zone) => zone.toMap()).toList(),
    };
  }

  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      zones: List<ZoneModel>.from(
        (map['zones'] ?? []).map((zone) => ZoneModel.fromMap(zone)),
      ),
    );
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    List<ZoneModel>? zones,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zones: zones ?? this.zones,
    );
  }

  @override
  String toString() {
    return 'SiteModel(id: $id, name: $name, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ZoneModel {
  final String id;
  final String name;
  final String color;

  ZoneModel({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? 'blue',
    );
  }

  ZoneModel copyWith({
    String? id,
    String? name,
    String? color,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'ZoneModel(id: $id, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZoneModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
