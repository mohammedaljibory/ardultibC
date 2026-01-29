import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class ImageControlScreen extends StatefulWidget {
  @override
  _ImageControlScreenState createState() => _ImageControlScreenState();
}

class _ImageControlScreenState extends State<ImageControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollectionReference postsCollection = FirebaseFirestore.instance.collection('posts');
  final CollectionReference galleryCollection = FirebaseFirestore.instance.collection('gallery');
  final TextEditingController _titleArController = TextEditingController();
  final TextEditingController _titleEnController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleArController.dispose();
    _titleEnController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showError('خطأ في اختيار الصورة: $e');
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception("فشل في قراءة الصورة");

    final img.Image resizedImage = img.copyResize(image, width: 800);
    final Uint8List compressedImage = img.encodeJpg(resizedImage, quality: 70);

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedImage);

    return tempFile;
  }

  Future<void> _uploadImage(bool isPost) async {
    if (_selectedImage == null || _titleArController.text.isEmpty || _titleEnController.text.isEmpty) {
      _showError('الرجاء اختيار صورة وإدخال العنوان بالعربية والإنجليزية');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final compressedImage = await _compressImage(_selectedImage!);
      final folder = isPost ? 'posts' : 'gallery';
      final storageRef = FirebaseStorage.instance.ref().child('$folder/${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask uploadTask = storageRef.putFile(
        compressedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
        });
      });

      await uploadTask;
      final url = await storageRef.getDownloadURL();

      final collection = isPost ? postsCollection : galleryCollection;
      await collection.add({
        'title_ar': _titleArController.text,
        'title_en': _titleEnController.text,
        'url': url,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploading = false;
        _selectedImage = null;
        _titleArController.clear();
        _titleEnController.clear();
      });

      _showSuccess(isPost ? 'تم رفع المنشور' : 'تم رفع الصورة للمعرض');
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('خطأ في رفع الصورة: $e');
    }
  }

  Future<void> _deleteImage(String url, String docId, CollectionReference collection) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('تأكيد الحذف', style: TextStyle(fontSize: 16)),
        content: Text('هل أنت متأكد من حذف هذه الصورة؟', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (url.isNotEmpty && url.startsWith('https://firebasestorage.googleapis.com')) {
        final storageRef = FirebaseStorage.instance.refFromURL(url);
        await storageRef.delete();
      }
      await collection.doc(docId).delete();
      _showSuccess('تم حذف الصورة');
    } catch (e) {
      _showError('خطأ في حذف الصورة: $e');
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(fontSize: 13)),
          backgroundColor: Color(0xFF667eea),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة المعرض',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'المنشورات وصور المعرض',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),

                // Tab Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Color(0xFF667eea),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(text: 'المنشورات'),
                      Tab(text: 'المعرض'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(true),
                _buildTabContent(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isPost) {
    final collection = isPost ? postsCollection : galleryCollection;
    final title = isPost ? 'منشور' : 'صورة للمعرض';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPost ? Icons.post_add : Icons.collections,
                        color: Color(0xFF667eea),
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'إضافة $title جديد',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                _buildTextField(_titleArController, 'العنوان (عربي)'),
                SizedBox(height: 12),
                _buildTextField(_titleEnController, 'العنوان (إنجليزي)'),
                SizedBox(height: 12),

                // Image Preview
                GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 28, color: Colors.grey[400]),
                              SizedBox(height: 6),
                              Text('اضغط لاختيار صورة', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 16),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                strokeWidth: 2,
                                color: Color(0xFF667eea),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'جاري الرفع ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 12, color: Color(0xFF667eea)),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _uploadImage(isPost),
                          icon: Icon(Icons.upload, size: 18),
                          label: Text('رفع $title', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Existing Images
          Text(
            isPost ? 'المنشورات الحالية' : 'صور المعرض',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1a1a2e)),
          ),
          SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: collection.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF667eea),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey[300]),
                        SizedBox(height: 12),
                        Text(
                          isPost ? 'لا توجد منشورات' : 'لا توجد صور',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildImageCard(doc.id, data, collection);
                },
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildImageCard(String docId, Map<String, dynamic> data, CollectionReference collection) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                data['url'] ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF667eea),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: Icon(Icons.broken_image, color: Colors.grey[400], size: 24),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title_ar'] ?? 'بدون عنوان',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    data['title_en'] ?? 'No title',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Material(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _deleteImage(data['url'], docId, collection),
                          child: Center(
                            child: Icon(Icons.delete_outline, size: 14, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
