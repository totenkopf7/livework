import 'package:flutter/material.dart';
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
        title: const Text('LiveWork View Dashboard'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
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
                    : _buildListView(filteredReports),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListView(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          final siteProvider = Provider.of<SiteProvider>(context, listen: false);
          final reportProvider = Provider.of<ReportProvider>(context, listen: false);
          if (siteProvider.currentSite != null) {
            await reportProvider.refreshReports(siteId: siteProvider.currentSite!.id);
          }
        },
        child: const Center(
          child: Text(
            'No reports found\nPull down to refresh',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        final reportProvider = Provider.of<ReportProvider>(context, listen: false);
        if (siteProvider.currentSite != null) {
          await reportProvider.refreshReports(siteId: siteProvider.currentSite!.id);
        }
      },
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
    final markers = reports.map((report) {
      return MapMarker(
        x: report.mapX ?? 0.1,
        y: report.mapY ?? 0.1,
        color: _getStatusColor(report.status),
        icon: _getReportIcon(report.type),
        label: report.description,
      );
    }).toList();

    return CustomMapWidget(
      onLocationSelected: (x, y) {
        // Optionally show a message or do nothing
      },
      markers: markers,
      mapImagePath:
          'assets/images/company_map.png', // <-- Make sure this is set!
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
        title: Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${report.type.name}'),
            Text('Status: ${report.status.name}'),
            Text('Zone: ${report.zone}'),
            Text('Description: ${report.description}'),
            if (report.mapX != null && report.mapY != null)
              Text(
                  'Map Location: ${(report.mapX! * 100).toStringAsFixed(1)}%, ${(report.mapY! * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
