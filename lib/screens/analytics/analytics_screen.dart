import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'week';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التحليلات والتقارير'),
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange(value);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'today', child: Text('اليوم')),
              PopupMenuItem(value: 'week', child: Text('هذا الأسبوع')),
              PopupMenuItem(value: 'month', child: Text('هذا الشهر')),
              PopupMenuItem(value: 'year', child: Text('هذه السنة')),
              PopupMenuItem(value: 'custom', child: Text('تخصيص')),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(_getPeriodLabel(), style: TextStyle(color: Colors.black87)),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(),
            SizedBox(height: 32),

            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSalesChart(),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: _buildTopProductsChart(),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Additional Charts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildOrderStatusChart(),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: _buildUserTypesChart(),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Top Customers Table
            _buildTopCustomersTable(),
            SizedBox(height: 32),

            // Recent Activities
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'week':
        _startDate = now.subtract(Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'custom':
        _selectCustomDateRange();
        break;
    }
  }

  void _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'آخر 7 أيام';
      case 'month':
        return 'هذا الشهر';
      case 'year':
        return 'هذه السنة';
      case 'custom':
        return '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}';
      default:
        return 'اختر الفترة';
    }
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('timestamps.created', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('timestamps.created', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .snapshots(),
      builder: (context, snapshot) {
        final orders = snapshot.data?.docs ?? [];

        // Calculate statistics
        double totalRevenue = 0;
        int totalOrders = orders.length;
        int completedOrders = 0;
        int pendingOrders = 0;

        for (var order in orders) {
          final data = order.data() as Map<String, dynamic>;
          final pricing = data['pricing'] ?? {};
          totalRevenue += (pricing['total'] ?? 0).toDouble();

          if (data['status'] == 'delivered') completedOrders++;
          if (data['status'] == 'pending') pendingOrders++;
        }

        double averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              'إجمالي الإيرادات',
              '${totalRevenue.toStringAsFixed(0)} د.ع',
              Icons.attach_money,
              Colors.green,
              '+12%',
            ),
            _buildStatCard(
              'عدد الطلبات',
              totalOrders.toString(),
              Icons.shopping_cart,
              Colors.blue,
              '+8%',
            ),
            _buildStatCard(
              'متوسط قيمة الطلب',
              '${averageOrderValue.toStringAsFixed(0)} د.ع',
              Icons.analytics,
              Colors.purple,
              '+5%',
            ),
            _buildStatCard(
              'معدل الإنجاز',
              '${totalOrders > 0 ? (completedOrders * 100 / totalOrders).toStringAsFixed(0) : 0}%',
              Icons.check_circle,
              Colors.orange,
              '+3%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المبيعات اليومية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
                        return Text(
                          days[value.toInt() % 7],
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 50,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 15),
                      FlSpot(1, 25),
                      FlSpot(2, 20),
                      FlSpot(3, 35),
                      FlSpot(4, 30),
                      FlSpot(5, 45),
                      FlSpot(6, 40),
                    ],
                    isCurved: true,
                    color: Color(0xFF2196F3),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Color(0xFF2196F3).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsChart() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المنتجات الأكثر مبيعاً',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue,
                    value: 35,
                    title: '35%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.green,
                    value: 25,
                    title: '25%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: 20,
                    title: '20%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.purple,
                    value: 20,
                    title: '20%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          // Legend
          Column(
            children: [
              _buildLegendItem('منتج 1', Colors.blue, '35%'),
              _buildLegendItem('منتج 2', Colors.green, '25%'),
              _buildLegendItem('منتج 3', Colors.orange, '20%'),
              _buildLegendItem('أخرى', Colors.purple, '20%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14))),
          Text(percentage, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return Container(
      padding: EdgeInsets.all(24),
      height: 400,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة الطلبات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final titles = ['معلق', 'قيد التحضير', 'قيد التوصيل', 'مكتمل', 'ملغي'];
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(toY: 30, color: Colors.orange, width: 30),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(toY: 45, color: Colors.blue, width: 30),
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(toY: 25, color: Colors.purple, width: 30),
                  ]),
                  BarChartGroupData(x: 3, barRods: [
                    BarChartRodData(toY: 80, color: Colors.green, width: 30),
                  ]),
                  BarChartGroupData(x: 4, barRods: [
                    BarChartRodData(toY: 10, color: Colors.red, width: 30),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypesChart() {
    return Container(
      padding: EdgeInsets.all(24),
      height: 400,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أنواع المستخدمين',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;
              Map<String, int> userTypes = {
                'public': 0,
                'wholesale': 0,
                'vip': 0,
                'special': 0,
              };

              for (var user in users) {
                final data = user.data() as Map<String, dynamic>;
                final type = data['userType'] ?? 'public';
                userTypes[type] = (userTypes[type] ?? 0) + 1;
              }

              return Column(
                children: [
                  _buildUserTypeRow('عام', userTypes['public']!, Colors.grey),
                  _buildUserTypeRow('جملة', userTypes['wholesale']!, Colors.blue),
                  _buildUserTypeRow('VIP', userTypes['vip']!, Colors.purple),
                  _buildUserTypeRow('خاص', userTypes['special']!, Colors.orange),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeRow(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: count / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomersTable() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أفضل العملاء',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Table(
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              _buildCustomerRow('أحمد محمد', 25, 125000, 'VIP'),
              _buildCustomerRow('علي حسين', 18, 95000, 'جملة'),
              _buildCustomerRow('فاطمة علي', 15, 75000, 'عام'),
              _buildCustomerRow('حسن كريم', 12, 60000, 'خاص'),
              _buildCustomerRow('زينب أحمد', 10, 50000, 'عام'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildCustomerRow(String name, int orders, int amount, String type) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(name),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(orders.toString()),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: Text('${amount} د.ع'),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getUserTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: _getUserTypeColor(type),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getUserTypeColor(String type) {
    switch (type) {
      case 'VIP':
        return Colors.purple;
      case 'جملة':
        return Colors.blue;
      case 'خاص':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentActivities() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النشاطات الأخيرة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          _buildActivityItem(
            Icons.shopping_cart,
            'طلب جديد #12345',
            'منذ 5 دقائق',
            Colors.blue,
          ),
          _buildActivityItem(
            Icons.person_add,
            'مستخدم جديد: أحمد علي',
            'منذ 15 دقيقة',
            Colors.green,
          ),
          _buildActivityItem(
            Icons.inventory,
            'تم تحديث منتج: اسم المنتج',
            'منذ ساعة',
            Colors.orange,
          ),
          _buildActivityItem(
            Icons.check_circle,
            'تم تسليم الطلب #12340',
            'منذ ساعتين',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String time, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}