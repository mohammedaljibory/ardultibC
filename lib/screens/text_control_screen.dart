import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TextControlScreen extends StatefulWidget {
  @override
  _TextControlScreenState createState() => _TextControlScreenState();
}

class _TextControlScreenState extends State<TextControlScreen> {
  final CollectionReference contentCollection =
  FirebaseFirestore.instance.collection('website_content');
  final TextEditingController _homeTitleArController = TextEditingController();
  final TextEditingController _homeTitleEnController = TextEditingController();
  final TextEditingController _companyNameArController = TextEditingController();
  final TextEditingController _companyNameEnController = TextEditingController();
  final TextEditingController _mobileNumbersArController = TextEditingController();
  final TextEditingController _mobileNumbersEnController = TextEditingController();
  final TextEditingController _emailArController = TextEditingController();
  final TextEditingController _emailEnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تهيئة القيم من Firestore
    contentCollection.doc('main').get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _homeTitleArController.text = data['home_page_title_ar'] ?? '';
        _homeTitleEnController.text = data['home_page_title_en'] ?? '';
        _companyNameArController.text = data['company_name_ar'] ?? '';
        _companyNameEnController.text = data['company_name_en'] ?? '';
        _mobileNumbersArController.text = data['mobile_numbers_ar'] ?? '';
        _mobileNumbersEnController.text = data['mobile_numbers_en'] ?? '';
        _emailArController.text = data['email_ar'] ?? '';
        _emailEnController.text = data['email_en'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _homeTitleArController.dispose();
    _homeTitleEnController.dispose();
    _companyNameArController.dispose();
    _companyNameEnController.dispose();
    _mobileNumbersArController.dispose();
    _mobileNumbersEnController.dispose();
    _emailArController.dispose();
    _emailEnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Website Texts"),
        backgroundColor: const Color(0xFF6A11CB),
      ),
      body: StreamBuilder(
        stream: contentCollection.doc('main').snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No content available. Create sample data first."));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildTextField(_homeTitleArController, "Home Page Title (Arabic)"),
                const SizedBox(height: 16),
                _buildTextField(_homeTitleEnController, "Home Page Title (English)"),
                const SizedBox(height: 16),
                _buildTextField(_companyNameArController, "Company Name (Arabic)"),
                const SizedBox(height: 16),
                _buildTextField(_companyNameEnController, "Company Name (English)"),
                const SizedBox(height: 16),
                _buildTextField(_mobileNumbersArController, "Mobile Numbers (Arabic)"),
                const SizedBox(height: 16),
                _buildTextField(_mobileNumbersEnController, "Mobile Numbers (English)"),
                const SizedBox(height: 16),
                _buildTextField(_emailArController, "Email (Arabic)"),
                const SizedBox(height: 16),
                _buildTextField(_emailEnController, "Email (English)"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    contentCollection.doc('main').update({
                      'home_page_title_ar': _homeTitleArController.text,
                      'home_page_title_en': _homeTitleEnController.text,
                      'company_name_ar': _companyNameArController.text,
                      'company_name_en': _companyNameEnController.text,
                      'mobile_numbers_ar': _mobileNumbersArController.text,
                      'mobile_numbers_en': _mobileNumbersEnController.text,
                      'email_ar': _emailArController.text,
                      'email_en': _emailEnController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Content updated successfully!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}