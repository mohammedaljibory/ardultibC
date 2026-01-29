import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class BannerManagementScreen extends StatefulWidget {
  @override
  _BannerManagementScreenState createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final CollectionReference bannersCollection =
      FirebaseFirestore.instance.collection('banners');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة البانرات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                      ),
                    ),
                    SizedBox(height: 2),
                    StreamBuilder<QuerySnapshot>(
                      stream: bannersCollection.snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        final activeCount = snapshot.data?.docs.where((d) =>
                          (d.data() as Map)['isActive'] == true).length ?? 0;
                        return Text(
                          '$count بانر ($activeCount فعال)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ],
                ),
                Spacer(),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _showBannerDialog(),
                    icon: Icon(Icons.add, size: 18),
                    label: Text('إضافة بانر', style: TextStyle(fontSize: 12)),
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

          // Banners List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bannersCollection.orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF667eea),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.docs.length,
                  onReorder: (oldIndex, newIndex) => _reorderBanners(snapshot.data!.docs, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildBannerCard(doc.id, data, key: ValueKey(doc.id));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[300]),
          SizedBox(height: 12),
          Text(
            'لا توجد بانرات',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _showBannerDialog(),
              icon: Icon(Icons.add, size: 18),
              label: Text('إضافة بانر', style: TextStyle(fontSize: 12)),
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
    );
  }

  Widget _buildBannerCard(String docId, Map<String, dynamic> data, {Key? key}) {
    final isActive = data['isActive'] ?? false;
    final titleAr = data['titleAr'] ?? 'بدون عنوان';
    final imageUrl = data['imageUrl'] ?? '';
    final order = data['order'] ?? 0;

    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 12),
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
          // Banner Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[100],
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF667eea),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 28),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 28),
                    ),
            ),
          ),

          // Banner Info
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            isActive ? 'فعال' : 'معطل',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // Order Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$order',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.drag_handle, color: Colors.grey[300], size: 20),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  titleAr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a2e),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'تعديل',
                        Icons.edit_outlined,
                        Color(0xFF667eea),
                        () => _showBannerDialog(docId: docId, data: data),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        isActive ? 'تعطيل' : 'تفعيل',
                        isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        isActive ? Colors.orange : Colors.green,
                        () => _toggleBannerStatus(docId, isActive),
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      height: 32,
                      child: Material(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _deleteBanner(docId, imageUrl),
                          child: Center(
                            child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: TextStyle(fontSize: 10)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  void _showBannerDialog({String? docId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (context) => BannerEditDialog(
        docId: docId,
        data: data,
        onSave: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _toggleBannerStatus(String docId, bool currentStatus) async {
    try {
      await bannersCollection.doc(docId).update({'isActive': !currentStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'تم تعطيل البانر' : 'تم تفعيل البانر',
              style: TextStyle(fontSize: 13),
            ),
            backgroundColor: Color(0xFF667eea),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: TextStyle(fontSize: 13)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _deleteBanner(String docId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('تأكيد الحذف', style: TextStyle(fontSize: 16)),
        content: Text('هل أنت متأكد من حذف هذا البانر؟', style: TextStyle(fontSize: 14)),
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

    if (confirm == true) {
      try {
        if (imageUrl.isNotEmpty && imageUrl.contains('firebasestorage.googleapis.com')) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }
        await bannersCollection.doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف البانر', style: TextStyle(fontSize: 13)),
              backgroundColor: Color(0xFF667eea),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e', style: TextStyle(fontSize: 13)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  Future<void> _reorderBanners(List<DocumentSnapshot> docs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final item = docs.removeAt(oldIndex);
    docs.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < docs.length; i++) {
      batch.update(docs[i].reference, {'order': i});
    }
    await batch.commit();
  }
}

class BannerEditDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;

  const BannerEditDialog({Key? key, this.docId, this.data, required this.onSave}) : super(key: key);

  @override
  _BannerEditDialogState createState() => _BannerEditDialogState();
}

class _BannerEditDialogState extends State<BannerEditDialog> {
  final _titleArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _subtitleArController = TextEditingController();
  final _subtitleEnController = TextEditingController();
  final _actionValueController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isActive = true;
  String _actionType = 'none';
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _titleArController.text = widget.data!['titleAr'] ?? '';
      _titleEnController.text = widget.data!['titleEn'] ?? '';
      _subtitleArController.text = widget.data!['subtitleAr'] ?? '';
      _subtitleEnController.text = widget.data!['subtitleEn'] ?? '';
      _actionValueController.text = widget.data!['actionValue'] ?? '';
      _existingImageUrl = widget.data!['imageUrl'];
      _isActive = widget.data!['isActive'] ?? true;
      _actionType = widget.data!['actionType'] ?? 'none';
    }
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _subtitleArController.dispose();
    _subtitleEnController.dispose();
    _actionValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception("فشل في قراءة الصورة");

    final img.Image resizedImage = img.copyResize(image, width: 1200);
    final Uint8List compressedImage = img.encodeJpg(resizedImage, quality: 80);

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedImage);

    return tempFile;
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _existingImageUrl;

    final compressedImage = await _compressImage(_selectedImage!);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('banners/banner_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = storageRef.putFile(
      compressedImage,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    uploadTask.snapshotEvents.listen((snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    await uploadTask;
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveBanner() async {
    if (_titleArController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال العنوان بالعربية', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_selectedImage == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار صورة للبانر', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage();

      final bannerData = {
        'titleAr': _titleArController.text,
        'titleEn': _titleEnController.text,
        'subtitleAr': _subtitleArController.text,
        'subtitleEn': _subtitleEnController.text,
        'imageUrl': imageUrl,
        'isActive': _isActive,
        'actionType': _actionType,
        'actionValue': _actionValueController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(widget.docId)
            .update(bannerData);
      } else {
        final count = await FirebaseFirestore.instance.collection('banners').count().get();
        bannerData['order'] = count.count ?? 0;
        bannerData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('banners').add(bannerData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ البانر', style: TextStyle(fontSize: 13)),
          backgroundColor: Color(0xFF667eea),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      widget.onSave();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_library_outlined, color: Color(0xFF667eea), size: 18),
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.docId != null ? 'تعديل البانر' : 'إضافة بانر جديد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 24, color: Colors.grey[200]),

              // Image Selection
              Text('صورة البانر *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
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
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey[400]),
                                SizedBox(height: 8),
                                Text('اضغط لاختيار صورة', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ],
                            ),
                ),
              ),
              SizedBox(height: 16),

              // Title Arabic
              _buildTextField(_titleArController, 'العنوان (عربي) *'),
              SizedBox(height: 12),

              // Title English
              _buildTextField(_titleEnController, 'العنوان (إنجليزي)'),
              SizedBox(height: 12),

              // Subtitle Arabic
              _buildTextField(_subtitleArController, 'النص الفرعي (عربي)'),
              SizedBox(height: 12),

              // Subtitle English
              _buildTextField(_subtitleEnController, 'النص الفرعي (إنجليزي)'),
              SizedBox(height: 12),

              // Action Type
              Text('الإجراء عند النقر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _actionType,
                  isExpanded: true,
                  underline: SizedBox(),
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                  items: [
                    DropdownMenuItem(value: 'none', child: Text('بدون إجراء')),
                    DropdownMenuItem(value: 'url', child: Text('فتح رابط')),
                    DropdownMenuItem(value: 'product', child: Text('فتح منتج')),
                    DropdownMenuItem(value: 'category', child: Text('فتح تصنيف')),
                  ],
                  onChanged: (value) => setState(() => _actionType = value!),
                ),
              ),
              SizedBox(height: 12),

              // Action Value
              if (_actionType != 'none')
                _buildTextField(
                  _actionValueController,
                  _actionType == 'url' ? 'الرابط' : 'معرف ${_actionType == 'product' ? 'المنتج' : 'التصنيف'}',
                ),
              if (_actionType != 'none') SizedBox(height: 12),

              // Active Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('البانر فعال', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeColor: Color(0xFF667eea),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            color: Color(0xFF667eea),
                            backgroundColor: Color(0xFF667eea).withOpacity(0.2),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'جاري الرفع... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: _saveBanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('حفظ البانر', style: TextStyle(fontSize: 13)),
                      ),
              ),
            ],
          ),
        ),
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
}
