import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'providers/report_provider.dart';
import 'providers/site_provider.dart';
import 'data/models/report_model.dart';
import 'widgets/custom_map_widget.dart';

class ReportCreationPage extends StatefulWidget {
  const ReportCreationPage({Key? key}) : super(key: key);

  @override
  State<ReportCreationPage> createState() => _ReportCreationPageState();
}

class _ReportCreationPageState extends State<ReportCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  ReportType _selectedType = ReportType.work;
  String _selectedZone = '';
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  double? _mapX;
  double? _mapY;
  List<String> _uploadErrors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
    });
  }

  void _loadZones() {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    if (siteProvider.currentSite != null &&
        siteProvider.currentSite!.zones.isNotEmpty) {
      setState(() {
        _selectedZone = siteProvider.currentSite!.zones.first.id;
      });
    }
  }

  // Function to compress image further
  Future<Uint8List> _compressImage(XFile imageFile, {int maxSizeKB = 200}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // If image is already small enough, return as is
      if (bytes.lengthInBytes <= maxSizeKB * 1024) {
        return bytes;
      }
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;
      
      // Calculate scaling factor to achieve target size
      int quality = 70;
      Uint8List compressedBytes = bytes;
      
      // Gradually reduce quality until we reach target size
      while (compressedBytes.lengthInBytes > maxSizeKB * 1024 && quality > 10) {
        quality -= 10;
        compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      }
      
      // If still too large, resize the image
      if (compressedBytes.lengthInBytes > maxSizeKB * 1024) {
        double scaleFactor = 0.9;
        img.Image resizedImage = image;
        
        while (compressedBytes.lengthInBytes > maxSizeKB * 1024 && scaleFactor > 0.3) {
          int newWidth = (resizedImage.width * scaleFactor).round();
          int newHeight = (resizedImage.height * scaleFactor).round();
          
          resizedImage = img.copyResize(resizedImage, width: newWidth, height: newHeight);
          compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
          
          scaleFactor -= 0.1;
        }
      }
      
      return compressedBytes;
    } catch (e) {
      print('Image compression error: $e');
      // If compression fails, return original bytes
      return await imageFile.readAsBytes();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      print('Camera error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      print('Gallery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _onMapLocationSelected(double x, double y) {
    setState(() {
      _mapX = x;
      _mapY = y;
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //         'Location selected: ${(x * 100).toStringAsFixed(1)}%, ${(y * 100).toStringAsFixed(1)}%'),
    //   ),
    // );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedZone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a zone')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadErrors.clear();
    });

    try {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);

      if (siteProvider.currentSite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No site selected')),
        );
        return;
      }

      // Process images with compression
      List<String> photoUrls = [];
      int imageIndex = 0;
      
      for (XFile image in _selectedImages) {
        try {
          imageIndex++;
          
          // Show progress for current image
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Processing image $imageIndex/${_selectedImages.length}'),
              duration: const Duration(seconds: 1),
            ),
          );
          
          if (kIsWeb) {
            // For web, compress and convert to base64
            final compressedBytes = await _compressImage(image, maxSizeKB: 200);
            final base64String = base64Encode(compressedBytes);
            photoUrls.add('data:image/jpeg;base64,$base64String');
          } else {
            // For mobile, save compressed image to temporary file
            final compressedBytes = await _compressImage(image, maxSizeKB: 200);
            
            // Create a temporary file
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$imageIndex.jpg');
            await tempFile.writeAsBytes(compressedBytes);
            
            photoUrls.add(tempFile.path);
          }
        } catch (e) {
          print('Error processing image $imageIndex: $e');
          _uploadErrors.add('Image $imageIndex: $e');
          // Continue with other images even if one fails
        }
      }

      // Check if we have any successfully processed images
      if (photoUrls.isEmpty && _selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process all images. Report not created.')),
        );
        return;
      }

      await reportProvider.createReport(
        siteId: siteProvider.currentSite!.id,
        zone: _selectedZone,
        type: _selectedType,
        description: _descriptionController.text,
        photoUrls: photoUrls,
        latitude: null,
        longitude: null,
        mapX: _mapX,
        mapY: _mapY,
      );

      // Show success message with any warnings
      if (_uploadErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report created successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report created with ${_uploadErrors.length} image errors'),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Image Upload Errors'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _uploadErrors.map((error) => Text('• $error')).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }

      // Reset form
      _descriptionController.clear();
      setState(() {
        _selectedImages.clear();
        _mapX = null;
        _mapY = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating report: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Report'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
      ),
      body: Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          if (siteProvider.currentSite == null) {
            return const Center(
              child: Text(
                'No site selected, please configure a site to create reports',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Report Type Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<ReportType>(
                                  title: const Text('Work'),
                                  value: ReportType.work,
                                  groupValue: _selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<ReportType>(
                                  title: const Text('Hazard'),
                                  value: ReportType.hazard,
                                  groupValue: _selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Zone Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Task zone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedZone.isEmpty ? null : _selectedZone,
                            decoration: const InputDecoration(
                              labelText: 'Select Zone',
                              border: OutlineInputBorder(),
                            ),
                            items: siteProvider.currentSite!.zones.map((zone) {
                              return DropdownMenuItem(
                                value: zone.id,
                                child: Text(zone.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedZone = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a zone';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Describe the work or hazard',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload photos',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey[300],
                                          ),
                                          child: FutureBuilder<Uint8List>(
                                            future: _selectedImages[index].readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                  ),
                                                );
                                              } else {
                                                return const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom Map Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Location on Map',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap on the map to select the work location',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomMapWidget(
                            onLocationSelected: _onMapLocationSelected,
                            markers: _mapX != null && _mapY != null
                                ? [
                                    MapMarker(
                                      x: _mapX!,
                                      y: _mapY!,
                                      color: _selectedType == ReportType.work
                                          ? Colors.blue
                                          : Colors.red,
                                      icon: _selectedType == ReportType.work
                                          ? Icons.build
                                          : Icons.warning,
                                      label: 'Selected Location',
                                    ),
                                  ]
                                : [],
                          ),
                          if (_mapX != null && _mapY != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Location selected: ${(_mapX! * 100).toStringAsFixed(1)}%, ${(_mapY! * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Creating Report...'),
                            ],
                          )
                        : const Text('Create Report'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}