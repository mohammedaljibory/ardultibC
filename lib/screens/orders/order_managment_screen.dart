import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../order_details_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  @override
  _OrdersManagementScreenState createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'orderNumber'; // orderNumber, phone, email, userName

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Enhanced Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar with Type Selection
                // Search Bar with Type Selection - FIXED VERSION
                Row(
                  children: [
                    // Search Type Dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _searchType,
                        underline: SizedBox(),
                        items: [
                          DropdownMenuItem(value: 'orderNumber', child: Text('رقم الطلب')),
                          DropdownMenuItem(value: 'phone', child: Text('الهاتف')),
                          DropdownMenuItem(value: 'email', child: Text('البريد')),
                          DropdownMenuItem(value: 'userName', child: Text('اسم العميل')),
                        ],
                        onChanged: (value) {
                          setState(() => _searchType = value!);
                        },
                      ),
                    ),
                    // Search Input - FIXED
                    Expanded(
                      child: Container(
                        height: 48, // Fixed height to match dropdown
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _getSearchHint(),
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              borderSide: BorderSide.none, // Remove border
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: Color(0xFF6A11CB), width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'الكل', null),
                      SizedBox(width: 8),
                      _buildFilterChip('pending', 'قيد الانتظار', Colors.orange),
                      SizedBox(width: 8),
                      _buildFilterChip('processing', 'قيد التحضير', Colors.blue),
                      SizedBox(width: 8),
                      _buildFilterChip('shipped', 'قيد التوصيل', Colors.purple),
                      SizedBox(width: 8),
                      _buildFilterChip('delivered', 'تم التسليم', Colors.green),
                      SizedBox(width: 8),
                      _buildFilterChip('cancelled', 'ملغي', Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    switch (_searchType) {
                      case 'orderNumber':
                        return doc.id.toLowerCase().contains(_searchQuery) ||
                            (data['orderNumber'] ?? '').toString().toLowerCase().contains(_searchQuery);
                      case 'phone':
                        final customer = data['customer'] ?? {};
                        return (customer['phone'] ?? '').toString().toLowerCase().contains(_searchQuery);
                      case 'email':
                        final customer = data['customer'] ?? {};
                        return (customer['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
                      case 'userName':
                        final customer = data['customer'] ?? {};
                        return (customer['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                      default:
                        return false;
                    }
                  }).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text('لا توجد نتائج', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            child: Text('مسح البحث'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    return _buildEnhancedOrderCard(order.id, orderData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'orderNumber':
        return 'ابحث برقم الطلب...';
      case 'phone':
        return 'ابحث برقم الهاتف...';
      case 'email':
        return 'ابحث بالبريد الإلكتروني...';
      case 'userName':
        return 'ابحث باسم العميل...';
      default:
        return 'ابحث...';
    }
  }

  Widget _buildFilterChip(String value, String label, Color? color) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color?.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance.collection('orders');

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return query.orderBy('timestamps.created', descending: true).snapshots();
  }

  Widget _buildEnhancedOrderCard(String orderId, Map<String, dynamic> order) {
    final customer = order['customer'] ?? {};
    final delivery = order['delivery'] ?? {};
    final pricing = order['pricing'] ?? {};
    final status = order['status'] ?? 'pending';
    final items = order['items'] as List? ?? [];
    final timestamps = order['timestamps'] ?? {};
    final createdAt = timestamps['created'] as Timestamp?;

    // Get user info if userId exists
    final userId = order['userId'] ?? customer['userId'];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showOrderDetails(orderId, order),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with Status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              'طلب #${orderId.substring(0, min(8, orderId.length))}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
            ),

            // Customer Info Section
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer Details Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.person,
                          'العميل',
                          customer['name'] ?? 'غير معروف',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.phone,
                          'الهاتف',
                          customer['phone'] ?? 'غير محدد',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Email and User Type
                  if (customer['email'] != null || userId != null)
                    Row(
                      children: [
                        if (customer['email'] != null)
                          Expanded(
                            child: _buildInfoItem(
                              Icons.email,
                              'البريد',
                              customer['email'],
                            ),
                          ),
                        if (userId != null)
                          Expanded(
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                                  return _buildInfoItem(
                                    Icons.account_circle,
                                    'نوع العميل',
                                    _getUserTypeLabel(userData['userType'] ?? 'public'),
                                  );
                                }
                                return _buildInfoItem(
                                  Icons.account_circle,
                                  'الحساب',
                                  'مسجل',
                                );
                              },
                            ),
                          ),
                      ],
                    ),

                  SizedBox(height: 12),

                  // Order Summary
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('المنتجات', '${items.length}'),
                        _buildSummaryItem('الإجمالي', '${pricing['total'] ?? 0} د.ع'),
                        _buildSummaryItem('التوصيل', delivery['address'] != null ? 'محدد' : 'غير محدد'),
                      ],
                    ),
                  ),

                  // Action Buttons
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(orderId, status),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showOrderDetails(orderId, order),
                          icon: Icon(Icons.visibility, size: 18),
                          label: Text('التفاصيل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
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
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActionButton(String orderId, String status) {
    switch (status) {
      case 'pending':
        return ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(orderId, 'processing'),
          icon: Icon(Icons.check, size: 18),
          label: Text('قبول'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        );
      case 'processing':
        return ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(orderId, 'shipped'),
          icon: Icon(Icons.local_shipping, size: 18),
          label: Text('شحن'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        );
      case 'shipped':
        return ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(orderId, 'delivered'),
          icon: Icon(Icons.done_all, size: 18),
          label: Text('تسليم'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        );
      default:
        return ElevatedButton.icon(
          onPressed: null,
          icon: Icon(Icons.check_circle, size: 18),
          label: Text('مكتمل'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد التحضير';
      case 'shipped':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case 'wholesale':
        return 'تاجر جملة';
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

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'timestamps.updated': FieldValue.serverTimestamp(),
        'timestamps.$newStatus': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة الطلب')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> orderData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderId: orderId,
          orderData: orderData,
        ),
      ),
    );
  }
}