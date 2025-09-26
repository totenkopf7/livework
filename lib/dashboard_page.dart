import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:provider/provider.dart';
import 'providers/report_provider.dart';
import 'providers/site_provider.dart';
import 'data/models/report_model.dart';
import 'widgets/report_card_widget.dart';
import 'widgets/filter_panel_widget.dart';
import 'widgets/custom_map_widget.dart';
import 'helpers/localization_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showMapView = false;
  ReportType? _selectedType;
  ReportStatus? _selectedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      await reportProvider.loadReports(siteId: siteProvider.currentSite!.id);
    }
  }

  Future<void> _refreshReports() async {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (siteProvider.currentSite != null) {
      await reportProvider.loadReports(siteId: siteProvider.currentSite!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(translate(context, 'dashboard')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshReports();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(translate(context, 'reports_refreshed')),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: translate(context, 'refresh_reports'),
          ),
          IconButton(
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMapView = !_showMapView;
              });
            },
            tooltip: _showMapView
                ? translate(context, 'show_list_view')
                : translate(context, 'show_map_view'),
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                strokeWidth: 3,
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshReports,
                    child: Text(translate(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          // Only show active reports (not completed and not archived) on dashboard
          final filteredReports = reportProvider
              .applyFilters(
                type: _selectedType,
                status: _selectedStatus,
              )
              .where((report) =>
                  report.status != ReportStatus.done && !report.isArchived)
              .toList();

          return Column(
            children: [
              FilterPanelWidget(
                selectedType: _selectedType,
                selectedStatus: _selectedStatus,
                onTypeChanged: (type) {
                  setState(() {
                    _selectedType = type;
                  });
                },
                onStatusChanged: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              ),
              Expanded(
                child: _showMapView
                    ? _buildMapView(filteredReports)
                    : _buildListView(filteredReports, reportProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListView(
      List<ReportModel> reports, ReportProvider reportProvider) {
    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Text(
                translate(context, 'no_reports_found'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReportCardWidget(
              report: report,
              onStatusChanged: (newStatus) {
                Provider.of<ReportProvider>(context, listen: false)
                    .updateReportStatus(report.id, newStatus);
              },
              showCompleteButton: report.type == ReportType.work,
              showControlledButton: report.type == ReportType.hazard,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<ReportModel> reports) {
    // Filter out reports without map coordinates AND archived reports
    final reportsWithLocation = reports
        .where((report) =>
            report.mapX != null && report.mapY != null && !report.isArchived)
        .toList(); // ADDED: !report.isArchived

    if (reportsWithLocation.isEmpty) {
      return Center(
        child: Text(
          translate(context, 'no_reports_with_locations'),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final markers = reportsWithLocation.map((report) {
      return MapMarker(
        x: report.mapX!,
        y: report.mapY!,
        color: _getStatusColor(report.status),
        icon: _getReportIcon(report.type),
        label: report.description,
      );
    }).toList();

    return CustomMapWidget(
      onLocationSelected: (x, y) {
        // Show coordinates when tapping on map
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${translate(context, 'selected')}: ${(x * 100).toStringAsFixed(1)}%, ${(y * 100).toStringAsFixed(1)}%'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      markers: markers,
      onMarkerTap: (marker) {
        // Find the report that matches this marker
        final report = reportsWithLocation.firstWhere(
            (r) => r.mapX == marker.x && r.mapY == marker.y,
            orElse: () => reportsWithLocation.firstWhere((r) =>
                (r.mapX! - marker.x).abs() < 0.01 &&
                (r.mapY! - marker.y).abs() < 0.01));

        _showReportDetails(report);
      },
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.inProgress:
        return Colors.orange;
      case ReportStatus.done:
        return Colors.green;
      case ReportStatus.hazard:
        return Colors.red;
    }
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.work:
        return Icons.build;
      case ReportType.hazard:
        return Icons.warning;
    }
  }

  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'report_details')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${translate(context, 'type')}: ${report.type.toString().split('.').last}'),
              Text(
                  '${translate(context, 'status')}: ${report.status.toString().split('.').last}'),
              Text('${translate(context, 'zone')}: ${report.zone}'),
              const SizedBox(height: 8),
              Text('${translate(context, 'description')}:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(report.description),
              const SizedBox(height: 8),
              if (report.mapX != null && report.mapY != null)
                Text(
                    '${translate(context, 'map_location')}: ${(report.mapX! * 100).toStringAsFixed(1)}%, ${(report.mapY! * 100).toStringAsFixed(1)}%'),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(translate(context, 'close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
