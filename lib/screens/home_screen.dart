// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'text_control_screen.dart';
import 'image_control_screen.dart';
import 'store_management_screen.dart';

class HomeScreen extends StatelessWidget {
  void _createSampleData() {
    final contentCollection = FirebaseFirestore.instance.collection('website_content');
    final postsCollection = FirebaseFirestore.instance.collection('posts');
    final galleryCollection = FirebaseFirestore.instance.collection('gallery');

    // نصوص الموقع
    contentCollection.doc('main').set({
      'home_page_title_ar': 'مرحبًا بكم في موقعنا',
      'home_page_title_en': 'Welcome to Our Website',
      'company_name_ar': 'شركتي',
      'company_name_en': 'My Company',
      'mobile_numbers_ar': '123-456-7890, 098-765-4321',
      'mobile_numbers_en': '123-456-7890, 098-765-4321',
      'email_ar': 'info@mycompany.com',
      'email_en': 'info@mycompany.com',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // منشورات تجريبية
    postsCollection.add({
      'title_ar': 'ميدترونيك',
      'title_en': 'Medtronic',
      'url': 'https://via.placeholder.com/150',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // صور معرض تجريبية
    galleryCollection.add({
      'title_ar': 'صورة المعرض 1',
      'title_en': 'Gallery Image 1',
      'url': 'https://via.placeholder.com/200',
      'timestamp': FieldValue.serverTimestamp(),
    });
    galleryCollection.add({
      'title_ar': 'صورة المعرض 2',
      'title_en': 'Gallery Image 2',
      'url': 'https://via.placeholder.com/300',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Medicine Land control panel",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TextControlScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Manage Texts",
                  style: TextStyle(
                    color: Color(0xFF6A11CB),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ImageControlScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Manage Images",
                  style: TextStyle(
                    color: Color(0xFF6A11CB),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StoreManagementScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Store Management",
                  style: TextStyle(
                    color: Color(0xFF6A11CB),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /*
              ElevatedButton(
                onPressed: () {
                  _createSampleData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sample content created!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Create Sample Content",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              */
            ],
          ),
        ),
      ),
    );
  }
}