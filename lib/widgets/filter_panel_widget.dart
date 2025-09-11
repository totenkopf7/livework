import 'package:flutter/material.dart';
import '../data/models/report_model.dart';

class FilterPanelWidget extends StatelessWidget {
  final ReportType? selectedType;
  final ReportStatus? selectedStatus;
  final Function(ReportType?) onTypeChanged;
  final Function(ReportStatus?) onStatusChanged;

  const FilterPanelWidget({
    Key? key,
    this.selectedType,
    this.selectedStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ReportType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<ReportType>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...ReportType.values.map((type) {
                      return DropdownMenuItem<ReportType>(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<ReportStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<ReportStatus>(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...ReportStatus.values.map((status) {
                      return DropdownMenuItem<ReportStatus>(
                        value: status,
                        child: Text(_getStatusText(status)),
                      );
                    }),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
} 