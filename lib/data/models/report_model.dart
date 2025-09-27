import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType { work, hazard }

enum ReportStatus { inProgress, done, hazard }

class ReportModel {
  final String id;
  final String siteId;
  final String zone;
  final ReportType type;
  final String description;
  final List<String> photoUrls;
  final ReportStatus status;
  final DateTime timestamp;
  final String? reporterName;
  final String? reporterId;
  final double? latitude;
  final double? longitude;
  final double? mapX;
  final double? mapY;
  final bool isArchived;
  final DateTime? archivedDate;
  final DateTime? lastEditedAt;
  final String? lastEditedBy;
  final int editCount;

  ReportModel({
    required this.id,
    required this.siteId,
    required this.zone,
    required this.type,
    required this.description,
    required this.photoUrls,
    required this.status,
    required this.timestamp,
    this.reporterName,
    this.reporterId,
    this.latitude,
    this.longitude,
    this.mapX,
    this.mapY,
    this.isArchived = false,
    this.archivedDate,
    this.lastEditedAt,
    this.lastEditedBy,
    this.editCount = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'zone': zone,
      'type': type.name,
      'description': description,
      'photoUrls': photoUrls,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'reporterName': reporterName,
      'reporterId': reporterId,
      'latitude': latitude,
      'longitude': longitude,
      'mapX': mapX,
      'mapY': mapY,
      'isArchived': isArchived,
      'archivedDate':
          archivedDate != null ? Timestamp.fromDate(archivedDate!) : null,
      'lastEditedAt':
          lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
      'lastEditedBy': lastEditedBy,
      'editCount': editCount,
    };
  }

  factory ReportModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ReportModel(
      id: id,
      siteId: data['siteId'] ?? '',
      zone: data['zone'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReportType.work,
      ),
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReportStatus.inProgress,
      ),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      reporterName: data['reporterName'],
      reporterId: data['reporterId'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      mapX: data['mapX']?.toDouble(),
      mapY: data['mapY']?.toDouble(),
      isArchived: data['isArchived'] ?? false,
      archivedDate: data['archivedDate'] != null
          ? (data['archivedDate'] as Timestamp).toDate()
          : null,
      lastEditedAt: data['lastEditedAt'] != null
          ? (data['lastEditedAt'] as Timestamp).toDate()
          : null,
      lastEditedBy: data['lastEditedBy'],
      editCount: data['editCount'] ?? 0,
    );
  }

  ReportModel copyWith({
    String? id,
    String? siteId,
    String? zone,
    ReportType? type,
    String? description,
    List<String>? photoUrls,
    ReportStatus? status,
    DateTime? timestamp,
    String? reporterName,
    String? reporterId,
    double? latitude,
    double? longitude,
    double? mapX,
    double? mapY,
    bool? isArchived,
    DateTime? archivedDate,
    DateTime? lastEditedAt,
    String? lastEditedBy,
    int? editCount,
  }) {
    return ReportModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      zone: zone ?? this.zone,
      type: type ?? this.type,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reporterName: reporterName ?? this.reporterName,
      reporterId: reporterId ?? this.reporterId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      isArchived: isArchived ?? this.isArchived,
      archivedDate: archivedDate ?? this.archivedDate,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      editCount: editCount ?? this.editCount,
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, siteId: $siteId, zone: $zone, type: $type, status: $status, isArchived: $isArchived)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
