import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:provider/provider.dart';
import 'providers/report_provider.dart';
import 'providers/site_provider.dart';
import 'data/models/report_model.dart';
import 'widgets/report_card_widget.dart';
import 'widgets/filter_panel_widget.dart';
import 'widgets/custom_map_widget.dart';

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
      appBar: AppBar(
        title: const Text('LiveWork View Dashboard'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshReports();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reports refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh Reports',
          ),
          IconButton(
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMapView = !_showMapView;
              });
            },
            tooltip: _showMapView ? 'Show List View' : 'Show Map View',
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshReports,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Only show active reports (not completed) on dashboard
          final filteredReports = reportProvider.applyFilters(
            type: _selectedType,
            status: _selectedStatus,
          ).where((report) => report.status != ReportStatus.done).toList();

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

  Widget _buildListView(List<ReportModel> reports, ReportProvider reportProvider) {
    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: const Center(
              child: Text(
                'No reports found\nPull down to refresh',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<ReportModel> reports) {
    // Filter out reports without map coordinates
    final reportsWithLocation = reports.where((report) => 
        report.mapX != null && report.mapY != null).toList();

    if (reportsWithLocation.isEmpty) {
      return const Center(
        child: Text(
          'No reports with map locations\nSwitch to list view or create new reports with locations',
          style: TextStyle(fontSize: 16, color: Colors.grey),
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
            content: Text('Selected: ${(x * 100).toStringAsFixed(1)}%, ${(y * 100).toStringAsFixed(1)}%'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      markers: markers,
      onMarkerTap: (marker) {
        // Find the report that matches this marker
        final report = reportsWithLocation.firstWhere(
          (r) => r.mapX == marker.x && r.mapY == marker.y,
          orElse: () => reportsWithLocation.firstWhere(
            (r) => (r.mapX! - marker.x).abs() < 0.01 && (r.mapY! - marker.y).abs() < 0.01
          )
        );
        
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
        title: const Text('Report Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${report.type.toString().split('.').last}'),
              Text('Status: ${report.status.toString().split('.').last}'),
              Text('Zone: ${report.zone}'),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(report.description),
              const SizedBox(height: 8),
              if (report.mapX != null && report.mapY != null)
                Text('Map Location: ${(report.mapX! * 100).toStringAsFixed(1)}%, ${(report.mapY! * 100).toStringAsFixed(1)}%'),
                // Removed createdAt as it does not exist on ReportModel
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}