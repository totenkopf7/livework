import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:livework_view/providers/auth_provider.dart' as livework_auth;
import 'package:livework_view/providers/language_provider.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../providers/site_provider.dart';
import '../data/models/report_model.dart';
import '../widgets/report_card_widget.dart';
import '../helpers/localization_helper.dart';

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
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      // backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(translate(context, 'completed_reports')),
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

          final completedReports = reportProvider.completedReports;

          return _buildReportsList(completedReports, reportProvider, isAdmin);
        },
      ),
    );
  }

  Widget _buildReportsList(
      List<ReportModel> reports, ReportProvider reportProvider, bool isAdmin) {
    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          final siteProvider =
              Provider.of<SiteProvider>(context, listen: false);
          if (siteProvider.currentSite != null) {
            await reportProvider.refreshReports(
                siteId: siteProvider.currentSite!.id);
          }
        },
        child: Center(child: Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
          return Text(
            translate(
                context, 'no_completed_reports'), // UPDATED: Use translation
            style: TextStyle(
              fontSize: 16, color: Colors.grey,
              // fontWeight: FontWeight.bold,
            ),
          );
        })),
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
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildDismissibleReportCard(report, reportProvider, isAdmin);
        },
      ),
    );
  }

  Widget _buildDismissibleReportCard(
      ReportModel report, ReportProvider reportProvider, bool isAdmin) {
    if (kIsWeb && isAdmin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReportCardWidget(
          report: report,
          onStatusChanged: (newStatus) {
            reportProvider.updateReportStatus(report.id, newStatus);
          },
          showDeleteButton: isAdmin,
          showArchiveButton: isAdmin,
          showStatusDropdown:
              true, // FIXED: Always show status dropdown in Reports section
          onDelete: () => _showDeleteConfirmation(report, reportProvider),
          onArchive: () => _showArchiveConfirmation(report, reportProvider),
        ),
      );
    }

    if (isAdmin) {
      return Dismissible(
        key: Key('${report.id}_completed'),
        direction: DismissDirection.horizontal,
        background: _buildSwipeBackground(
            Colors.orange, Icons.archive, translate(context, 'archive')),
        secondaryBackground: _buildSwipeBackground(
            Colors.red, Icons.delete, translate(context, 'delete')),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await _showDeleteConfirmationDialog(report);
          } else {
            return await _showArchiveConfirmationDialog(report);
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteReport(report, reportProvider);
          } else {
            _archiveReport(report, reportProvider);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ReportCardWidget(
            report: report,
            onStatusChanged: (newStatus) {
              reportProvider.updateReportStatus(report.id, newStatus);
            },
            showStatusDropdown:
                true, // FIXED: Always show status dropdown in Reports section
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReportCardWidget(
          report: report,
          onStatusChanged: (newStatus) {
            reportProvider.updateReportStatus(report.id, newStatus);
          },
          showStatusDropdown:
              true, // FIXED: Show status dropdown for non-admin users too
        ),
      );
    }
  }

  Widget _buildSwipeBackground(Color color, IconData icon, String text) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showArchiveConfirmationDialog(ReportModel report) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(translate(context, 'archive_report')),
            content: Text(
                '${translate(context, 'archive_report_confirmation')} "${report.description}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(translate(context, 'cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: Text(translate(context, 'archive')),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _archiveReport(ReportModel report, ReportProvider reportProvider) {
    reportProvider.archiveReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'report_archived')} "${report.description}"'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: translate(context, 'undo'),
          textColor: Colors.white,
          onPressed: () {
            reportProvider.unarchiveReport(report.id);
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(ReportModel report) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(translate(context, 'delete_report')),
            content: Text(
                '${translate(context, 'delete_report_confirmation')} "${report.description}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(translate(context, 'cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(translate(context, 'delete')),
              ),
            ],
          ),
        ) ??
        false;
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

  void _showArchiveConfirmation(
      ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'archive_report')),
        content: Text(
            '${translate(context, 'archive_report_confirmation')} "${report.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _archiveReport(report, reportProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(translate(context, 'archive')),
          ),
        ],
      ),
    );
  }

  void _deleteReport(ReportModel report, ReportProvider reportProvider) {
    reportProvider.deleteReport(report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${translate(context, 'report_deleted')} "${report.description}"'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: translate(context, 'undo'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(translate(context, 'undo_not_available')),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
