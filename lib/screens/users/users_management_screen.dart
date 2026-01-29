import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;

class UsersManagementScreen extends StatefulWidget {
  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Add Button
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة العملاء',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a2e),
                          ),
                        ),
                        SizedBox(height: 2),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.docs.length ?? 0;
                            return Text(
                              '$count عميل مسجل',
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
                        onPressed: _showAddUserDialog,
                        icon: Icon(Icons.person_add_outlined, size: 18),
                        label: Text('إضافة عميل', style: TextStyle(fontSize: 12)),
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
                SizedBox(height: 16),

                // Stats Row
                _buildStatsRow(),
                SizedBox(height: 16),

                // Search & Filter
                _buildSearchAndFilter(),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF667eea),
                    ),
                  );
                }

                var users = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final phone = (data['phoneNumber'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || phone.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userData = user.data() as Map<String, dynamic>;
                    return _buildUserCard(user.id, userData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(height: 50);

        final users = snapshot.data!.docs;
        final wholesaleCount = users.where((d) => (d.data() as Map)['userType'] == 'wholesale').length;
        final vipCount = users.where((d) => (d.data() as Map)['userType'] == 'vip').length;
        final specialCount = users.where((d) => (d.data() as Map)['userType'] == 'special').length;

        return Row(
          children: [
            Expanded(child: _buildStatChip('جملة', wholesaleCount, Colors.blue)),
            SizedBox(width: 8),
            Expanded(child: _buildStatChip('VIP', vipCount, Colors.purple)),
            SizedBox(width: 8),
            Expanded(child: _buildStatChip('خاص', specialCount, Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1a2e),
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: Container(
            height: 44,
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
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الهاتف...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
        ),
        SizedBox(width: 12),

        // Filter Dropdown
        Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: 12),
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
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterType,
                underline: SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'public', child: Text('عام')),
                  DropdownMenuItem(value: 'wholesale', child: Text('جملة')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  DropdownMenuItem(value: 'special', child: Text('خاص')),
                ],
                onChanged: (value) {
                  setState(() => _filterType = value!);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
          SizedBox(height: 12),
          Text(
            'لا يوجد عملاء',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: Text(
                'مسح البحث',
                style: TextStyle(fontSize: 12, color: Color(0xFF667eea)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = FirebaseFirestore.instance.collection('users');

    if (_filterType != 'all') {
      query = query.where('userType', isEqualTo: _filterType);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final userType = userData['userType'] ?? 'public';
    final savedItems = List.from(userData['savedItems'] ?? []);
    final createdAt = userData['createdAt'] as Timestamp?;

    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getUserTypeColor(userType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                (userData['name'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: _getUserTypeColor(userType),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  userData['name'] ?? 'بدون اسم',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
              ),
              _buildUserTypeBadge(userType),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              userData['phoneNumber'] ?? 'بدون رقم',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
          children: [
            Divider(height: 1, color: Colors.grey[100]),
            SizedBox(height: 12),

            // User Details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.tag, 'المعرف', '#${userId.substring(0, min(8, userId.length))}'),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.favorite_outline, 'المفضلة', '${savedItems.length}'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                if (userData['email'] != null && userData['email'].toString().isNotEmpty)
                  Expanded(
                    child: _buildInfoItem(Icons.email_outlined, 'البريد', userData['email']),
                  ),
                if (createdAt != null)
                  Expanded(
                    child: _buildInfoItem(Icons.calendar_today_outlined, 'التسجيل', _formatDate(createdAt)),
                  ),
              ],
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'تغيير النوع',
                    Icons.swap_horiz,
                    Color(0xFF667eea),
                    () => _showChangeTypeMenu(userId),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'الطلبات',
                    Icons.shopping_bag_outlined,
                    Colors.green,
                    () => _viewUserOrders(userId, userData['name']),
                  ),
                ),
                SizedBox(width: 8),
                _buildIconAction(
                  Icons.notifications_outlined,
                  Colors.orange,
                  () => _sendNotification(userId, userData['name']),
                ),
                SizedBox(width: 8),
                _buildIconAction(
                  Icons.delete_outline,
                  Colors.red,
                  () => _deleteUser(userId, userData['name']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1a1a2e)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeBadge(String userType) {
    final color = _getUserTypeColor(userType);
    final label = _getUserTypeLabel(userType);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'wholesale':
        return Colors.blue;
      case 'vip':
        return Colors.purple;
      case 'special':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case 'wholesale':
        return 'جملة';
      case 'vip':
        return 'VIP';
      case 'special':
        return 'خاص';
      default:
        return 'عام';
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd').format(date);
  }

  void _showChangeTypeMenu(String userId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تغيير نوع العميل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              _buildTypeOption('عام', 'public', Colors.grey, userId),
              _buildTypeOption('جملة', 'wholesale', Colors.blue, userId),
              _buildTypeOption('VIP', 'vip', Colors.purple, userId),
              _buildTypeOption('خاص', 'special', Colors.orange, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, String type, Color color, String userId) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      title: Text(label, style: TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        _updateUserType(userId, type);
      },
    );
  }

  Future<void> _updateUserType(String userId, String newType) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'userType': newType});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث نوع العميل', style: TextStyle(fontSize: 13)),
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

  void _viewUserOrders(String userId, String? userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserOrdersScreen(userId: userId, userName: userName),
      ),
    );
  }

  void _sendNotification(String userId, String? userName) {
    showDialog(
      context: context,
      builder: (context) => SendNotificationDialog(userId: userId, userName: userName),
    );
  }

  void _deleteUser(String userId, String? userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('تأكيد الحذف', style: TextStyle(fontSize: 16)),
        content: Text('هل أنت متأكد من حذف "${userName ?? ''}"؟', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف العميل', style: TextStyle(fontSize: 13)),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedType = 'public';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('إضافة عميل جديد', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameController, 'الاسم', Icons.person_outline),
                SizedBox(height: 12),
                _buildDialogTextField(phoneController, 'رقم الهاتف', Icons.phone_outlined, keyboardType: TextInputType.phone),
                SizedBox(height: 12),
                _buildDialogTextField(emailController, 'البريد (اختياري)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.category_outlined, size: 20, color: Colors.grey[600]),
                    ),
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                    items: [
                      DropdownMenuItem(value: 'public', child: Text('عام')),
                      DropdownMenuItem(value: 'wholesale', child: Text('جملة')),
                      DropdownMenuItem(value: 'vip', child: Text('VIP')),
                      DropdownMenuItem(value: 'special', child: Text('خاص')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedType = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الرجاء ملء الحقول المطلوبة', style: TextStyle(fontSize: 13)),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('users').add({
                    'name': nameController.text,
                    'phoneNumber': phoneController.text,
                    'email': emailController.text.isEmpty ? null : emailController.text,
                    'userType': selectedType,
                    'createdAt': FieldValue.serverTimestamp(),
                    'savedItems': [],
                  });

                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إضافة العميل', style: TextStyle(fontSize: 13)),
                        backgroundColor: Color(0xFF667eea),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e', style: TextStyle(fontSize: 13)),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
              ),
              child: Text('إضافة', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

// User Orders Screen
class UserOrdersScreen extends StatelessWidget {
  final String userId;
  final String? userName;

  UserOrdersScreen({required this.userId, this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'طلبات ${userName ?? 'العميل'}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1a1a2e)),
        ),
        iconTheme: IconThemeData(color: Color(0xFF1a1a2e)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customer.userId', isEqualTo: userId)
            .orderBy('timestamps.created', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF667eea)));
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[300]),
                  SizedBox(height: 12),
                  Text('لا توجد طلبات', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final status = order['status'] ?? 'pending';
              final pricing = order['pricing'] ?? {};

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(14),
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
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${orders[index].id.substring(0, 8)}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${pricing['total'] ?? 0} د.ع',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'processing': return 'قيد التحضير';
      case 'shipped': return 'قيد التوصيل';
      case 'delivered': return 'تم التسليم';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}

// Send Notification Dialog
class SendNotificationDialog extends StatefulWidget {
  final String userId;
  final String? userName;

  const SendNotificationDialog({Key? key, required this.userId, this.userName}) : super(key: key);

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('إرسال إشعار', style: TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'إلى: ${widget.userName ?? 'العميل'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          TextField(
            controller: titleController,
            style: TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'عنوان الإشعار',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: messageController,
            style: TextStyle(fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'نص الإشعار',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: TextStyle(fontSize: 13)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (titleController.text.isEmpty || messageController.text.isEmpty) {
              return;
            }

            try {
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': widget.userId,
                'title': titleController.text,
                'message': messageController.text,
                'type': 'admin_message',
                'read': false,
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إرسال الإشعار', style: TextStyle(fontSize: 13)),
                  backgroundColor: Color(0xFF667eea),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ: $e', style: TextStyle(fontSize: 13)),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF667eea),
            foregroundColor: Colors.white,
          ),
          child: Text('إرسال', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
