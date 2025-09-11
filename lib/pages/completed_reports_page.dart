import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../providers/site_provider.dart';
import '../data/models/report_model.dart';
import '../widgets/report_card_widget.dart';

class CompletedReportsPage extends StatefulWidget {
  const CompletedReportsPage({Key? key}) : super(key: key);

  @override
  State<CompletedReportsPage> createState() => _CompletedReportsPageState();
}

class _CompletedReportsPageState extends State<CompletedReportsPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Reports'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (kIsWeb) // Only show delete all button on web
            Consumer<ReportProvider>(
              builder: (context, reportProvider, child) {
                final completedCount = reportProvider.completedReports.length;
                if (completedCount > 0) {
                  return IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => _showDeleteAllConfirmation(reportProvider),
                    tooltip: 'Delete All Completed Reports',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final siteProvider = Provider.of<SiteProvider>(context, listen: false);
              final reportProvider = Provider.of<ReportProvider>(context, listen: false);
              if (siteProvider.currentSite != null) {
                reportProvider.refreshReports(siteId: siteProvider.currentSite!.id);
              }
            },
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: Consumer2<ReportProvider, SiteProvider>(
        builder: (context, reportProvider, siteProvider, child) {
          if (siteProvider.currentSite == null) {
            return const Center(
              child: Text(
                'No site selected, please configure a site to view reports',
                style: TextStyle(fontSize: 16),
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
                    'Error: ${reportProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      reportProvider.loadReports(
                          siteId: siteProvider.currentSite!.id);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final completedReports = reportProvider.completedReports;

          return _buildReportsList(completedReports, reportProvider);
        },
      ),
    );
  }

  Widget _buildReportsList(List<ReportModel> reports, ReportProvider reportProvider) {
    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          final siteProvider = Provider.of<SiteProvider>(context, listen: false);
          if (siteProvider.currentSite != null) {
            await reportProvider.refreshReports(siteId: siteProvider.currentSite!.id);
          }
        },
        child: const Center(
          child: Text(
            'No completed reports found\nPull down to refresh',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        if (siteProvider.currentSite != null) {
          await reportProvider.refreshReports(siteId: siteProvider.currentSite!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildDismissibleReportCard(report, reportProvider);
        },
      ),
    );
  }

  Widget _buildDismissibleReportCard(ReportModel report, ReportProvider reportProvider) {
    // For web platform, use a delete button instead of swipe gesture
    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            ReportCardWidget(
              report: report,
              onStatusChanged: (newStatus) {
                // Completed reports can't change status, but we keep this for consistency
                reportProvider.updateReportStatus(report.id, newStatus);
              },
              showDeleteButton: true,
              onDelete: () => _showDeleteConfirmation(report, reportProvider),
            ),
            // Add a separate delete button as a test
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(report, reportProvider),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('DELETE REPORT (TEST)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // For mobile platforms, use swipe-to-delete
    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Report'),
            content: Text('Are you sure you want to delete "${report.description}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteReport(report, reportProvider);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReportCardWidget(
          report: report,
          onStatusChanged: (newStatus) {
            // Completed reports can't change status, but we keep this for consistency
            reportProvider.updateReportStatus(report.id, newStatus);
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "${report.description}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReport(report, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteReport(ReportModel report, ReportProvider reportProvider) {
    reportProvider.deleteReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report "${report.description}" deleted'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Note: Undo functionality would require more complex state management
            // For now, we'll just show a message that undo is not available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Undo not available - report has been permanently deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteAllConfirmation(ReportProvider reportProvider) {
    final completedCount = reportProvider.completedReports.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Completed Reports'),
        content: Text('Are you sure you want to delete all $completedCount completed reports? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Delete all completed reports
              for (final report in reportProvider.completedReports) {
                reportProvider.deleteReport(report.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$completedCount completed reports deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
