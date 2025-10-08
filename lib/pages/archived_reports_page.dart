// --------------------------------------------------
import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
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

class _ArchivedReportsPageState extends State<ArchivedReportsPage> {
  // LAZY LOADING: ADDED CONTROLLER FOR SCROLL DETECTION
  final ScrollController _scrollController = ScrollController();

  // LAZY LOADING: ADDED VARIABLES FOR PAGINATION
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    // LAZY LOADING: ADDED SCROLL LISTENER FOR LOADING MORE DATA
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    // LAZY LOADING: DISPOSE SCROLL CONTROLLER
    _scrollController.dispose();
    super.dispose();
  }

  // LAZY LOADING: NEW METHOD TO HANDLE SCROLL EVENTS
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  // LAZY LOADING: NEW METHOD TO LOAD INITIAL DATA
  void _loadInitialData() {
    _currentPage = 0;
    _hasMoreData = true;
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      reportProvider.loadReports(siteId: siteProvider.currentSite!.id);
    }
  }

  // LAZY LOADING: NEW METHOD TO LOAD MORE DATA WHEN SCROLLING
  void _loadMoreData() {
    if (!_isLoadingMore && _hasMoreData) {
      setState(() {
        _isLoadingMore = true;
      });

      // Simulate loading delay
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _currentPage++;
          _isLoadingMore = false;
          // LAZY LOADING: CHECK IF WE'VE REACHED THE END OF AVAILABLE DATA
          // In a real implementation, you would check the actual data count from your API
          final reportProvider =
              Provider.of<ReportProvider>(context, listen: false);
          final allArchivedReports = reportProvider.archivedReports;
          final totalLoaded = (_currentPage + 1) * _pageSize;

          if (totalLoaded >= allArchivedReports.length) {
            _hasMoreData = false;
          }
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // LAZY LOADING: RESET PAGINATION WHEN DEPENDENCIES CHANGE
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      // backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(translate(context, 'archived_reports')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadInitialData(); // LAZY LOADING: UPDATED TO USE NEW METHOD
              final siteProvider =
                  Provider.of<SiteProvider>(context, listen: false);
              final reportProvider =
                  Provider.of<ReportProvider>(context, listen: false);
              if (siteProvider.currentSite != null) {
                reportProvider.refreshReports(
                    siteId: siteProvider.currentSite!.id);
              }
            },
            tooltip: translate(context, 'refresh_reports'),
          ),
        ],
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

          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                    onPressed: () {
                      reportProvider.loadReports(
                          siteId: siteProvider.currentSite!.id);
                    },
                    child: Text(translate(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          final archivedReportsByDate = reportProvider.archivedReportsByDate;

          // LAZY LOADING: GET PAGINATED DATA
          final paginatedArchivedReports =
              _getPaginatedArchivedReports(archivedReportsByDate);

          return _buildArchivedReportsList(
              paginatedArchivedReports, reportProvider, isAdmin);
        },
      ),
    );
  }

  // LAZY LOADING: NEW METHOD TO GET PAGINATED ARCHIVED REPORTS
  Map<String, List<ReportModel>> _getPaginatedArchivedReports(
      Map<String, List<ReportModel>> allArchivedReports) {
    if (allArchivedReports.isEmpty) return {};

    // LAZY LOADING: CONVERT THE MAP TO A LIST OF ENTRIES FOR PAGINATION
    final entries = allArchivedReports.entries.toList();
    final totalItemsToShow = (_currentPage + 1) * _pageSize;

    // LAZY LOADING: CALCULATE HOW MANY DATE GROUPS TO SHOW BASED ON ITEM COUNT
    int currentItemCount = 0;
    final Map<String, List<ReportModel>> paginatedResult = {};

    for (final entry in entries) {
      if (currentItemCount >= totalItemsToShow) break;

      final dateKey = entry.key;
      final reports = entry.value;

      if (currentItemCount + reports.length <= totalItemsToShow) {
        // LAZY LOADING: ADD COMPLETE DATE GROUP
        paginatedResult[dateKey] = reports;
        currentItemCount += reports.length;
      } else {
        // LAZY LOADING: ADD PARTIAL DATE GROUP (LAST ONE)
        final remainingItems = totalItemsToShow - currentItemCount;
        paginatedResult[dateKey] = reports.sublist(0, remainingItems);
        break;
      }
    }

    return paginatedResult;
  }

  Widget _buildArchivedReportsList(
      Map<String, List<ReportModel>> archivedReportsByDate,
      ReportProvider reportProvider,
      bool isAdmin) {
    if (archivedReportsByDate.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _loadInitialData(); // LAZY LOADING: RESET PAGINATION ON REFRESH
          final siteProvider =
              Provider.of<SiteProvider>(context, listen: false);
          if (siteProvider.currentSite != null) {
            await reportProvider.refreshReports(
                siteId: siteProvider.currentSite!.id);
          }
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
        _loadInitialData(); // LAZY LOADING: RESET PAGINATION ON REFRESH
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        if (siteProvider.currentSite != null) {
          await reportProvider.refreshReports(
              siteId: siteProvider.currentSite!.id);
        }
      },
      child: ListView.builder(
        // LAZY LOADING: ADDED SCROLL CONTROLLER
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: archivedReportsByDate.length +
            (_hasMoreData ? 1 : 0), // LAZY LOADING: ADD LOADING ITEM
        itemBuilder: (context, index) {
          // LAZY LOADING: CHECK IF THIS IS THE LOADING INDICATOR
          if (index == archivedReportsByDate.length) {
            return _buildLoadingIndicator();
          }

          final dateKey = archivedReportsByDate.keys.elementAt(index);
          final reports = archivedReportsByDate[dateKey]!;

          return _buildDateSection(dateKey, reports, reportProvider, isAdmin);
        },
      ),
    );
  }

  // LAZY LOADING: NEW METHOD TO BUILD LOADING INDICATOR
  Widget _buildLoadingIndicator() {
    return _isLoadingMore
        ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : _hasMoreData
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Scroll to load more...'),
                ),
              )
            : const SizedBox.shrink();
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

  void _unarchiveReport(ReportModel report, ReportProvider reportProvider) {
    reportProvider.unarchiveReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'report_unarchived')} "${report.description}"'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
