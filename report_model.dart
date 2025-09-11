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
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReportModel(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      zone: data['zone'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ReportType.work,
      ),
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ReportStatus.inProgress,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      reporterName: data['reporterName'],
      reporterId: data['reporterId'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'zone': zone,
      'type': type.toString().split('.').last,
      'description': description,
      'photoUrls': photoUrls,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'reporterName': reporterName,
      'reporterId': reporterId,
      'latitude': latitude,
      'longitude': longitude,
    };
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
    );
  }
}

