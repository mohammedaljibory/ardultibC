import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UsersManagementScreen extends StatefulWidget {
  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو رقم الهاتف...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _filterType,
                    underline: SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('جميع المستخدمين')),
                      DropdownMenuItem(value: 'public', child: Text('عام')),
                      DropdownMenuItem(value: 'wholesale', child: Text('جملة')),
                      DropdownMenuItem(value: 'vip', child: Text('VIP')),
                      DropdownMenuItem(value: 'special', child: Text('خاص')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterType = value!);
                    },
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: Icon(Icons.person_add),
                  label: Text('إضافة مستخدم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text('لا يوجد مستخدمين', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
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
    final lastLogin = userData['lastLogin'] as Timestamp?;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getUserTypeColor(userType).withOpacity(0.2),
          child: Text(
            (userData['name'] ?? 'U')[0].toUpperCase(),
            style: TextStyle(
              color: _getUserTypeColor(userType),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userData['name'] ?? 'بدون اسم',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildUserTypeChip(userType),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('الهاتف: ${userData['phoneNumber'] ?? 'غير محدد'}'),
            if (userData['email'] != null && userData['email'].toString().isNotEmpty)
              Text('البريد: ${userData['email']}'),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details
                _buildDetailRow('معرف المستخدم', userId.substring(0, min(8, userId.length))),
                _buildDetailRow('العنوان', userData['address'] ?? 'غير محدد'),
                _buildDetailRow('المفضلة', '${savedItems.length} منتج'),
                if (createdAt != null)
                  _buildDetailRow('تاريخ التسجيل', _formatDate(createdAt)),
                if (lastLogin != null)
                  _buildDetailRow('آخر دخول', _formatDate(lastLogin)),

                SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Change User Type
                    PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('تغيير النوع', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                      onSelected: (newType) => _updateUserType(userId, newType),
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'public', child: Text('عام')),
                        PopupMenuItem(value: 'wholesale', child: Text('جملة')),
                        PopupMenuItem(value: 'vip', child: Text('VIP')),
                        PopupMenuItem(value: 'special', child: Text('خاص')),
                      ],
                    ),
                    SizedBox(width: 8),

                    // View Orders
                    OutlinedButton.icon(
                      onPressed: () => _viewUserOrders(userId, userData['name']),
                      icon: Icon(Icons.shopping_cart, size: 18),
                      label: Text('الطلبات'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                    SizedBox(width: 8),

                    // Send Notification
                    OutlinedButton.icon(
                      onPressed: () => _sendNotification(userId, userData['name']),
                      icon: Icon(Icons.notifications, size: 18),
                      label: Text('إشعار'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                      ),
                    ),
                    SizedBox(width: 8),

                    // Delete User
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(userId, userData['name']),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    final color = _getUserTypeColor(userType);
    final label = _getUserTypeLabel(userType);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }

  int min(int a, int b) => a < b ? a : b;

  Future<void> _updateUserType(String userId, String newType) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'userType': newType});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث نوع المستخدم بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewUserOrders(String userId, String? userName) {
    // Navigate to orders screen with user filter
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
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم ${userName ?? ''}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف المستخدم بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
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
      builder: (context) => AlertDialog(
        title: Text('إضافة مستخدم جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني (اختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'نوع المستخدم',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'public', child: Text('عام')),
                  DropdownMenuItem(value: 'wholesale', child: Text('جملة')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  DropdownMenuItem(value: 'special', child: Text('خاص')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('الرجاء ملء الحقول المطلوبة')),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إضافة المستخدم بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

// Helper Screens
class UserOrdersScreen extends StatelessWidget {
  final String userId;
  final String? userName;

  UserOrdersScreen({required this.userId, this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات ${userName ?? 'المستخدم'}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customer.userId', isEqualTo: userId)
            .orderBy('timestamps.created', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Center(
              child: Text('لا توجد طلبات لهذا المستخدم'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('طلب #${orders[index].id.substring(0, 8)}'),
                  subtitle: Text('المبلغ: ${order['pricing']?['total'] ?? 0} د.ع'),
                  trailing: Text(order['status'] ?? 'pending'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
      title: Text('إرسال إشعار إلى ${widget.userName ?? 'المستخدم'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'عنوان الإشعار',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: messageController,
            decoration: InputDecoration(
              labelText: 'نص الإشعار',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء'),
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
                SnackBar(content: Text('تم إرسال الإشعار بنجاح')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
              );
            }
          },
          child: Text('إرسال'),
        ),
      ],
    );
  }
}