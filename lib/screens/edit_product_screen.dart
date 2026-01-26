// screens/edit_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    Key? key,
    required this.productId,
    required this.productData,
  }) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _newImage;
  List<File> _newImages = [];
  List<String> _existingImages = [];
  bool _isUploading = false;
  bool _isUploadingMultiple = false;
  double _uploadProgress = 0.0;
  bool _isHidden = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.productData['name'] ?? '';
    _descriptionController.text = widget.productData['description'] ?? '';
    _isHidden = widget.productData['hidden'] ?? false;
    _selectedCategory = widget.productData['category'];

    // Load existing images
    if (widget.productData['images'] != null && widget.productData['images'] is List) {
      _existingImages = List<String>.from(widget.productData['images']);
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .get();

      List<String> loadedCategories = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String categoryName = data['nameAr'] ?? data['nameEn'] ?? '';
        if (categoryName.isNotEmpty) {
          loadedCategories.add(categoryName);
        }
      }

      setState(() {
        _categories = loadedCategories;
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _categories.add(_selectedCategory!);
        }
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages = pickedFiles.map((xFile) => File(xFile.path)).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم اختيار ${pickedFiles.length} صورة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصور: $e')),
      );
    }
  }

  Future<File> _processImageToSquare(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception('فشل في قراءة الصورة');

    final int size = image.width < image.height ? image.width : image.height;
    final int offsetX = (image.width - size) ~/ 2;
    final int offsetY = (image.height - size) ~/ 2;

    img.Image squareImage = img.copyCrop(image,
        x: offsetX,
        y: offsetY,
        width: size,
        height: size
    );

    squareImage = img.copyResize(squareImage, width: 800, height: 800);
    final Uint8List compressedImage = img.encodeJpg(squareImage, quality: 85);

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/square_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedImage);

    return tempFile;
  }

  Future<String?> _uploadImage() async {
    if (_newImage == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final squareImage = await _processImageToSquare(_newImage!);
      final fileName = 'product_${widget.productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products/$fileName');

      final uploadTask = storageRef.putFile(
        squareImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;
      final url = await storageRef.getDownloadURL();

      // Delete old thumbnail if exists
      final oldThumbnail = widget.productData['thumbnail'];
      if (oldThumbnail != null &&
          oldThumbnail.toString().isNotEmpty &&
          oldThumbnail.toString().contains('firebasestorage.googleapis.com')) {
        try {
          await FirebaseStorage.instance.refFromURL(oldThumbnail).delete();
        } catch (e) {
          print('Error deleting old thumbnail: $e');
        }
      }

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      return url;
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصورة: $e'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<List<String>> _uploadMultipleImages() async {
    if (_newImages.isEmpty) return [];

    List<String> uploadedUrls = [];

    setState(() {
      _isUploadingMultiple = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      int totalImages = _newImages.length;
      int uploadedCount = 0;

      for (File imageFile in _newImages) {
        try {
          final squareImage = await _processImageToSquare(imageFile);
          final fileName = 'product_${widget.productId}_${DateTime.now().millisecondsSinceEpoch}_$uploadedCount.jpg';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('products/$fileName');

          final uploadTask = storageRef.putFile(
            squareImage,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          await uploadTask;
          final url = await storageRef.getDownloadURL();
          uploadedUrls.add(url);

          uploadedCount++;

          setState(() {
            _uploadProgress = uploadedCount / totalImages;
          });

          print('Uploaded image $uploadedCount of $totalImages');

        } catch (e) {
          print('Error uploading image $uploadedCount: $e');
        }
      }

      setState(() {
        _isUploadingMultiple = false;
        _uploadProgress = 0.0;
      });

      return uploadedUrls;

    } catch (e) {
      setState(() {
        _isUploadingMultiple = false;
        _uploadProgress = 0.0;
      });
      throw e;
    }
  }

  Future<void> _deleteImageFromList(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete from storage
      try {
        final imageUrl = _existingImages[index];
        if (imageUrl.contains('firebasestorage.googleapis.com')) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }
      } catch (e) {
        print('Error deleting image from storage: $e');
      }

      setState(() {
        _existingImages.removeAt(index);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المنتج')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري حفظ التغييرات...'),
          ],
        ),
      ),
    );

    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'hidden': _isHidden,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (_descriptionController.text.trim().isNotEmpty) {
        updateData['description'] = _descriptionController.text.trim();
      }

      if (_selectedCategory != null) {
        updateData['category'] = _selectedCategory;
      }

      // Handle single image upload (for thumbnail)
      if (_newImage != null) {
        final imageUrl = await _uploadImage();
        if (imageUrl != null) {
          updateData['thumbnail'] = imageUrl;
          if (!_existingImages.contains(imageUrl)) {
            _existingImages.add(imageUrl);
          }
        }
      }

      // Handle multiple images upload
      if (_newImages.isNotEmpty) {
        final uploadedUrls = await _uploadMultipleImages();
        _existingImages.addAll(uploadedUrls);

        // Set first image as thumbnail if no thumbnail exists
        if ((widget.productData['thumbnail'] == null ||
            widget.productData['thumbnail'].toString().isEmpty) &&
            uploadedUrls.isNotEmpty) {
          updateData['thumbnail'] = uploadedUrls.first;
        }
      }

      // Update images array
      updateData['images'] = _existingImages;

      // Update nameParts for search
      final nameParts = _nameController.text
          .trim()
          .toLowerCase()
          .split(' ')
          .where((part) => part.isNotEmpty)
          .toList();
      updateData['nameParts'] = nameParts;
      updateData['namePartsLower'] = nameParts;

      await FirebaseFirestore.instance
          .collection('items1')
          .doc(widget.productId)
          .update(updateData);

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Return to list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ التغييرات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A11CB),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اسم المنتج',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'أدخل اسم المنتج',
                        border: OutlineInputBorder(),
                      ),
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
                      'وصف المنتج',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'أدخل وصف المنتج (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التصنيف',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        hint: const Text('اختر التصنيف'),
                        underline: const SizedBox(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('بدون تصنيف'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Images Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'صور المنتج',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Main thumbnail display
                    Center(
                      child: _buildMainImageDisplay(),
                    ),
                    const SizedBox(height: 16),

                    // Buttons for image selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading || _isUploadingMultiple ? null : _pickImage,
                          icon: const Icon(Icons.photo),
                          label: const Text('صورة واحدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading || _isUploadingMultiple ? null : _pickMultipleImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('عدة صور'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    // Show selected new images
                    if (_newImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('الصور المختارة للرفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _newImages[index],
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _newImages.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Show existing images
                    if (_existingImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('الصور الحالية:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _existingImages[index],
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () => _deleteImageFromList(index),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Upload progress
                    if (_isUploading || _isUploadingMultiple)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            const SizedBox(height: 8),
                            Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visibility Toggle
            Card(
              child: SwitchListTile(
                title: const Text(
                  'إخفاء المنتج',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('عند التفعيل، لن يظهر المنتج في الموقع'),
                value: _isHidden,
                onChanged: (value) {
                  setState(() {
                    _isHidden = value;
                  });
                },
                activeColor: const Color(0xFF6A11CB),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.save),
                label: const Text(
                  'حفظ التغييرات',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageDisplay() {
    final currentImageUrl = widget.productData['thumbnail'];

    if (_newImage != null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _newImage!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (currentImageUrl != null && currentImageUrl.toString().isNotEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            currentImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error_outline, size: 50, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}