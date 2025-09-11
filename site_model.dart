import 'package:cloud_firestore/cloud_firestore.dart';

class SiteModel {
  final String id;
  final String name;
  final String location;
  final String mapImageUrl;
  final List<ZoneModel> zones;
  final DateTime createdAt;
  final DateTime updatedAt;

  SiteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.mapImageUrl,
    required this.zones,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SiteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SiteModel(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      mapImageUrl: data['mapImageUrl'] ?? '',
      zones: (data['zones'] as List<dynamic>?)
          ?.map((zone) => ZoneModel.fromMap(zone as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'mapImageUrl': mapImageUrl,
      'zones': zones.map((zone) => zone.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? location,
    String? mapImageUrl,
    List<ZoneModel>? zones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      mapImageUrl: mapImageUrl ?? this.mapImageUrl,
      zones: zones ?? this.zones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ZoneModel {
  final String id;
  final String name;
  final String description;
  final double? x; // X coordinate on map (percentage)
  final double? y; // Y coordinate on map (percentage)

  ZoneModel({
    required this.id,
    required this.name,
    required this.description,
    this.x,
    this.y,
  });

  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      x: map['x']?.toDouble(),
      y: map['y']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'x': x,
      'y': y,
    };
  }

  ZoneModel copyWith({
    String? id,
    String? name,
    String? description,
    double? x,
    double? y,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

