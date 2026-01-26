import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // لضغط الصور
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
        print("Image picked: ${pickedFile.path}");
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<File> _compressImage(File imageFile) async {
    // قراءة الصورة
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception("Failed to decode image");

    // تغيير حجم الصورة إذا لزم الأمر (مثلاً 800px كحد أقصى للعرض)
    final img.Image resizedImage = img.copyResize(image, width: 800);

    // ضغط الصورة بجودة 70%
    final Uint8List compressedImage = img.encodeJpg(resizedImage, quality: 70);

    // حفظ الصورة المضغوطة في ملف مؤقت
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedImage);

    return tempFile;
  }

  Future<void> _uploadPostImage() async {
    if (_postImage == null || _postTitleArController.text.isEmpty || _postTitleEnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image and enter titles in both languages")),
      );
      return;
    }

    setState(() {
      _isUploadingPost = true;
      _uploadProgress = 0.0;
    });

    try {
      print("Compressing post image...");
      final compressedImage = await _compressImage(_postImage!);

      print("Uploading post image...");
      final storageRef = FirebaseStorage.instance.ref().child('posts/post_${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = storageRef.putFile(
        compressedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
        });
        print("Upload progress: ${(_uploadProgress * 100).toStringAsFixed(2)}%");
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
        const SnackBar(content: Text("Post image uploaded successfully!")),
      );
    } catch (e) {
      setState(() {
        _isUploadingPost = false;
      });
      print("Error uploading post image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading post image: $e")),
      );
    }
  }

  Future<void> _uploadGalleryImage() async {
    if (_galleryImage == null || _galleryTitleArController.text.isEmpty || _galleryTitleEnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image and enter titles in both languages")),
      );
      return;
    }

    setState(() {
      _isUploadingGallery = true;
      _uploadProgress = 0.0;
    });

    try {
      print("Compressing gallery image...");
      final compressedImage = await _compressImage(_galleryImage!);

      print("Uploading gallery image...");
      final storageRef = FirebaseStorage.instance.ref().child('gallery/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = storageRef.putFile(
        compressedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
        });
        print("Upload progress: ${(_uploadProgress * 100).toStringAsFixed(2)}%");
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
        const SnackBar(content: Text("Gallery image uploaded successfully!")),
      );
    } catch (e) {
      setState(() {
        _isUploadingGallery = false;
      });
      print("Error uploading gallery image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading gallery image: $e")),
      );
    }
  }

  Future<void> _deleteImage(String url, String docId, CollectionReference collection) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (url.isNotEmpty && url.startsWith('https://firebasestorage.googleapis.com')) {
        final storageRef = FirebaseStorage.instance.refFromURL(url);
        await storageRef.delete();
        print("Image deleted from Storage");
      } else {
        print("Invalid URL, skipping Storage deletion: $url");
      }
      await collection.doc(docId).delete();
      print("Document deleted from Firestore");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Images"),
        backgroundColor: const Color(0xFF6A11CB),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم المناشئ (Posts Control)
              const Text(
                "Posts Control",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _postTitleArController,
                decoration: const InputDecoration(
                  labelText: "Post Title (Arabic)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _postTitleEnController,
                decoration: const InputDecoration(
                  labelText: "Post Title (English)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _postImage != null
                  ? Image.file(_postImage!, height: 100, fit: BoxFit.cover)
                  : const Text("Select an image to upload"),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isUploadingPost ? null : () => _pickImage(true),
                    child: const Text("Pick Post Image"),
                  ),
                  const SizedBox(width: 10),
                  _isUploadingPost
                      ? Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 6,
                        color: const Color(0xFF6A11CB),
                        backgroundColor: Colors.grey[300],
                      ),
                      Text(
                        "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  )
                      : ElevatedButton(
                    onPressed: _uploadPostImage,
                    child: const Text("Upload Post"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder(
                stream: postsCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No posts available.");
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                data['url'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Text(data['title_ar'] ?? 'No Arabic Title'),
                            Text(data['title_en'] ?? 'No English Title'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteImage(data['url'], doc.id, postsCollection),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // قسم المعرض (Gallery)
              const Text(
                "Gallery",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _galleryTitleArController,
                decoration: const InputDecoration(
                  labelText: "Gallery Image Title (Arabic)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _galleryTitleEnController,
                decoration: const InputDecoration(
                  labelText: "Gallery Image Title (English)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _galleryImage != null
                  ? Image.file(_galleryImage!, height: 100, fit: BoxFit.cover)
                  : const Text("Select an image to upload"),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isUploadingGallery ? null : () => _pickImage(false),
                    child: const Text("Pick Gallery Image"),
                  ),
                  const SizedBox(width: 10),
                  _isUploadingGallery
                      ? Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 6,
                        color: const Color(0xFF6A11CB),
                        backgroundColor: Colors.grey[300],
                      ),
                      Text(
                        "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  )
                      : ElevatedButton(
                    onPressed: _uploadGalleryImage,
                    child: const Text("Upload to Gallery"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder(
                stream: galleryCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No gallery images available.");
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                data['url'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Text(data['title_ar'] ?? 'No Arabic Title'),
                            Text(data['title_en'] ?? 'No English Title'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteImage(data['url'], doc.id, galleryCollection),
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