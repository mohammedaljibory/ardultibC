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

class _ImageControlScreenState extends State<ImageControlScreen> {
  final CollectionReference postsCollection = FirebaseFirestore.instance.collection('posts');
  final CollectionReference galleryCollection = FirebaseFirestore.instance.collection('gallery');
  final TextEditingController _postTitleArController = TextEditingController();
  final TextEditingController _postTitleEnController = TextEditingController();
  final TextEditingController _galleryTitleArController = TextEditingController();
  final TextEditingController _galleryTitleEnController = TextEditingController();
  File? _postImage;
  File? _galleryImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPost = false;
  bool _isUploadingGallery = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _postTitleArController.dispose();
    _postTitleEnController.dispose();
    _galleryTitleArController.dispose();
    _galleryTitleEnController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isPost) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (isPost) {
            _postImage = File(pickedFile.path);
          } else {
            _galleryImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في اختيار الصورة: $e"), backgroundColor: Colors.red),
      );
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

  Future<void> _uploadPostImage() async {
    if (_postImage == null || _postTitleArController.text.isEmpty || _postTitleEnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء اختيار صورة وإدخال العنوان بالعربية والإنجليزية"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingPost = true;
      _uploadProgress = 0.0;
    });

    try {
      final compressedImage = await _compressImage(_postImage!);

      final storageRef = FirebaseStorage.instance.ref().child('posts/post_${DateTime.now().millisecondsSinceEpoch}.jpg');
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

      await postsCollection.add({
        'title_ar': _postTitleArController.text,
        'title_en': _postTitleEnController.text,
        'url': url,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploadingPost = false;
        _postImage = null;
        _postTitleArController.clear();
        _postTitleEnController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم رفع الصورة بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploadingPost = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في رفع الصورة: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadGalleryImage() async {
    if (_galleryImage == null || _galleryTitleArController.text.isEmpty || _galleryTitleEnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء اختيار صورة وإدخال العنوان بالعربية والإنجليزية"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingGallery = true;
      _uploadProgress = 0.0;
    });

    try {
      final compressedImage = await _compressImage(_galleryImage!);

      final storageRef = FirebaseStorage.instance.ref().child('gallery/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
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

      await galleryCollection.add({
        'title_ar': _galleryTitleArController.text,
        'title_en': _galleryTitleEnController.text,
        'url': url,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploadingGallery = false;
        _galleryImage = null;
        _galleryTitleArController.clear();
        _galleryTitleEnController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم رفع الصورة إلى المعرض بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploadingGallery = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في رفع الصورة: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteImage(String url, String docId, CollectionReference collection) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف هذه الصورة؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم حذف الصورة بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في حذف الصورة: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة الصور", style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0097A7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم المناشئ (Posts Control)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.post_add, color: Color(0xFF0097A7), size: 20),
                          SizedBox(width: 8),
                          const Text(
                            "إدارة المنشورات",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _postTitleArController,
                        style: TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: "عنوان المنشور (عربي)",
                          labelStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _postTitleEnController,
                        style: TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: "عنوان المنشور (إنجليزي)",
                          labelStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _postImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_postImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                            )
                          : Container(
                              height: 80,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
                                  SizedBox(height: 4),
                                  Text("اختر صورة للرفع", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploadingPost ? null : () => _pickImage(true),
                              icon: Icon(Icons.photo_library, size: 18),
                              label: const Text("اختيار صورة", style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF0097A7),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isUploadingPost
                                ? Container(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            value: _uploadProgress,
                                            strokeWidth: 3,
                                            color: Color(0xFF0097A7),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                                          style: TextStyle(fontSize: 13, color: Color(0xFF0097A7)),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _uploadPostImage,
                                    icon: Icon(Icons.upload, size: 18),
                                    label: const Text("رفع المنشور", style: TextStyle(fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0097A7),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // عرض المنشورات الحالية
              const Text(
                "المنشورات الحالية",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: postsCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text("لا توجد منشورات", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ),
                    );
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Image.network(
                                data['url'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title_ar'] ?? 'بدون عنوان',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      data['title_en'] ?? 'No title',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Spacer(),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteImage(data['url'], doc.id, postsCollection),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // قسم المعرض (Gallery)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_library, color: Color(0xFF0097A7), size: 20),
                          SizedBox(width: 8),
                          const Text(
                            "إدارة المعرض",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _galleryTitleArController,
                        style: TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: "عنوان الصورة (عربي)",
                          labelStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _galleryTitleEnController,
                        style: TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: "عنوان الصورة (إنجليزي)",
                          labelStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _galleryImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_galleryImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                            )
                          : Container(
                              height: 80,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
                                  SizedBox(height: 4),
                                  Text("اختر صورة للرفع", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploadingGallery ? null : () => _pickImage(false),
                              icon: Icon(Icons.photo_library, size: 18),
                              label: const Text("اختيار صورة", style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF0097A7),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isUploadingGallery
                                ? Container(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            value: _uploadProgress,
                                            strokeWidth: 3,
                                            color: Color(0xFF0097A7),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                                          style: TextStyle(fontSize: 13, color: Color(0xFF0097A7)),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _uploadGalleryImage,
                                    icon: Icon(Icons.upload, size: 18),
                                    label: const Text("رفع للمعرض", style: TextStyle(fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0097A7),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // عرض صور المعرض
              const Text(
                "صور المعرض",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: galleryCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text("لا توجد صور في المعرض", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ),
                    );
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Image.network(
                                data['url'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title_ar'] ?? 'بدون عنوان',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      data['title_en'] ?? 'No title',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Spacer(),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteImage(data['url'], doc.id, galleryCollection),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
