import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;

import '../order_details_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  @override
  _OrdersManagementScreenState createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'orderNumber';

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
          // Header
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'إدارة الطلبات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                      ),
                    ),
                    Spacer(),
                    _buildOrderStats(),
                  ],
                ),
                SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(),
                SizedBox(height: 12),

                // Filter Chips
                _buildFilterChips(),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF667eea),
                    ),
                  );
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
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    return _buildOrderCard(order.id, orderData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '$count طلب جديد',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: Row(
        children: [
          // Search Type Dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: DropdownButton<String>(
              value: _searchType,
              underline: SizedBox(),
              icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              items: [
                DropdownMenuItem(value: 'orderNumber', child: Text('رقم الطلب')),
                DropdownMenuItem(value: 'phone', child: Text('الهاتف')),
                DropdownMenuItem(value: 'email', child: Text('البريد')),
                DropdownMenuItem(value: 'userName', child: Text('الاسم')),
              ],
              onChanged: (value) {
                setState(() => _searchType = value!);
              },
            ),
          ),
          // Search Input
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('all', 'الكل', null),
          SizedBox(width: 8),
          _buildChip('pending', 'قيد الانتظار', Colors.orange),
          SizedBox(width: 8),
          _buildChip('processing', 'قيد التحضير', Colors.blue),
          SizedBox(width: 8),
          _buildChip('shipped', 'قيد التوصيل', Colors.purple),
          SizedBox(width: 8),
          _buildChip('delivered', 'تم التسليم', Colors.green),
          SizedBox(width: 8),
          _buildChip('cancelled', 'ملغي', Colors.red),
        ],
      ),
    );
  }

  Widget _buildChip(String value, String label, Color? color) {
    final isSelected = _filterStatus == value;
    final chipColor = color ?? Color(0xFF667eea);

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? chipColor.withOpacity(0.3) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? chipColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
          SizedBox(height: 12),
          Text(
            'لا توجد طلبات',
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

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance.collection('orders');

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return query.orderBy('timestamps.created', descending: true).snapshots();
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order) {
    final customer = order['customer'] ?? {};
    final pricing = order['pricing'] ?? {};
    final status = order['status'] ?? 'pending';
    final items = order['items'] as List? ?? [];
    final timestamps = order['timestamps'] ?? {};
    final createdAt = timestamps['created'] as Timestamp?;

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showOrderDetails(orderId, order),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Order ID & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${orderId.substring(0, min(8, orderId.length))}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                          SizedBox(height: 2),
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),

                SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[100]),
                SizedBox(height: 12),

                // Customer & Order Info
                Row(
                  children: [
                    // Customer
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFF667eea).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person_outline, size: 16, color: Color(0xFF667eea)),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer['name'] ?? 'عميل',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  customer['phone'] ?? '',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order Summary
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '${items.length}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '${pricing['total'] ?? 0} د.ع',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667eea),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(child: _buildActionButton(orderId, status)),
                    SizedBox(width: 8),
                    _buildDetailsButton(orderId, order),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(String orderId, String status) {
    IconData icon;
    String label;
    Color color;
    String? nextStatus;

    switch (status) {
      case 'pending':
        icon = Icons.check_rounded;
        label = 'قبول الطلب';
        color = Colors.blue;
        nextStatus = 'processing';
        break;
      case 'processing':
        icon = Icons.local_shipping_rounded;
        label = 'بدء الشحن';
        color = Colors.orange;
        nextStatus = 'shipped';
        break;
      case 'shipped':
        icon = Icons.done_all_rounded;
        label = 'تم التسليم';
        color = Colors.green;
        nextStatus = 'delivered';
        break;
      default:
        icon = Icons.check_circle_outline;
        label = 'مكتمل';
        color = Colors.grey;
        nextStatus = null;
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: nextStatus != null ? () => _updateOrderStatus(orderId, nextStatus!) : null,
        icon: Icon(icon, size: 16),
        label: Text(label, style: TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[200],
          disabledForegroundColor: Colors.grey[500],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDetailsButton(String orderId, Map<String, dynamic> order) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: () => _showOrderDetails(orderId, order),
        child: Icon(Icons.arrow_forward_ios, size: 14),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[600],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
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

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الطلب', style: TextStyle(fontSize: 13)),
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
