// --------------------------------------------------
import 'package:flutter/material.dart';
import 'package:livework_view/widgets/animated_drawer_icon.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/widgets/safety_drawer_widget.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../providers/site_provider.dart';
import '../providers/auth_provider.dart' as livework_auth;
import '../data/models/report_model.dart';
import '../widgets/report_card_widget.dart';
import '../helpers/localization_helper.dart';

class ArchivedReportsPage extends StatefulWidget {
  const ArchivedReportsPage({Key? key}) : super(key: key);

  @override
  State<ArchivedReportsPage> createState() => _ArchivedReportsPageState();
}

class _ArchivedReportsPageState extends State<ArchivedReportsPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  // REAL LAZY LOADING: PAGINATION VARIABLES
  int _currentPage = 0;
  final int _pageSize = 10; // Load 10 reports at a time
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _hasLoadedInitialData = false;
  List<ReportModel> _loadedArchivedReports = []; // Only loaded reports
  Map<String, List<ReportModel>> _paginatedArchivedReportsByDate = {};
  bool _isInitialLoading = false; // Changed to false initially

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // REMOVED: Auto-load on init - user will manually load
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // REMOVED: Auto-load on dependencies change
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // REAL LAZY LOADING: LOAD MORE DATA WHEN SCROLLING TO BOTTOM
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  // REAL LAZY LOADING: LOAD INITIAL BATCH OF ARCHIVED REPORTS
// ==== CHANGE START: CLEAR PAGINATION TRACKING ON INITIAL LOAD ====
// REAL LAZY LOADING: LOAD INITIAL BATCH OF ARCHIVED REPORTS
  Future<void> _loadInitialData() async {
    if (_hasLoadedInitialData) return;

    setState(() {
      _isInitialLoading = true;
    });

    _currentPage = 0;
    _hasMoreData = true;
    _loadedArchivedReports.clear();
    _paginatedArchivedReportsByDate.clear();

    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      try {
        // CLEAR PAGINATION TRACKING BEFORE LOADING FRESH DATA
        await reportProvider.clearPaginationTracking();

        // LOAD FIRST PAGE OF ARCHIVED REPORTS FROM DATABASE
        final firstPageReports =
            await reportProvider.loadArchivedReportsPaginated(
          siteId: siteProvider.currentSite!.id,
          page: _currentPage,
          pageSize: _pageSize,
        );

        setState(() {
          _loadedArchivedReports = firstPageReports;
          _paginatedArchivedReportsByDate =
              _groupReportsByDate(firstPageReports);
          _hasLoadedInitialData = true;
          _isInitialLoading = false;
          _hasMoreData = firstPageReports.length ==
              _pageSize; // More data if we got a full page
        });
      } catch (e) {
        print('Error loading initial archived reports: $e');
        setState(() {
          _isInitialLoading = false;
        });
      }
    } else {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

// ==== CHANGE END ====
  // REAL LAZY LOADING: LOAD MORE ARCHIVED REPORTS FROM DATABASE
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      try {
        final nextPageReports =
            await reportProvider.loadArchivedReportsPaginated(
          siteId: siteProvider.currentSite!.id,
          page: _currentPage + 1,
          pageSize: _pageSize,
        );

        setState(() {
          _currentPage++;
          _loadedArchivedReports.addAll(nextPageReports);
          _paginatedArchivedReportsByDate =
              _groupReportsByDate(_loadedArchivedReports);
          _isLoadingMore = false;
          _hasMoreData = nextPageReports.length ==
              _pageSize; // More data if we got a full page
        });
      } catch (e) {
        print('Error loading more archived reports: $e');
        setState(() {
          _isLoadingMore = false;
        });
      }
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // GROUP LOADED REPORTS BY DATE FOR DISPLAY
  Map<String, List<ReportModel>> _groupReportsByDate(
      List<ReportModel> reports) {
    final Map<String, List<ReportModel>> grouped = {};

    for (final report in reports) {
      final dateKey = _formatDateKey(report.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(report);
    }

    // Sort dates in descending order (newest first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <String, List<ReportModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      drawer: const SafetyDrawer(),
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return AnimatedDrawerIcon(
            onPressed: () {
              // This will open the drawer
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: Text(translate(context, 'archived_reports')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        // REMOVED: Refresh button from app bar
      ),
      body: Consumer2<ReportProvider, SiteProvider>(
        builder: (context, reportProvider, siteProvider, child) {
          if (siteProvider.currentSite == null) {
            return Center(
              child: Text(
                translate(context, 'no_site_selected'),
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          // SHOW LOAD BUTTON IF NO DATA LOADED YET
          if (!_hasLoadedInitialData && !_isInitialLoading) {
            return _buildLoadArchivedReportsButton();
          }

          if (_isInitialLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === LOGO IMAGE ===
                  Image(
                    image: AssetImage('assets/images/logo.png'),
                    width: 90,
                    height: 90,
                  ),
                  SizedBox(height: 20),

                  // === PROGRESS BAR ===
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.background),
                      backgroundColor: Colors.black12,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }

          if (reportProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${translate(context, 'error')}: ${reportProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: Text(translate(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          return _buildArchivedReportsList(
              _paginatedArchivedReportsByDate, reportProvider, isAdmin);
        },
      ),
    );
  }

  // NEW: BUILD LOAD ARCHIVED REPORTS BUTTON
  Widget _buildLoadArchivedReportsButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: Text(translate(context, 'load_archived_reports')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedReportsList(
      Map<String, List<ReportModel>> archivedReportsByDate,
      ReportProvider reportProvider,
      bool isAdmin) {
    if (archivedReportsByDate.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _hasLoadedInitialData = false;
          });
          await _loadInitialData();
        },
        child: Center(
          child: Text(
            translate(context, 'no_archived_reports'),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _hasLoadedInitialData = false;
        });
        await _loadInitialData();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: archivedReportsByDate.length +
            (_hasMoreData || _isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator or load more button at the end
          if (index == archivedReportsByDate.length) {
            if (_isLoadingMore) {
              return _buildLoadingIndicator();
            } else if (_hasMoreData) {
              return _buildLoadMoreTrigger();
            } else {
              return const SizedBox.shrink();
            }
          }

          final dateKey = archivedReportsByDate.keys.elementAt(index);
          final reports = archivedReportsByDate[dateKey]!;

          return _buildDateSection(dateKey, reports, reportProvider, isAdmin);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
          child: SizedBox(
        width: 120,
        child: LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
          backgroundColor: Colors.black12,
          minHeight: 4,
        ),
      )),
    );
  }

  Widget _buildLoadMoreTrigger() {
    return GestureDetector(
      onTap: _loadMoreData,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              translate(context, 'load_more_reports'),
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(String dateKey, List<ReportModel> reports,
      ReportProvider reportProvider, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed layout to prevent overflow
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateHeader(dateKey),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reports.length} ${translate(context, 'tasks')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _showDeleteDateConfirmation(
                        dateKey, reports, reportProvider),
                    tooltip: translate(context, 'delete_all_reports_for_date'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: reports
                  .map((report) =>
                      _buildArchivedReportCard(report, reportProvider, isAdmin))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedReportCard(
      ReportModel report, ReportProvider reportProvider, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReportCardWidget(
        report: report,
        onStatusChanged: (newStatus) {
          reportProvider.updateReportStatus(report.id, newStatus);
        },
        showDeleteButton: isAdmin,
        showUnarchiveButton: isAdmin,
        onDelete: () => _showDeleteConfirmation(report, reportProvider),
        onUnarchive: () => _showUnarchiveConfirmation(report, reportProvider),
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);

        // Format: 22 September 2025
        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];

        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return dateKey;
  }

  void _showDeleteDateConfirmation(String dateKey, List<ReportModel> reports,
      ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'delete_all_reports')),
        content: Text(
            '${translate(context, 'delete_all_reports_confirmation')} ${_formatDateHeader(dateKey)}? '
            '${translate(context, 'this_action_cannot_be_undone')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReportsByDate(dateKey, reports, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translate(context, 'delete_all')),
          ),
        ],
      ),
    );
  }

  void _deleteReportsByDate(String dateKey, List<ReportModel> reports,
      ReportProvider reportProvider) {
    reportProvider.deleteArchivedReportsByDate(dateKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'reports_deleted_for_date')} ${_formatDateHeader(dateKey)}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDeleteConfirmation(
      ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'delete_report')),
        content: Text(
            '${translate(context, 'delete_report_confirmation')} "${report.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReport(report, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translate(context, 'delete')),
          ),
        ],
      ),
    );
  }

  void _showUnarchiveConfirmation(
      ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'unarchive_report')),
        content: Text(
            '${translate(context, 'unarchive_report_confirmation')} "${report.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unarchiveReport(report, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(translate(context, 'unarchive')),
          ),
        ],
      ),
    );
  }

  void _deleteReport(ReportModel report, ReportProvider reportProvider) {
    reportProvider.deleteArchivedReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'report_deleted')} "${report.description}"'),
        backgroundColor: Colors.red,
      ),
    );
  }

// ==== CHANGE START: REFRESH DATA AFTER UNARCHIVING ====
  void _unarchiveReport(
      ReportModel report, ReportProvider reportProvider) async {
    try {
      await reportProvider.unarchiveReport(report.id);

      // Refresh the archived reports list after successful unarchive
      setState(() {
        _hasLoadedInitialData = false; // This will trigger a reload
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${translate(context, 'report_unarchived')} "${report.description}"'),
          backgroundColor: Colors.green,
        ),
      );

      // Optional: Wait a bit then reload the data
      await Future.delayed(const Duration(milliseconds: 500));
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unarchive report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
// ==== CHANGE END ====
}
