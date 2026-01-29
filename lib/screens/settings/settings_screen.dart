import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../category_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Store Settings Controllers
  final _storeNameArController = TextEditingController();
  final _storeNameEnController = TextEditingController();
  final _homeTitleArController = TextEditingController();
  final _homeTitleEnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressArController = TextEditingController();
  final _addressEnController = TextEditingController();

  // Delivery Settings
  final _deliveryFeeController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _freeDeliveryController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('website_content')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _storeNameArController.text = data['company_name_ar'] ?? '';
        _storeNameEnController.text = data['company_name_en'] ?? '';
        _homeTitleArController.text = data['home_page_title_ar'] ?? '';
        _homeTitleEnController.text = data['home_page_title_en'] ?? '';
        _phoneController.text = data['mobile_numbers_ar'] ?? '';
        _whatsappController.text = data['whatsapp_number'] ?? '';
        _emailController.text = data['email_ar'] ?? '';
        _addressArController.text = data['address_ar'] ?? '';
        _addressEnController.text = data['address_en'] ?? '';
      }

      final deliveryDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery')
          .get();

      if (deliveryDoc.exists) {
        final data = deliveryDoc.data()!;
        _deliveryFeeController.text = (data['deliveryFee'] ?? 0).toString();
        _minimumOrderController.text = (data['minimumOrder'] ?? 0).toString();
        _freeDeliveryController.text = (data['freeDeliveryThreshold'] ?? 0).toString();
      }
    } catch (e) {
      // Error loading settings
    }
  }

  @override
  void dispose() {
    _storeNameArController.dispose();
    _storeNameEnController.dispose();
    _homeTitleArController.dispose();
    _homeTitleEnController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    _deliveryFeeController.dispose();
    _minimumOrderController.dispose();
    _freeDeliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'إعدادات المتجر والتوصيل',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Store Information
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('معلومات المتجر', Icons.store_outlined),
                  SizedBox(height: 12),
                  _buildStoreInfoSection(),
                  SizedBox(height: 24),

                  _buildSectionHeader('إعدادات التوصيل', Icons.delivery_dining_outlined),
                  SizedBox(height: 12),
                  _buildDeliverySection(),
                  SizedBox(height: 24),

                  _buildSectionHeader('إدارة التصنيفات', Icons.category_outlined),
                  SizedBox(height: 12),
                  _buildCategoriesSection(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF667eea), size: 16),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1a1a2e),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfoSection() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Store Name
            Row(
              children: [
                Expanded(child: _buildTextField(_storeNameArController, 'اسم المتجر (عربي)')),
                SizedBox(width: 12),
                Expanded(child: _buildTextField(_storeNameEnController, 'Store Name (English)')),
              ],
            ),
            SizedBox(height: 12),

            // Home Title
            Row(
              children: [
                Expanded(child: _buildTextField(_homeTitleArController, 'عنوان الرئيسية (عربي)')),
                SizedBox(width: 12),
                Expanded(child: _buildTextField(_homeTitleEnController, 'Home Title (English)')),
              ],
            ),
            SizedBox(height: 12),

            // Contact Info
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _phoneController,
                    'رقم الهاتف',
                    icon: Icons.phone_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _whatsappController,
                    'واتساب',
                    icon: Icons.chat_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            _buildTextField(
              _emailController,
              'البريد الإلكتروني',
              icon: Icons.email_outlined,
            ),
            SizedBox(height: 12),

            // Address
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _addressArController,
                    'العنوان (عربي)',
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _addressEnController,
                    'Address (English)',
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveStoreInfo,
                icon: _isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.save_outlined, size: 18),
                label: Text(
                  'حفظ معلومات المتجر',
                  style: TextStyle(fontSize: 12),
                ),
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
    );
  }

  Widget _buildDeliverySection() {
    return Container(
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _deliveryFeeController,
                  'رسوم التوصيل (د.ع)',
                  icon: Icons.delivery_dining_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  _minimumOrderController,
                  'الحد الأدنى (د.ع)',
                  icon: Icons.shopping_cart_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildTextField(
            _freeDeliveryController,
            'توصيل مجاني للطلبات أكثر من (د.ع)',
            icon: Icons.local_shipping_outlined,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _saveDeliverySettings,
              icon: Icon(Icons.save_outlined, size: 18),
              label: Text('حفظ إعدادات التوصيل', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

  Widget _buildCategoriesSection() {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.category_outlined, color: Colors.orange, size: 20),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة التصنيفات',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'إضافة وتعديل وحذف تصنيفات المنتجات',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey[500]) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(fontSize: 13)),
          backgroundColor: isError ? Colors.red : Color(0xFF667eea),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _saveStoreInfo() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('website_content')
          .doc('main')
          .update({
        'company_name_ar': _storeNameArController.text,
        'company_name_en': _storeNameEnController.text,
        'home_page_title_ar': _homeTitleArController.text,
        'home_page_title_en': _homeTitleEnController.text,
        'mobile_numbers_ar': _phoneController.text,
        'mobile_numbers_en': _phoneController.text,
        'whatsapp_number': _whatsappController.text,
        'email_ar': _emailController.text,
        'email_en': _emailController.text,
        'address_ar': _addressArController.text,
        'address_en': _addressEnController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('تم حفظ معلومات المتجر');
    } catch (e) {
      _showSnackBar('خطأ: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDeliverySettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery')
          .set({
        'deliveryFee': int.tryParse(_deliveryFeeController.text) ?? 0,
        'minimumOrder': int.tryParse(_minimumOrderController.text) ?? 0,
        'freeDeliveryThreshold': int.tryParse(_freeDeliveryController.text) ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('تم حفظ إعدادات التوصيل');
    } catch (e) {
      _showSnackBar('خطأ: $e', isError: true);
    }
  }
}
