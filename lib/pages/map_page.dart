import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../providers/site_provider.dart';
import '../data/models/report_model.dart';
import '../widgets/custom_map_widget.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
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
        title: const Text('Work Reports Map'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                // Map View
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildMapView(reportProvider.reports),
                  ),
                ),
                const SizedBox(height: 16),
                // Reports List
                _buildReportsList(reportProvider.reports),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<ReportModel> reports) {
    // Convert reports to map markers
    final markers = reports.map((report) {
      return MapMarker(
        x: report.mapX ?? 0.1, // Default position if no map coordinates
        y: report.mapY ?? 0.1,
        color: _getStatusColor(report.status),
        icon: _getReportIcon(report.type),
        label: report.description,
        // Add a reference to the report id for lookup
        // We'll use label as a unique key for now, but id is better if available
      );
    }).toList();

    return CustomMapWidget(
      onLocationSelected: (x, y) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tap on a marker to view report details'),
          ),
        );
      },
      markers: markers,
      mapImagePath: 'assets/images/company_map.png',
      onMarkerTap: (marker) {
        // Find the report by matching label (description) and coordinates
        final report = reports.firstWhere(
          (r) => r.description == marker.label &&
                  ((r.mapX ?? 0.1) - marker.x).abs() < 0.0001 &&
                  ((r.mapY ?? 0.1) - marker.y).abs() < 0.0001,
          orElse: () => reports.first,
        );
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(report.zone),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.photoUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.network(
                      report.photoUrls.first,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                Text(
                  report.description,
                  style: const TextStyle(fontSize: 16),
                ),
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
      },
    );
  }

  Widget _buildReportsList(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text(
          'No reports found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Work Reports (reports.length})',
              style:  TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(report.status),
          child: Icon(
            _getReportIcon(report.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          report.zone,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(report.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(report.status),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(report.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showReportDetails(report),
      ),
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

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.done:
        return 'Completed';
      case ReportStatus.hazard:
        return 'Hazard';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
            if (report.mapX != null && report.mapY != null) ...[
              const SizedBox(height: 8),
              Text(
                  'Map Location: ${(report.mapX! * 100).toStringAsFixed(1)}%, ${(report.mapY! * 100).toStringAsFixed(1)}%'),
            ],
            if (report.reporterName != null) ...[
              const SizedBox(height: 8),
              Text('Reporter: ${report.reporterName}'),
            ],
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
