// --------------------------------------------------
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

  int _archivedReportsCount = 0;

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

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedMap = <String, List<ReportModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

// ADD THIS METHOD TO HANDLE REPORT EDITS
  Future<void> editReport({
    required String reportId,
    String? description,
    String? zone,
    ReportType? type,
    List<String>? photoUrls,
    double? mapX,
    double? mapY,
    List<String>? performedBy,
  }) async {
    try {
      // Find the report to edit
      final reportIndex =
          _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex == -1) {
        throw Exception('Report not found');
      }

      final originalReport = _reports[reportIndex];

      // Create updated report with new values
      final updatedReport = originalReport.copyWith(
        description: description ?? originalReport.description,
        zone: zone ?? originalReport.zone,
        type: type ?? originalReport.type,
        photoUrls: photoUrls ?? originalReport.photoUrls,
        mapX: mapX ?? originalReport.mapX,
        mapY: mapY ?? originalReport.mapY,
        lastEditedAt: DateTime.now(),
        lastEditedBy: _currentUser?.name ?? 'Unknown User',
        editCount: originalReport.editCount + 1,
        performedBy: performedBy ?? originalReport.performedBy,
      );

      // Update in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .update(updatedReport.toFirestore());
        print('Report updated in Firestore: $reportId');
      } catch (e) {
        print('Error updating report in Firestore: $e');
        throw Exception('Failed to update report in cloud: $e');
      }

      // Update local state - THIS IS IMPORTANT FOR UI UPDATE
      _reports[reportIndex] = updatedReport;
      notifyListeners(); // This triggers UI rebuild
    } catch (e) {
      // Use a more descriptive error message
      _error = 'Failed to edit report: ${e.toString()}';
      notifyListeners();
      throw e; // Re-throw to handle in UI
    }
  }

  void setCurrentUser(livework_auth.AppUser? user) {
    _currentUser = user;
  }

  List<ReportModel> get activeReports => _reports
      .where(
          (report) => report.status != ReportStatus.done && !report.isArchived)
      .toList();

  List<ReportModel> get completedReports => _reports
      .where(
          (report) => report.status == ReportStatus.done && !report.isArchived)
      .toList();

  ReportProvider() {
    loadReports();
  }

// ==== CHANGE START: ADD COMPOSITE INDEX SUPPORT AND FALLBACK ====
  Future<void> loadReports(
      {String? siteId,
      bool forceRefresh = false,
      bool excludeArchived = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _reportSubscription?.cancel();

    try {
      print(
          'Loading reports from Firestore with archived filter: $excludeArchived');

      Query query = FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true);

      // Only add archived filter if we have the index, otherwise filter client-side
      bool useServerSideFiltering = false;

      if (excludeArchived) {
        try {
          // Test if we can use server-side filtering by making a simple query
          query = query.where('isArchived', isEqualTo: false);
          useServerSideFiltering = true;
          print('Using server-side archived filtering');
        } catch (e) {
          print(
              'Server-side filtering not available, will filter client-side: $e');
          useServerSideFiltering = false;
          // Reset query without the archived filter
          query = FirebaseFirestore.instance
              .collection('reports')
              .orderBy('timestamp', descending: true);
        }
      }

      final initialSnapshot = await query.get();
      print('Initial snapshot: ${initialSnapshot.docs.length} reports');

      List<ReportModel> loadedReports = [];

      if (initialSnapshot.docs.isNotEmpty) {
        loadedReports = initialSnapshot.docs
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

        // Apply client-side filtering if server-side filtering failed
        if (excludeArchived && !useServerSideFiltering) {
          loadedReports =
              loadedReports.where((report) => !report.isArchived).toList();
          print(
              'Applied client-side archived filtering: ${loadedReports.length} reports');
        }

        _reports = loadedReports;
        print('Successfully loaded ${_reports.length} reports');
      } else {
        print('No reports found in initial snapshot, using mock data');
        // _loadMockData(siteId);
      }

      _isLoading = false;
      notifyListeners();

      _reportSubscription = query.snapshots().listen((snapshot) {
        try {
          print(
              'Real-time update: ${snapshot.docs.length} reports from Firestore');
          if (snapshot.docs.isNotEmpty) {
            List<ReportModel> updatedReports = snapshot.docs
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

            // Apply client-side filtering for real-time updates too
            if (excludeArchived && !useServerSideFiltering) {
              updatedReports =
                  updatedReports.where((report) => !report.isArchived).toList();
            }

            _reports = updatedReports;
            print(
                'Successfully updated ${_reports.length} reports from real-time listener');
          } else {
            print('No reports found in real-time update, using mock data');
            // _loadMockData(siteId);
          }
        } catch (e) {
          print('Error parsing Firestore data: $e');
          _error = 'Error parsing data: $e';
          // _loadMockData(siteId);
        }
        notifyListeners();
      }, onError: (e) {
        print('Firestore real-time listener error: $e');
        _error = 'Firestore error: $e';
        // _loadMockData(siteId);
        notifyListeners();
      });
    } catch (e) {
      print('Error setting up Firestore connection: $e');
      _error = 'Failed to connect to Firestore: $e';
      // _loadMockData(siteId);
      _isLoading = false;
      notifyListeners();
    }
  }
// ==== CHANGE END ====

// ==== CHANGE START: UPDATE REFRESH METHOD TO SUPPORT FILTERING ====
  Future<void> refreshReports(
      {String? siteId, bool excludeArchived = true}) async {
    print('Manually refreshing reports with archived filter: $excludeArchived');
    await loadReports(
        siteId: siteId, forceRefresh: true, excludeArchived: excludeArchived);
  }
// ==== CHANGE END ====

// ==== CHANGE START: FIX PAGINATION FOR ARCHIVED REPORTS ====
  Future<List<ReportModel>> loadArchivedReportsPaginated({
    required String siteId,
    required int page,
    required int pageSize,
  }) async {
    try {
      print('Loading archived reports page $page with size $pageSize');

      Query query = FirebaseFirestore.instance
          .collection('reports')
          .where('isArchived', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(pageSize);

      // For pages beyond the first, we need to start after the last document of previous page
      if (page > 0) {
        // Get the last document from the previously loaded reports to use as startAfter
        if (_loadedArchivedReportsForPagination.isNotEmpty) {
          final lastReport = _loadedArchivedReportsForPagination.last;
          query = query.startAfter([lastReport.timestamp]);
        }
      }

      final snapshot = await query.get();

      final reports = snapshot.docs
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

      // Store for pagination tracking
      if (reports.isNotEmpty) {
        _loadedArchivedReportsForPagination.addAll(reports);
      }

      print('Loaded ${reports.length} archived reports for page $page');
      return reports;
    } catch (e) {
      print('Error loading paginated archived reports: $e');
      return [];
    }
  }

// Add this list to track loaded reports for pagination
  List<ReportModel> _loadedArchivedReportsForPagination = [];

// ==== CHANGE END ====

// ==== CHANGE START: ADD CLEAR PAGINATION METHOD ====
  Future<void> clearPaginationTracking() async {
    _loadedArchivedReportsForPagination.clear();
    print('Cleared pagination tracking');
  }
// ==== CHANGE END ====

// Helper method to get the last timestamp for pagination
  Timestamp? _getLastTimestampForPagination(int page) {
    if (_reports.isEmpty || page == 0) return null;

    // For archived reports pagination, we need to track the last loaded timestamp
    // This is a simplified version - you might need to adjust based on your data structure
    final allArchivedReports =
        _reports.where((report) => report.isArchived).toList();
    if (allArchivedReports.isEmpty) return null;

    allArchivedReports.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final startIndex = page * 10; // Adjust based on your page size
    if (startIndex >= allArchivedReports.length) return null;

    return Timestamp.fromDate(allArchivedReports[startIndex].timestamp);
  }
// ==== CHANGE END ====

  // void _loadMockData(String? siteId) {
  //   _reports = [
  //     ReportModel(
  //       id: 'report_001',
  //       siteId: siteId ?? 'site_001',
  //       zone: 'zone_a',
  //       type: ReportType.work,
  //       description: 'Electrical maintenance in building A',
  //       photoUrls: [],
  //       status: ReportStatus.inProgress,
  //       timestamp: DateTime.now()
  //           .subtract(const Duration(days: 3)), // Different date for testing
  //       reporterName: 'John Doe',
  //       reporterId: 'user_123',
  //       latitude: 29.7604,
  //       longitude: -95.3698,
  //     ),
  //     ReportModel(
  //       id: 'report_002',
  //       siteId: siteId ?? 'site_001',
  //       zone: 'zone_b',
  //       type: ReportType.hazard,
  //       description: 'Slippery floor near entrance',
  //       photoUrls: [],
  //       status: ReportStatus.hazard,
  //       timestamp: DateTime.now()
  //           .subtract(const Duration(days: 2)), // Different date for testing
  //       reporterName: 'Jane Smith',
  //       reporterId: 'user_456',
  //       latitude: 29.7605,
  //       longitude: -95.3699,
  //     ),
  //     ReportModel(
  //       id: 'report_003',
  //       siteId: siteId ?? 'site_001',
  //       zone: 'zone_c',
  //       type: ReportType.work,
  //       description: 'Completed plumbing repair',
  //       photoUrls: [],
  //       status: ReportStatus.done,
  //       timestamp: DateTime.now()
  //           .subtract(const Duration(days: 1)), // Different date for testing
  //       reporterName: 'Bob Wilson',
  //       reporterId: 'user_789',
  //       latitude: 29.7606,
  //       longitude: -95.3700,
  //     ),
  //   ];
  // }

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
    List<String>? performedBy = const [],
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
        performedBy: performedBy ?? [],
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
      final reportIndex =
          _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        final updatedReport = _reports[reportIndex].copyWith(
          isArchived: true,
          archivedDate:
              DateTime.now(), // Still store archive date for reference
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

// ==== CHANGE START: FIX UNARCHIVE TO WORK WITH PAGINATED DATA ====
  Future<void> unarchiveReport(String reportId) async {
    try {
      print('Attempting to unarchive report: $reportId');

      // First, try to find the report in the currently loaded reports
      int reportIndex = _reports.indexWhere((report) => report.id == reportId);

      // If not found in loaded reports, we need to fetch it from Firestore
      if (reportIndex == -1) {
        print('Report not found in loaded reports, fetching from Firestore...');
        try {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .get();

          if (docSnapshot.exists) {
            final report = ReportModel.fromFirestore(
                reportId, docSnapshot.data() as Map<String, dynamic>);
            // Add the report to our local list
            _reports.add(report);
            reportIndex = _reports.length - 1;
            print('Fetched report from Firestore: ${report.description}');
          } else {
            print('Report not found in Firestore: $reportId');
            _error = 'Report not found in database: $reportId';
            notifyListeners();
            return;
          }
        } catch (e) {
          print('Error fetching report from Firestore: $e');
          _error = 'Error fetching report: $e';
          notifyListeners();
          return;
        }
      }

      if (reportIndex != -1) {
        final originalReport = _reports[reportIndex];
        print('Found report to unarchive: ${originalReport.description}');
        print(
            'Current status: ${originalReport.status}, isArchived: ${originalReport.isArchived}');

        // Create unarchived report
        final updatedReport = originalReport.copyWith(
          isArchived: false,
          archivedDate: null,
        );

        _reports[reportIndex] = updatedReport;

        // UPDATE ARCHIVED COUNT
        _archivedReportsCount--;
        if (_archivedReportsCount < 0) _archivedReportsCount = 0;

        print(
            'Updated report - isArchived: ${updatedReport.isArchived}, status: ${updatedReport.status}');
        print('New archived count: $_archivedReportsCount');

        try {
          final updateData = {
            'isArchived': false,
            'archivedDate': null,
          };

          print('Updating Firestore with: $updateData');

          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update(updateData);

          print('Successfully unarchived report in Firestore: $reportId');

          // If we're using paginated data, we might need to refresh the archived reports list
          // This ensures the UI updates properly
          notifyListeners();
        } catch (e) {
          print('Error unarchiving report in Firestore: $e');
          _error = 'Failed to unarchive report in cloud: $e';
          // Revert the change if Firestore update fails
          _reports[reportIndex] = originalReport;
          _archivedReportsCount++; // Revert count
          print('Reverted changes due to Firestore error');
          notifyListeners();
        }

        print('Notified listeners of unarchive change');
      }
    } catch (e) {
      print('Unexpected error in unarchiveReport: $e');
      _error = 'Failed to unarchive report: $e';
      notifyListeners();
    }
  }
// ==== CHANGE END ====

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
