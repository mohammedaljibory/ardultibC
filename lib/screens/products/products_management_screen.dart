import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../edit_product_screen.dart';

class ProductsManagementScreen extends StatefulWidget {
  @override
  _ProductsManagementScreenState createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = 'all';
  String _filterStock = 'all';
  bool _showHidden = false;
  List<String> categories = ['all'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .get();

      List<String> loadedCategories = ['all'];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String categoryName = data['nameAr'] ?? data['nameEn'] ?? '';
        if (categoryName.isNotEmpty) {
          loadedCategories.add(categoryName);
        }
      }

      setState(() {
        categories = loadedCategories;
      });
    } catch (e) {
      // Error loading categories - continue with empty list
    }
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
                          'إدارة المنتجات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a2e),
                          ),
                        ),
                        SizedBox(height: 2),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('items1').snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.docs.length ?? 0;
                            return Text(
                              '$count منتج',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            );
                          },
                        ),
                      ],
                    ),
                    Spacer(),
                    _buildAddButton(),
                  ],
                ),
                SizedBox(height: 16),

                // Stats Cards
                _buildStatsRow(),
                SizedBox(height: 16),

                // Search & Filters
                _buildSearchAndFilters(),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items1').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF667eea),
                    ),
                  );
                }

                var products = snapshot.data!.docs;

                // Apply filters
                products = products.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Search filter
                  if (_searchController.text.isNotEmpty) {
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    if (!name.contains(_searchController.text.toLowerCase())) {
                      return false;
                    }
                  }

                  // Category filter
                  if (_filterCategory != 'all' && data['category'] != _filterCategory) {
                    return false;
                  }

                  // Stock filter
                  final stock = data['Number'] ?? 0;
                  if (_filterStock == 'in_stock' && stock <= 0) return false;
                  if (_filterStock == 'low_stock' && (stock <= 0 || stock > 5)) return false;
                  if (_filterStock == 'out_of_stock' && stock > 0) return false;

                  // Hidden filter
                  if (!_showHidden && data['hidden'] == true) return false;

                  return true;
                }).toList();

                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 :
                                   MediaQuery.of(context).size.width > 800 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>;
                    return _buildProductCard(product.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: _showAddProductDialog,
        icon: Icon(Icons.add, size: 18),
        label: Text('إضافة منتج', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF667eea),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items1').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(height: 60);

        final products = snapshot.data!.docs;
        final hiddenProducts = products.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['hidden'] == true;
        }).length;
        final outOfStock = products.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['Number'] ?? 0) == 0;
        }).length;
        final lowStock = products.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final stock = data['Number'] ?? 0;
          return stock > 0 && stock <= 5;
        }).length;

        return Row(
          children: [
            Expanded(child: _buildStatChip('مخفي', hiddenProducts, Colors.orange)),
            SizedBox(width: 8),
            Expanded(child: _buildStatChip('نفذ', outOfStock, Colors.red)),
            SizedBox(width: 8),
            Expanded(child: _buildStatChip('منخفض', lowStock, Colors.amber[700]!)),
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

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Bar
        Container(
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
              hintText: 'بحث عن منتج...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        SizedBox(height: 12),

        // Filter Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Category Filter
              _buildDropdownFilter(
                value: _filterCategory,
                items: categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c == 'all' ? 'كل التصنيفات' : c, style: TextStyle(fontSize: 11)),
                )).toList(),
                onChanged: (v) => setState(() => _filterCategory = v!),
                icon: Icons.category_outlined,
              ),
              SizedBox(width: 8),

              // Stock Filter
              _buildDropdownFilter(
                value: _filterStock,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('كل المخزون', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'in_stock', child: Text('متوفر', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'low_stock', child: Text('منخفض', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'out_of_stock', child: Text('نفذ', style: TextStyle(fontSize: 11))),
                ],
                onChanged: (v) => setState(() => _filterStock = v!),
                icon: Icons.inventory_outlined,
              ),
              SizedBox(width: 8),

              // Show Hidden Toggle
              GestureDetector(
                onTap: () => setState(() => _showHidden = !_showHidden),
                child: Container(
                  height: 36,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _showHidden ? Color(0xFF667eea).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showHidden ? Color(0xFF667eea).withOpacity(0.3) : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showHidden ? Icons.visibility : Icons.visibility_off_outlined,
                        size: 16,
                        color: _showHidden ? Color(0xFF667eea) : Colors.grey[600],
                      ),
                      SizedBox(width: 6),
                      Text(
                        'المخفي',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _showHidden ? FontWeight.w600 : FontWeight.w500,
                          color: _showHidden ? Color(0xFF667eea) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 6),
          DropdownButton<String>(
            value: value,
            underline: SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
          SizedBox(height: 12),
          Text(
            'لا توجد منتجات',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    final stock = data['Number'] ?? 0;
    final isHidden = data['hidden'] ?? false;
    final price = data['SalePrice1'] ?? 0;
    final currency = data['SaleCurrencyId'] == 2 ? '\$' : 'د.ع';

    Color stockColor = Color(0xFF38ef7d);
    if (stock == 0) {
      stockColor = Colors.red;
    } else if (stock <= 5) {
      stockColor = Colors.orange;
    }

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
          onTap: () => _editProduct(productId, data),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (data['thumbnail'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            data['thumbnail'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF667eea),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.image_not_supported, size: 24, color: Colors.grey[400]),
                            ),
                          ),
                        )
                      else
                        Center(child: Icon(Icons.image_outlined, size: 28, color: Colors.grey[400])),

                      // Status Badges
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Row(
                          children: [
                            if (isHidden)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'مخفي',
                                  style: TextStyle(color: Colors.white, fontSize: 9),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Stock Indicator
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: stockColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'بدون اسم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1a2e),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      if (data['category'] != null)
                        Text(
                          data['category'],
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$price $currency',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF667eea),
                            ),
                          ),
                          Text(
                            stock == 0 ? 'نفذ' : '$stock',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                height: 36,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[100]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _editProduct(productId, data),
                        child: Center(
                          child: Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                        ),
                      ),
                    ),
                    Container(width: 1, color: Colors.grey[100]),
                    Expanded(
                      child: InkWell(
                        onTap: () => _toggleHideProduct(productId, !isHidden),
                        child: Center(
                          child: Icon(
                            isHidden ? Icons.visibility : Icons.visibility_off_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: Colors.grey[100]),
                    Expanded(
                      child: InkWell(
                        onTap: () => _deleteProduct(productId, data['name']),
                        child: Center(
                          child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProduct(String productId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          productId: productId,
          productData: data,
        ),
      ),
    );
  }

  Future<void> _toggleHideProduct(String productId, bool hide) async {
    try {
      await FirebaseFirestore.instance
          .collection('items1')
          .doc(productId)
          .update({'hidden': hide});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hide ? 'تم إخفاء المنتج' : 'تم إظهار المنتج',
              style: TextStyle(fontSize: 13),
            ),
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

  void _deleteProduct(String productId, String? productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('تأكيد الحذف', style: TextStyle(fontSize: 16)),
        content: Text(
          'هل أنت متأكد من حذف "${productName ?? ''}"؟',
          style: TextStyle(fontSize: 14),
        ),
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
                    .collection('items1')
                    .doc(productId)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف المنتج', style: TextStyle(fontSize: 13)),
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

  void _showAddProductDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ميزة إضافة المنتج قيد التطوير', style: TextStyle(fontSize: 13)),
        backgroundColor: Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
