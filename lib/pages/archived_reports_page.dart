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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      reportProvider.loadReports(siteId: siteProvider.currentSite!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(translate(context, 'archived_reports')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
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

          return _buildArchivedReportsList(
              archivedReportsByDate, reportProvider, isAdmin);
        },
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
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        if (siteProvider.currentSite != null) {
          await reportProvider.refreshReports(
              siteId: siteProvider.currentSite!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archivedReportsByDate.length,
        itemBuilder: (context, index) {
          final dateKey = archivedReportsByDate.keys.elementAt(index);
          final reports = archivedReportsByDate[dateKey]!;

          return _buildDateSection(dateKey, reports, reportProvider, isAdmin);
        },
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
