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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardHome(),
    OrdersManagementScreen(),
    ProductsManagementScreen(),
    UsersManagementScreen(),
    BannerManagementScreen(),
    ImageControlScreen(),
    SettingsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.dashboard, 'الرئيسية', Color(0xFF1976D2)),
    NavigationItem(Icons.shopping_cart, 'الطلبات', Color(0xFF388E3C)),
    NavigationItem(Icons.inventory, 'المنتجات', Color(0xFFE64A19)),
    NavigationItem(Icons.people, 'المستخدمين', Color(0xFF7B1FA2)),
    NavigationItem(Icons.view_carousel, 'البانرات', Color(0xFFE91E63)),
    NavigationItem(Icons.image, 'الصور', Color(0xFF0097A7)),
    NavigationItem(Icons.settings, 'الإعدادات', Color(0xFF616161)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? _buildDrawer() : null,
      body: Row(
        children: [
          // Desktop Side Navigation
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: _buildSideNavigation(false), // false for desktop (don't close)
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // App Bar for mobile
                if (!isDesktop)
                  AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0 ,
                    leading: IconButton(
                      icon: Icon(Icons.menu, color: Colors.black87),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    title: Text(
                      _navigationItems[_selectedIndex].label,
                      style: TextStyle(color: Colors.black87),
                    ),
                    actions: [
                      _buildNotificationButton(),
                      SizedBox(width: 16),
                    ],
                  ),

                // Content - Remove Expanded wrapper
                if (isDesktop)
                  Expanded(child: _screens[_selectedIndex])
                else
                  Expanded(
                    child: _screens[_selectedIndex],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(bool shouldCloseDrawer) {
    return Column(
      children: [
        // Logo and User Info
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: Color(0xFF2196F3),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'لوحة تحكم أرض الطب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data?.email ?? 'admin@medicalland.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: _navigationItems.length,
            itemBuilder: (context, index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
                ),
                child: ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? item.color : Colors.grey[600],
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? item.color : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  )
                      : null,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    // Close drawer on mobile after selection
                    if (shouldCloseDrawer && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),

        Divider(height: 1),

        // Logout Button
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text(
            'تسجيل الخروج',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {
            // Close drawer first if open
            if (shouldCloseDrawer && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            _showLogoutDialog();
          },
        ),

        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: _buildSideNavigation(true), // true for mobile (should close)
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () => _showNotifications(context),
          );
        }
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.black87),
              onPressed: () => _showNotifications(context),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('تسجيل الخروج'),
          ],
        ),
        content: Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NotificationsDialog(),
    );
  }
}

// Keep NavigationItem and other classes as they were...
class NavigationItem {
  final IconData icon;
  final String label;
  final Color color;

  NavigationItem(this.icon, this.label, this.color);
}

// Keep the DashboardHome widget as is
class DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التحكم'),
        backgroundColor: Colors.white,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_notifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => _showNotifications(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً بك في لوحة التحكم',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'نظرة عامة على متجرك',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width > 1200 ? 1.5 : 1.3,
                children: [
                  _buildStatCard(
                    'الطلبات الجديدة',
                    Icons.shopping_cart,
                    Colors.blue,
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                  ),
                  _buildStatCard(
                    'إجمالي المنتجات',
                    Icons.inventory,
                    Colors.green,
                    FirebaseFirestore.instance.collection('items1').snapshots(),
                  ),
                  _buildStatCard(
                    'المستخدمين',
                    Icons.people,
                    Colors.orange,
                    FirebaseFirestore.instance.collection('users').snapshots(),
                  ),
                  _buildStatCard(
                    'الإيرادات اليوم',
                    Icons.attach_money,
                    Colors.purple,
                    null,
                    customValue: '0 د.ع',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      IconData icon,
      Color color,
      Stream<QuerySnapshot>? stream, {
        String? customValue,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 8),
            if (stream != null)
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              )
            else
              Text(
                customValue ?? '0',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NotificationsDialog(),
    );
  }
}

// NotificationsDialog remains the same
class NotificationsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإشعارات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admin_notifications')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data!.docs;

                  if (notifications.isEmpty) {
                    return Center(
                      child: Text('لا توجد إشعارات'),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index].data() as Map<String, dynamic>;
                      final isRead = notification['read'] ?? false;

                      return Card(
                        color: isRead ? null : Colors.blue[50],
                        child: ListTile(
                          leading: Icon(
                            _getNotificationIcon(notification['type']),
                            color: _getNotificationColor(notification['type']),
                          ),
                          title: Text(notification['message'] ?? ''),
                          subtitle: Text(
                            _formatTimestamp(notification['timestamp']),
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: !isRead
                              ? TextButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('admin_notifications')
                                  .doc(notifications[index].id)
                                  .update({'read': true});
                            },
                            child: Text('قراءة'),
                          )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'low_stock':
        return Icons.warning;
      case 'new_user':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'new_order':
        return Colors.blue;
      case 'low_stock':
        return Colors.orange;
      case 'new_user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}