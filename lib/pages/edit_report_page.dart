import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/providers/report_provider.dart';
import 'package:livework_view/providers/site_provider.dart';
import 'package:livework_view/data/models/report_model.dart';
import 'package:livework_view/helpers/localization_helper.dart';

class EditReportPage extends StatefulWidget {
  final ReportModel report;

  const EditReportPage({Key? key, required this.report}) : super(key: key);

  @override
  _EditReportPageState createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  ReportType _selectedType = ReportType.work;
  String _selectedZone = '';
  List<XFile> _selectedImages = [];
  List<String> _existingPhotoUrls = [];
  bool _isSubmitting = false;
  double? _mapX;
  double? _mapY;

  @override
  void initState() {
    super.initState();
    // INITIALIZE FORM WITH EXISTING REPORT DATA
    _descriptionController.text = widget.report.description;
    _selectedType = widget.report.type;
    _selectedZone = widget.report.zone;
    _existingPhotoUrls = List.from(widget.report.photoUrls);
    _mapX = widget.report.mapX;
    _mapY = widget.report.mapY;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);

      // Validate we have a current site
      if (siteProvider.currentSite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context, 'no_site_selected'))),
        );
        return;
      }

      // Process new images (you can reuse your existing compression logic)
      List<String> updatedPhotoUrls = List.from(_existingPhotoUrls);
      // ... add logic to process new images ...

      await reportProvider.editReport(
        reportId: widget.report.id,
        description: _descriptionController.text,
        zone: _selectedZone,
        type: _selectedType,
        photoUrls: updatedPhotoUrls,
        mapX: _mapX,
        mapY: _mapY,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context, 'report_updated'))),
      );

      Navigator.of(context).pop(); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      // TEMPORARY: Detailed error logging
      print('❌ Report edit error: $e');
      print('📋 Stack trace: $stackTrace');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );
    } finally {
      // FIX 5: Only update state if widget is still mounted
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context, 'edit_report')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submitEdit,
            tooltip: translate(context, 'save_changes'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ADD YOUR FORM FIELDS HERE (similar to report_creation_page.dart)
              // Description, Zone dropdown, Type radio buttons, etc.
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: translate(context, 'description'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return translate(context, 'please_enter_description');
                  }
                  return null;
                },
              ),
              // ... add other form fields ...

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEdit,
                child: _isSubmitting
                    ? CircularProgressIndicator()
                    : Text(translate(context, 'save_changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
