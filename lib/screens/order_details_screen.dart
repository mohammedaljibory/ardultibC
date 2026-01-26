// screens/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
    required this.orderData,
  }) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Map<String, dynamic> _orderData;

  @override
  void initState() {
    super.initState();
    _orderData = widget.orderData;
  }

  @override
  Widget build(BuildContext context) {
    final customer = _orderData['customer'] ?? {};
    final delivery = _orderData['delivery'] ?? {};
    final pricing = _orderData['pricing'] ?? {};
    final items = _orderData['items'] as List? ?? [];
    final userId = _orderData['userId'] ?? customer['userId'];

    return Scaffold(
      appBar: AppBar(
        title: Text('طلب #${widget.orderId.substring(0, 8)}'),
        backgroundColor: Color(0xFF6A11CB),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'print') {
                _printOrder();
              } else if (value == 'cancel') {
                _cancelOrder();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'print', child: Text('طباعة')),
              PopupMenuItem(value: 'cancel', child: Text('إلغاء الطلب')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            _buildStatusCard(),
            SizedBox(height: 16),

            // Customer Information Card
            _buildCustomerCard(customer, userId),
            SizedBox(height: 16),

            // Delivery Information Card
            _buildDeliveryCard(delivery),
            SizedBox(height: 16),

            // Order Items Card
            _buildItemsCard(items),
            SizedBox(height: 16),

            // Pricing Summary Card
            _buildPricingCard(pricing),
            SizedBox(height: 16),

            // Status Timeline
            _buildTimelineCard(),
            SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _orderData['status'] ?? 'pending';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor(status).withOpacity(0.1),
              _getStatusColor(status).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة الطلب',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, String? userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Color(0xFF6A11CB)),
                SizedBox(width: 8),
                Text(
                  'معلومات العميل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('الاسم', customer['name'] ?? 'غير محدد'),
            _buildInfoRow('الهاتف', customer['phone'] ?? 'غير محدد'),
            if (customer['email'] != null)
              _buildInfoRow('البريد', customer['email']),
            if (userId != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        _buildInfoRow('نوع العميل', _getUserTypeLabel(userData['userType'] ?? 'public')),
                        _buildInfoRow('معرف المستخدم', userId.substring(0, 10) + '...'),
                      ],
                    );
                  }
                  return _buildInfoRow('الحساب', 'عميل مسجل');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Color(0xFF6A11CB)),
                SizedBox(width: 8),
                Text(
                  'معلومات التوصيل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('العنوان', delivery['address'] ?? 'غير محدد'),
            if (delivery['deliveryDate'] != null)
              _buildInfoRow('تاريخ التوصيل', delivery['deliveryDate']),
            if (delivery['deliveryTime'] != null)
              _buildInfoRow('وقت التوصيل', delivery['deliveryTime']),
            if (delivery['deliveryNotes'] != null && delivery['deliveryNotes'].toString().isNotEmpty)
              _buildInfoRow('ملاحظات', delivery['deliveryNotes']),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(List items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Color(0xFF6A11CB)),
                SizedBox(width: 8),
                Text(
                  'المنتجات (${items.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24),
            ...items.map((item) => _buildItemRow(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final productId = item['productId'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: productId.isNotEmpty && productId != 'item_1'
          ? FirebaseFirestore.instance.collection('items1').doc(productId).get()
          : Future.value(null),
      builder: (context, snapshot) {
        String thumbnailUrl = '';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final productData = snapshot.data!.data() as Map<String, dynamic>;
          thumbnailUrl = productData['thumbnail'] ?? '';
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image_not_supported, color: Colors.grey);
                    },
                  ),
                )
                    : Icon(Icons.inventory_2, color: Colors.grey),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'] ?? 'منتج غير معروف',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'الكمية: ${item['quantity']} | السعر: ${item['unitPrice']} د.ع',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${item['totalPrice']} د.ع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> pricing) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Color(0xFF6A11CB)),
                SizedBox(width: 8),
                Text(
                  'ملخص الفاتورة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24),
            _buildPriceRow('المجموع الفرعي', pricing['subtotal'] ?? 0),
            _buildPriceRow('رسوم التوصيل', pricing['shipping'] ?? 0),
            _buildPriceRow('الخصم', pricing['discount'] ?? 0),
            _buildPriceRow('الضريبة', pricing['tax'] ?? 0),
            Divider(height: 16),
            _buildPriceRow(
              'الإجمالي',
              pricing['total'] ?? 0,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    final timestamps = _orderData['timestamps'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Color(0xFF6A11CB)),
                SizedBox(width: 8),
                Text(
                  'تاريخ الطلب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24),
            if (timestamps['created'] != null)
              _buildTimelineItem('تم الإنشاء', timestamps['created']),
            if (timestamps['processing'] != null)
              _buildTimelineItem('بدء التحضير', timestamps['processing']),
            if (timestamps['shipped'] != null)
              _buildTimelineItem('تم الشحن', timestamps['shipped']),
            if (timestamps['delivered'] != null)
              _buildTimelineItem('تم التسليم', timestamps['delivered']),
            if (timestamps['cancelled'] != null)
              _buildTimelineItem('تم الإلغاء', timestamps['cancelled']),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String label, Timestamp timestamp) {
    final date = timestamp.toDate();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Color(0xFF6A11CB)),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Spacer(),
          Text(
            DateFormat('yyyy/MM/dd - HH:mm').format(date),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _orderData['status'] ?? 'pending';

    return Row(
      children: [
        if (status != 'delivered' && status != 'cancelled')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(_getNextStatus(status)),
              icon: Icon(Icons.arrow_forward),
              label: Text(_getNextStatusLabel(status)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A11CB),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (status != 'delivered' && status != 'cancelled') ...[
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelOrder,
              icon: Icon(Icons.cancel),
              label: Text('إلغاء الطلب'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, dynamic value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Spacer(),
          Text(
            '$value د.ع',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Color(0xFF6A11CB) : null,
            ),
          ),
        ],
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.restaurant;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
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

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'processing';
      case 'processing':
        return 'shipped';
      case 'shipped':
        return 'delivered';
      default:
        return currentStatus;
    }
  }

  String _getNextStatusLabel(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'بدء التحضير';
      case 'processing':
        return 'بدء الشحن';
      case 'shipped':
        return 'تأكيد التسليم';
      default:
        return 'تحديث';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': newStatus,
        'timestamps.updated': FieldValue.serverTimestamp(),
        'timestamps.$newStatus': FieldValue.serverTimestamp(),
      });

      setState(() {
        _orderData['status'] = newStatus;
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

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الإلغاء'),
        content: Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('نعم', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus('cancelled');
    }
  }

  void _printOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري طباعة الطلب...')),
    );
  }
}