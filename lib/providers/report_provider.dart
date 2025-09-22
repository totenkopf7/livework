import 'package:flutter/foundation.dart';
import '../data/models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:livework_view/providers/auth_provider.dart' as livework_auth;

class ReportProvider with ChangeNotifier {
  List<ReportModel> _reports = [];
  List<ReportModel> _pendingReports = [];
  bool _isLoading = false;
  String? _error;
  livework_auth.AppUser? _currentUser;

  StreamSubscription<QuerySnapshot>? _reportSubscription;

  List<ReportModel> get reports => _reports;
  List<ReportModel> get pendingReports => _pendingReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ReportModel> get archivedReports =>
      _reports.where((report) => report.isArchived).toList();

  Map<String, List<ReportModel>> get archivedReportsByDate {
    final Map<String, List<ReportModel>> grouped = {};
    
    for (final report in archivedReports) {
      // FIXED: Use original creation date (timestamp) instead of archive date
      final dateKey = _formatDateKey(report.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(report);
    }
    
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    final sortedMap = <String, List<ReportModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    
    return sortedMap;
  }

  void setCurrentUser(livework_auth.AppUser? user) {
    _currentUser = user;
  }

  List<ReportModel> get activeReports =>
      _reports.where((report) => report.status != ReportStatus.done && !report.isArchived).toList();

  List<ReportModel> get completedReports =>
      _reports.where((report) => report.status == ReportStatus.done && !report.isArchived).toList();

  ReportProvider() {
    loadReports();
  }

  Future<void> loadReports({String? siteId, bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _reportSubscription?.cancel();

    try {
      print('Loading reports from Firestore...');
      final query = FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true);

      final initialSnapshot = await query.get();
      print('Initial snapshot: ${initialSnapshot.docs.length} reports');

      if (initialSnapshot.docs.isNotEmpty) {
        _reports = initialSnapshot.docs
            .map((doc) {
              try {
                return ReportModel.fromFirestore(
                    doc.id, doc.data() as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing document ${doc.id}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<ReportModel>()
            .toList();
        print(
            'Successfully loaded ${_reports.length} reports from initial snapshot');
      } else {
        print('No reports found in initial snapshot, using mock data');
        _loadMockData(siteId);
      }

      _isLoading = false;
      notifyListeners();

      _reportSubscription = query.snapshots().listen((snapshot) {
        try {
          print(
              'Real-time update: ${snapshot.docs.length} reports from Firestore');
          if (snapshot.docs.isNotEmpty) {
            _reports = snapshot.docs
                .map((doc) {
                  try {
                    return ReportModel.fromFirestore(
                        doc.id, doc.data() as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing document ${doc.id}: $e');
                    return null;
                  }
                })
                .where((report) => report != null)
                .cast<ReportModel>()
                .toList();

            print(
                'Successfully updated ${_reports.length} reports from real-time listener');
          } else {
            print('No reports found in real-time update, using mock data');
            _loadMockData(siteId);
          }
        } catch (e) {
          print('Error parsing Firestore data: $e');
          _error = 'Error parsing data: $e';
          _loadMockData(siteId);
        }
        notifyListeners();
      }, onError: (e) {
        print('Firestore real-time listener error: $e');
        _error = 'Firestore error: $e';
        _loadMockData(siteId);
        notifyListeners();
      });
    } catch (e) {
      print('Error setting up Firestore connection: $e');
      _error = 'Failed to connect to Firestore: $e';
      _loadMockData(siteId);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReports({String? siteId}) async {
    print('Manually refreshing reports...');
    await loadReports(siteId: siteId, forceRefresh: true);
  }

  void _loadMockData(String? siteId) {
    _reports = [
      ReportModel(
        id: 'report_001',
        siteId: siteId ?? 'site_001',
        zone: 'zone_a',
        type: ReportType.work,
        description: 'Electrical maintenance in building A',
        photoUrls: [],
        status: ReportStatus.inProgress,
        timestamp: DateTime.now().subtract(const Duration(days: 3)), // Different date for testing
        reporterName: 'John Doe',
        reporterId: 'user_123',
        latitude: 29.7604,
        longitude: -95.3698,
      ),
      ReportModel(
        id: 'report_002',
        siteId: siteId ?? 'site_001',
        zone: 'zone_b',
        type: ReportType.hazard,
        description: 'Slippery floor near entrance',
        photoUrls: [],
        status: ReportStatus.hazard,
        timestamp: DateTime.now().subtract(const Duration(days: 2)), // Different date for testing
        reporterName: 'Jane Smith',
        reporterId: 'user_456',
        latitude: 29.7605,
        longitude: -95.3699,
      ),
      ReportModel(
        id: 'report_003',
        siteId: siteId ?? 'site_001',
        zone: 'zone_c',
        type: ReportType.work,
        description: 'Completed plumbing repair',
        photoUrls: [],
        status: ReportStatus.done,
        timestamp: DateTime.now().subtract(const Duration(days: 1)), // Different date for testing
        reporterName: 'Bob Wilson',
        reporterId: 'user_789',
        latitude: 29.7606,
        longitude: -95.3700,
      ),
    ];
  }

  Future<void> createReport({
    required String siteId,
    required String zone,
    required ReportType type,
    required String description,
    required List<String> photoUrls,
    double? latitude,
    double? longitude,
    double? mapX,
    double? mapY,
  }) async {
    try {
      final reporterName = _currentUser?.name ?? 'Unknown User';
      final reporterId = _currentUser?.uid ?? 'unknown';

      final newReport = ReportModel(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        siteId: siteId,
        zone: zone,
        type: type,
        description: description,
        photoUrls: photoUrls,
        status: type == ReportType.hazard
            ? ReportStatus.hazard
            : ReportStatus.inProgress,
        timestamp: DateTime.now(),
        reporterName: reporterName,
        reporterId: reporterId,
        latitude: latitude,
        longitude: longitude,
        mapX: mapX,
        mapY: mapY,
      );

      try {
        final docRef = await FirebaseFirestore.instance
            .collection('reports')
            .add(newReport.toFirestore());
        print('Report added to Firestore successfully with ID: ${docRef.id}');
      } catch (e) {
        print('Error adding to Firestore: $e');
        _error = 'Failed to save report to cloud: $e';
        _reports.add(newReport);
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _error = 'Failed to create report: $e';
      notifyListeners();
    }
  }

  Future<void> updateReportStatus(
      String reportId, ReportStatus newStatus) async {
    try {
      final reportIndex =
          _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        _reports[reportIndex] =
            _reports[reportIndex].copyWith(status: newStatus);

        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update({'status': newStatus.name});
          print(
              'Report status updated in Firestore: $reportId -> ${newStatus.name}');
        } catch (e) {
          print('Error updating report status in Firestore: $e');
          _error = 'Failed to update report status in cloud: $e';
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update report status: $e';
      notifyListeners();
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      try {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .delete();
        print('Report deleted from Firestore: $reportId');
      } catch (e) {
        print('Error deleting report from Firestore: $e');
        _error = 'Failed to delete report from cloud: $e';
        notifyListeners();
        return;
      }

      _reports.removeWhere((report) => report.id == reportId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete report: $e';
      notifyListeners();
    }
  }

  Future<void> archiveReport(String reportId) async {
    try {
      final reportIndex = _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        final updatedReport = _reports[reportIndex].copyWith(
          isArchived: true,
          archivedDate: DateTime.now(), // Still store archive date for reference
        );
        _reports[reportIndex] = updatedReport;

        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update({
                'isArchived': true,
                'archivedDate': Timestamp.fromDate(DateTime.now()),
              });
          print('Report archived in Firestore: $reportId');
        } catch (e) {
          print('Error archiving report in Firestore: $e');
          _error = 'Failed to archive report in cloud: $e';
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to archive report: $e';
      notifyListeners();
    }
  }

  Future<void> unarchiveReport(String reportId) async {
    try {
      final reportIndex = _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        final updatedReport = _reports[reportIndex].copyWith(
          isArchived: false,
          archivedDate: null,
        );
        _reports[reportIndex] = updatedReport;

        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update({
                'isArchived': false,
                'archivedDate': null,
              });
          print('Report unarchived in Firestore: $reportId');
        } catch (e) {
          print('Error unarchiving report in Firestore: $e');
          _error = 'Failed to unarchive report in cloud: $e';
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to unarchive report: $e';
      notifyListeners();
    }
  }

  Future<void> deleteArchivedReport(String reportId) async {
    try {
      try {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .delete();
        print('Archived report deleted from Firestore: $reportId');
      } catch (e) {
        print('Error deleting archived report from Firestore: $e');
        _error = 'Failed to delete archived report from cloud: $e';
        notifyListeners();
        return;
      }

      _reports.removeWhere((report) => report.id == reportId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete archived report: $e';
      notifyListeners();
    }
  }

  Future<void> deleteArchivedReportsByDate(String dateKey) async {
    try {
      final reportsToDelete = archivedReportsByDate[dateKey] ?? [];
      final reportIds = reportsToDelete.map((report) => report.id).toList();
      
      for (final reportId in reportIds) {
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .delete();
          print('Archived report deleted from Firestore: $reportId');
        } catch (e) {
          print('Error deleting archived report from Firestore: $e');
          _error = 'Failed to delete some archived reports from cloud: $e';
        }
      }

      _reports.removeWhere((report) => reportIds.contains(report.id));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete archived reports: $e';
      notifyListeners();
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void addReport(ReportModel report) {
    _reports.add(report);
    notifyListeners();
  }

  void addPendingReport(ReportModel report) {
    _pendingReports.add(report);
    notifyListeners();
  }

  Future<void> syncPendingReports() async {
    _reports.addAll(_pendingReports);
    _pendingReports.clear();
    notifyListeners();
  }

  List<ReportModel> applyFilters({
    ReportType? type,
    ReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _reports.where((report) {
      if (type != null && report.type != type) return false;
      if (status != null && report.status != status) return false;
      if (startDate != null && report.timestamp.isBefore(startDate))
        return false;
      if (endDate != null && report.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    super.dispose();
  }
}