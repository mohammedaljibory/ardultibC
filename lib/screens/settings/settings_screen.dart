import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../category_management_screen.dart';
//import '../category_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Store Settings Controllers
  final _storeNameArController = TextEditingController();
  final _storeNameEnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressArController = TextEditingController();
  final _addressEnController = TextEditingController();

  // Delivery Settings
  final _deliveryFeeController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _freeDeliveryController = TextEditingController();

  // Admin Settings
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _enableNotifications = true;
  bool _enableOrders = true;
  bool _maintenanceMode = false;

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
        _phoneController.text = data['mobile_numbers_ar'] ?? '';
        _whatsappController.text = data['whatsapp_number'] ?? '';
        _emailController.text = data['email_ar'] ?? '';
        _addressArController.text = data['address_ar'] ?? '';
        _addressEnController.text = data['address_en'] ?? '';
      }

      // Load delivery settings
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

      // Load app settings
      final appDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .get();

      if (appDoc.exists) {
        final data = appDoc.data()!;
        setState(() {
          _enableNotifications = data['enableNotifications'] ?? true;
          _enableOrders = data['enableOrders'] ?? true;
          _maintenanceMode = data['maintenanceMode'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Information
            _buildSectionTitle('معلومات المتجر'),
            _buildStoreInfoSection(),
            SizedBox(height: 32),

            // Delivery Settings
            _buildSectionTitle('إعدادات التوصيل'),
            _buildDeliverySection(),
            SizedBox(height: 32),
/*
            // App Settings
            _buildSectionTitle('إعدادات التطبيق'),
            _buildAppSettingsSection(),
            SizedBox(height: 32),
*/
            // Categories Management

            _buildSectionTitle('إدارة التصنيفات'),
            _buildCategoriesSection(),
            SizedBox(height: 32),

            /*
            // Admin Account
            _buildSectionTitle('حساب المسؤول'),
            _buildAdminSection(),
            SizedBox(height: 32),

            // Backup & Export
            _buildSectionTitle('النسخ الاحتياطي والتصدير'),
            _buildBackupSection(),
            */

          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _storeNameArController,
                    decoration: InputDecoration(
                      labelText: 'اسم المتجر (عربي)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _storeNameEnController,
                    decoration: InputDecoration(
                      labelText: 'Store Name (English)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _whatsappController,
                    decoration: InputDecoration(
                      labelText: 'واتساب',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.chat),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressArController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'العنوان (عربي)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _addressEnController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address (English)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveStoreInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('حفظ معلومات المتجر'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'رسوم التوصيل (د.ع)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.delivery_dining),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _minimumOrderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الحد الأدنى للطلب (د.ع)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.shopping_cart),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _freeDeliveryController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'توصيل مجاني للطلبات أكثر من (د.ع)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.local_shipping),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveDeliverySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('حفظ إعدادات التوصيل'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('تفعيل الإشعارات'),
            subtitle: Text('إرسال إشعارات للمستخدمين'),
            value: _enableNotifications,
            onChanged: (value) {
              setState(() => _enableNotifications = value);
              _saveAppSettings();
            },
            activeColor: Color(0xFF2196F3),
          ),
          Divider(),
          SwitchListTile(
            title: Text('تفعيل الطلبات'),
            subtitle: Text('السماح بإستقبال طلبات جديدة'),
            value: _enableOrders,
            onChanged: (value) {
              setState(() => _enableOrders = value);
              _saveAppSettings();
            },
            activeColor: Color(0xFF2196F3),
          ),
          Divider(),
          SwitchListTile(
            title: Text('وضع الصيانة'),
            subtitle: Text('إيقاف التطبيق مؤقتاً للصيانة'),
            value: _maintenanceMode,
            onChanged: (value) {
              setState(() => _maintenanceMode = value);
              _saveAppSettings();
            },
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.category, color: Color(0xFF2196F3)),
            title: Text('إدارة التصنيفات'),
            subtitle: Text('إضافة وتعديل وحذف تصنيفات المنتجات'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {  // Changed from onPressed to onTap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('تغيير كلمة المرور'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.backup, color: Colors.green),
            title: Text('نسخة احتياطية'),
            subtitle: Text('إنشاء نسخة احتياطية من البيانات'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _createBackup,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.download, color: Colors.blue),
            title: Text('تصدير البيانات'),
            subtitle: Text('تصدير البيانات إلى Excel'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _exportData,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.restore, color: Colors.orange),
            title: Text('استعادة البيانات'),
            subtitle: Text('استعادة من نسخة احتياطية'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: _restoreBackup,
          ),
        ],
      ),
    );
  }

  Future<void> _saveStoreInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('website_content')
          .doc('main')
          .update({
        'company_name_ar': _storeNameArController.text,
        'company_name_en': _storeNameEnController.text,
        'mobile_numbers_ar': _phoneController.text,
        'mobile_numbers_en': _phoneController.text,
        'whatsapp_number': _whatsappController.text,
        'email_ar': _emailController.text,
        'email_en': _emailController.text,
        'address_ar': _addressArController.text,
        'address_en': _addressEnController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ معلومات المتجر بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ إعدادات التوصيل بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveAppSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .set({
        'enableNotifications': _enableNotifications,
        'enableOrders': _enableOrders,
        'maintenanceMode': _maintenanceMode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ إعدادات التطبيق')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('كلمات المرور غير متطابقة'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Re-authenticate
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);

        // Change password
        await user.updatePassword(_newPasswordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );

        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _createBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري إنشاء نسخة احتياطية...')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري تصدير البيانات...')),
    );
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحذير'),
        content: Text('سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('جاري استعادة البيانات...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('استعادة'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _storeNameArController.dispose();
    _storeNameEnController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    _deliveryFeeController.dispose();
    _minimumOrderController.dispose();
    _freeDeliveryController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}