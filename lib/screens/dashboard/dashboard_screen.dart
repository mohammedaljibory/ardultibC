import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../orders/order_management_screen.dart';
import '../users/users_management_screen.dart';
import '../products/products_management_screen.dart';
import '../settings/settings_screen.dart';
import '../image_control_screen.dart';
import '../banner_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded, 'الرئيسية'),
    _NavItem(Icons.receipt_long_rounded, 'الطلبات'),
    _NavItem(Icons.inventory_2_rounded, 'المنتجات'),
    _NavItem(Icons.group_rounded, 'العملاء'),
    _NavItem(Icons.photo_library_rounded, 'البانرات'),
    _NavItem(Icons.collections_rounded, 'المعرض'),
    _NavItem(Icons.settings_rounded, 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(isWide),

          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isWide) {
    return Container(
      width: isWide ? 220 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
                ),
                if (isWide) ...[
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أرض الطب',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Navigation
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: isSelected ? Color(0xFF667eea).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        height: 44,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? Color(0xFF667eea) : Colors.grey[600],
                            ),
                            if (isWide) ...[
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Color(0xFF667eea) : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // User & Logout
          Padding(
            padding: EdgeInsets.all(8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _showLogoutDialog,
                child: Container(
                  height: 44,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: Colors.red[400]),
                      if (isWide) ...[
                        SizedBox(width: 12),
                        Text(
                          'خروج',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _HomePage();
      case 1:
        return OrdersManagementScreen();
      case 2:
        return ProductsManagementScreen();
      case 3:
        return UsersManagementScreen();
      case 4:
        return BannerManagementScreen();
      case 5:
        return ImageControlScreen();
      case 6:
        return SettingsScreen();
      default:
        return _HomePage();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('تسجيل الخروج', style: TextStyle(fontSize: 16)),
        content: Text('هل تريد تسجيل الخروج؟', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: Text('خروج', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}

// Home Page
class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'نظرة عامة على متجرك',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Spacer(),
                _buildNotificationButton(context),
              ],
            ),
            SizedBox(height: 20),

            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 45) / 4
                    : constraints.maxWidth > 600
                        ? (constraints.maxWidth - 15) / 2
                        : constraints.maxWidth;

                return Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.receipt_long_rounded,
                      label: 'طلبات جديدة',
                      color: Color(0xFF667eea),
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.inventory_2_rounded,
                      label: 'المنتجات',
                      color: Color(0xFF11998e),
                      stream: FirebaseFirestore.instance.collection('items1').snapshots(),
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.group_rounded,
                      label: 'العملاء',
                      color: Color(0xFFf77062),
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.check_circle_rounded,
                      label: 'طلبات مكتملة',
                      color: Color(0xFF38ef7d),
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('status', isEqualTo: 'delivered')
                          .snapshots(),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),

            // Recent Orders
            _SectionHeader(title: 'آخر الطلبات'),
            SizedBox(height: 12),
            _RecentOrdersList(),

            SizedBox(height: 24),

            // Low Stock Products
            _SectionHeader(title: 'منتجات قليلة المخزون'),
            SizedBox(height: 12),
            _LowStockList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.notifications_none_rounded, color: Colors.grey[700], size: 20),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1a1a2e),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data?.docs.length ?? 0}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a2e),
                      ),
                    );
                  },
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamps.created', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('لا توجد طلبات', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final customer = data['customer'] ?? {};
              final status = data['status'] ?? 'pending';
              final pricing = data['pricing'] ?? {};

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: _buildStatusDot(status),
                title: Text(
                  customer['name'] ?? 'عميل',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '#${orders[index].id.substring(0, 8)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                trailing: Text(
                  '${pricing['total'] ?? 0} د.ع',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF667eea)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'processing': color = Colors.blue; break;
      case 'shipped': color = Colors.purple; break;
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LowStockList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items1')
            .where('Number', isLessThan: 10)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('جميع المنتجات متوفرة', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final stock = data['Number'] ?? 0;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: data['thumbnail'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(data['thumbnail'], fit: BoxFit.cover),
                        )
                      : Icon(Icons.image, color: Colors.grey[400], size: 18),
                ),
                title: Text(
                  data['name'] ?? 'منتج',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stock == 0 ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stock == 0 ? 'نفذ' : '$stock متبقي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: stock == 0 ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
