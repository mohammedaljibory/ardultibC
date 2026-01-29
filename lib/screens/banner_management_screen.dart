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
      appBar: AppBar(
        title: Text('إدارة البانرات', style: TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: Color(0xFFE91E63),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => _showBannerDialog(),
            tooltip: 'إضافة بانر جديد',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bannersCollection.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('لا توجد بانرات', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showBannerDialog(),
                    icon: Icon(Icons.add, size: 18),
                    label: Text('إضافة بانر', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: EdgeInsets.all(16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerDialog(),
        backgroundColor: Color(0xFFE91E63),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBannerCard(String docId, Map<String, dynamic> data, {Key? key}) {
    final isActive = data['isActive'] ?? false;
    final titleAr = data['titleAr'] ?? 'بدون عنوان';
    final titleEn = data['titleEn'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final order = data['order'] ?? 0;

    return Card(
      key: key,
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Banner Image
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                  );
                },
              ),
            )
          else
            Container(
              height: 120,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey, size: 40),
            ),

          // Banner Info
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'فعال' : 'معطل',
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ترتيب: $order',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.drag_handle, color: Colors.grey[400]),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  titleAr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (titleEn.isNotEmpty)
                  Text(
                    titleEn,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showBannerDialog(docId: docId, data: data),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('تعديل', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleBannerStatus(docId, isActive),
                        icon: Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 16),
                        label: Text(isActive ? 'تعطيل' : 'تفعيل', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive ? Colors.orange : Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteBanner(docId, imageUrl),
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'حذف',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'تم تعطيل البانر' : 'تم تفعيل البانر'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteBanner(String docId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا البانر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete image from storage
        if (imageUrl.isNotEmpty && imageUrl.contains('firebasestorage.googleapis.com')) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }
        // Delete document
        await bannersCollection.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف البانر'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reorderBanners(List<DocumentSnapshot> docs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final item = docs.removeAt(oldIndex);
    docs.insert(newIndex, item);

    // Update order for all items
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
        SnackBar(content: Text('خطأ في اختيار الصورة: $e'), backgroundColor: Colors.red),
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
        SnackBar(content: Text('الرجاء إدخال العنوان بالعربية'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedImage == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء اختيار صورة للبانر'), backgroundColor: Colors.orange),
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
        // Update existing
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(widget.docId)
            .update(bannerData);
      } else {
        // Create new
        final count = await FirebaseFirestore.instance.collection('banners').count().get();
        bannerData['order'] = count.count ?? 0;
        bannerData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('banners').add(bannerData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ البانر بنجاح'), backgroundColor: Colors.green),
      );
      widget.onSave();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.image, color: Color(0xFFE91E63)),
                  SizedBox(width: 8),
                  Text(
                    widget.docId != null ? 'تعديل البانر' : 'إضافة بانر جديد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 12),

              // Image Selection
              Text('صورة البانر *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                                SizedBox(height: 8),
                                Text('اضغط لاختيار صورة', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                ),
              ),
              SizedBox(height: 16),

              // Title Arabic
              TextField(
                controller: _titleArController,
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'العنوان (عربي) *',
                  labelStyle: TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 12),

              // Title English
              TextField(
                controller: _titleEnController,
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'العنوان (إنجليزي)',
                  labelStyle: TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 12),

              // Subtitle Arabic
              TextField(
                controller: _subtitleArController,
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'النص الفرعي (عربي)',
                  labelStyle: TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 12),

              // Subtitle English
              TextField(
                controller: _subtitleEnController,
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'النص الفرعي (إنجليزي)',
                  labelStyle: TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 12),

              // Action Type
              Text('الإجراء عند النقر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _actionType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(value: 'none', child: Text('بدون إجراء', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'url', child: Text('فتح رابط', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'product', child: Text('فتح منتج', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'category', child: Text('فتح تصنيف', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (value) => setState(() => _actionType = value!),
              ),
              SizedBox(height: 12),

              // Action Value
              if (_actionType != 'none')
                TextField(
                  controller: _actionValueController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _actionType == 'url' ? 'الرابط' : 'معرف ${_actionType == 'product' ? 'المنتج' : 'التصنيف'}',
                    labelStyle: TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              SizedBox(height: 12),

              // Active Status
              SwitchListTile(
                title: Text('البانر فعال', style: TextStyle(fontSize: 14)),
                subtitle: Text('سيظهر في الموقع', style: TextStyle(fontSize: 12)),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: Color(0xFFE91E63),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Column(
                        children: [
                          LinearProgressIndicator(value: _uploadProgress, color: Color(0xFFE91E63)),
                          SizedBox(height: 8),
                          Text('جاري الرفع... ${(_uploadProgress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12)),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: _saveBanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('حفظ البانر', style: TextStyle(fontSize: 14)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
