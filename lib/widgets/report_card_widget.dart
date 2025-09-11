import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/models/report_model.dart';

class ReportCardWidget extends StatelessWidget {
  final ReportModel report;
  final Function(ReportStatus) onStatusChanged;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const ReportCardWidget({
    Key? key,
    required this.report,
    required this.onStatusChanged,
    this.onDelete,
    this.showDeleteButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReportIcon(report.type),
                  color: _getStatusColor(report.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.zone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusText(report.status),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(report.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    report.type.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: report.type == ReportType.work
                      ? Colors.blue.shade100
                      : Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
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
                if (report.reporterName != null) ...[
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.reporterName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            if (report.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.photoUrls.length,
                  itemBuilder: (context, index) {
                    final imagePath = report.photoUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, imagePath),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 80,
                            child: kIsWeb
                                ? _buildWebImage(imagePath)
                                : _buildMobileImage(imagePath),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (report.status == ReportStatus.inProgress) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => onStatusChanged(ReportStatus.done),
                icon: const Icon(Icons.check),
                label: const Text('Task completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            if (showDeleteButton && onDelete != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReportStatus>(
                    value: report.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ReportStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        onStatusChanged(newStatus);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showLocationInfo(context),
                  icon: const Icon(Icons.location_on),
                  tooltip: 'View Location',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.work:
        return Icons.build;
      case ReportType.hazard:
        return Icons.warning;
    }
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

  void _showLocationInfo(BuildContext context) {
    if (report.latitude != null && report.longitude != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Information'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location data available for this report'),
        ),
      );
    }
  }

  Widget _buildWebImage(String imagePath) {
    // For web, handle base64 images
    if (imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imagePath.split(',')[1]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey[300],
            child: const Icon(
              Icons.image,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      // Fallback for non-base64 paths
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Image',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMobileImage(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: const Icon(
            Icons.image,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Image'),
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 400,
                ),
                child: kIsWeb
                    ? _buildWebImage(imagePath)
                    : _buildMobileImage(imagePath),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
