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
      print('Error loading categories: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          // Statistics Cards - FIXED VERSION
          Container(
            height: 100, // Reduced height from 120
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items1').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();

                final products = snapshot.data!.docs;
                final totalProducts = products.length;
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

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
                  children: [
                    _buildStatCard('إجمالي المنتجات', totalProducts.toString(), Colors.blue, Icons.inventory),
                    _buildStatCard('منتجات مخفية', hiddenProducts.toString(), Colors.orange, Icons.visibility_off),
                    _buildStatCard('نفذ المخزون', outOfStock.toString(), Colors.red, Icons.remove_shopping_cart),
                    _buildStatCard('مخزون منخفض', lowStock.toString(), Colors.amber, Icons.warning),
                  ],
                );
              },
            ),
          ),

          // Filters
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث عن منتج...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddProductDialog,
                      icon: Icon(Icons.add),
                      label: Text('إضافة منتج'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filterCategory,
                          underline: SizedBox(),
                          hint: Text('التصنيف'),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category == 'all' ? 'جميع التصنيفات' : category),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _filterCategory = value!),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filterStock,
                          underline: SizedBox(),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('جميع المنتجات')),
                            DropdownMenuItem(value: 'in_stock', child: Text('متوفر')),
                            DropdownMenuItem(value: 'low_stock', child: Text('مخزون منخفض')),
                            DropdownMenuItem(value: 'out_of_stock', child: Text('نفذ المخزون')),
                          ],
                          onChanged: (value) => setState(() => _filterStock = value!),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    FilterChip(
                      label: Text('إظهار المخفي'),
                      selected: _showHidden,
                      onSelected: (value) => setState(() => _showHidden = value),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items1').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text('لا توجد منتجات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Changed to 1.0 for square-ish cards
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

  // FIXED Statistics Card Widget
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 180, // Reduced width from 200
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12), // Reduced padding from 16
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
      child: Row( // Changed to Row instead of Column for better space usage
        children: [
          Container(
            padding: EdgeInsets.all(8), // Reduced padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24), // Reduced icon size from 32
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11, // Reduced from 14
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Product Card Widget - Already fixed
  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    final stock = data['Number'] ?? 0;
    final isHidden = data['hidden'] ?? false;
    final price = data['SalePrice1'] ?? 0;
    final currency = data['SaleCurrencyId'] == 2 ? '\$' : 'د.ع';

    Color stockColor = Colors.green;
    String stockText = 'متوفر ($stock)';

    if (stock == 0) {
      stockColor = Colors.red;
      stockText = 'نفذ المخزون';
    } else if (stock <= 5) {
      stockColor = Colors.orange;
      stockText = 'مخزون منخفض ($stock)';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Add this to clip content
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProductScreen(
                productId: productId,
                productData: data,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder( // Add LayoutBuilder to get constraints
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image - Use proportional height
                Container(
                  height: constraints.maxHeight * 0.4, // 40% of card height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (data['thumbnail'] != null)
                        Image.network(
                          data['thumbnail'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                            );
                          },
                        )
                      else
                        Center(
                          child: Icon(Icons.image_outlined, size: 30, color: Colors.grey),
                        ),

                      // Status Badge
                      if (isHidden)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
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
                        ),
                    ],
                  ),
                ),

                // Product Info - Use remaining space
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(6), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          data['name'] ?? 'بدون اسم',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reduced font size
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Category
                        if (data['category'] != null)
                          Text(
                            data['category'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Spacer(), // Push price to bottom
                        // Price and Stock
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 1,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$price $currency',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 2),
                            Flexible(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: stockColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    stockText,
                                    style: TextStyle(
                                      color: stockColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions - Fixed height
                Container(
                  height: 35, // Reduced height
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 16),
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        onPressed: () => _editProduct(productId, data),
                      ),
                      IconButton(
                        icon: Icon(
                          isHidden ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                        ),
                        color: Colors.orange,
                        padding: EdgeInsets.zero,
                        onPressed: () => _toggleHideProduct(productId, !isHidden),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 16),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        onPressed: () => _deleteProduct(productId, data['name']),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hide ? 'تم إخفاء المنتج' : 'تم إظهار المنتج')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteProduct(String productId, String? productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${productName ?? ''}"؟'),
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
                    .collection('items1')
                    .doc(productId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف المنتج بنجاح')),
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

  void _showAddProductDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة إضافة المنتج قيد التطوير')),
    );
  }

  void _exportProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة التصدير قيد التطوير')),
    );
  }

  void _importProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة الاستيراد قيد التطوير')),
    );
  }
}