// screens/store_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_management_screen.dart';
import 'edit_product_screen.dart';
// import 'category_settings_screen.dart';

class StoreManagementScreen extends StatefulWidget {
  @override
  _StoreManagementScreenState createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final CollectionReference itemsCollection = FirebaseFirestore.instance.collection('items1');
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'all';
  List<String> categories = ['all'];
  List<DocumentSnapshot> searchResults = [];
  bool isSearching = false;
  bool hasSearched = false;

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

      List<String> loadedCategories = ['all']; // Keep 'all' as first option

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
  Future<void> _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        hasSearched = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      hasSearched = true;
    });

    try {
      // Search using nameParts array
      final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();

      Query searchQuery = itemsCollection;

      // If we have search words, use array-contains-any
      if (queryWords.isNotEmpty) {
        // Firebase allows array-contains-any with up to 10 values
        final searchTerms = queryWords.take(10).toList();
        searchQuery = searchQuery.where('namePartsLower', arrayContainsAny: searchTerms);
      }

      // Apply category filter if selected
      if (selectedCategory != 'all') {
        searchQuery = searchQuery.where('category', isEqualTo: selectedCategory);
      }

      // Limit results for performance
      searchQuery = searchQuery.limit(50);

      final snapshot = await searchQuery.get();

      setState(() {
        searchResults = snapshot.docs;
        isSearching = false;
      });
    } catch (e) {
      // Fallback: if array-contains-any fails, do a client-side search
      try {
        final snapshot = await itemsCollection.limit(200).get();

        setState(() {
          searchResults = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Search in nameParts
            final nameParts = List<String>.from(data['nameParts'] ?? []);
            final namePartsLower = List<String>.from(data['namePartsLower'] ?? []);
            final name = (data['name'] ?? '').toString().toLowerCase();

            final matchesSearch = nameParts.any((part) =>
                part.toLowerCase().contains(query)) ||
                namePartsLower.any((part) =>
                    part.contains(query)) ||
                name.contains(query);

            final matchesCategory = selectedCategory == 'all' ||
                data['category'] == selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          isSearching = false;
        });
      } catch (e) {
        setState(() {
          isSearching = false;
          searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة المتجر", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A11CB),
        actions: [
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
              );
              _loadCategories(); // Reload categories after returning
            },
            tooltip: 'إدارة التصنيفات',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isSearching ? null : _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A11CB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('بحث'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    underline: const SizedBox(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                      // Re-search if we have a query
                      if (_searchController.text.isNotEmpty) {
                        _performSearch();
                      }
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category == 'all' ? 'جميع التصنيفات' : category),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Results or Instructions
          Expanded(
            child: isSearching
                ? const Center(child: CircularProgressIndicator())
                : !hasSearched
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ابحث عن المنتجات للبدء',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'اكتب اسم المنتج أو جزء منه',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : searchResults.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'لا توجد نتائج',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchResults = [];
                        hasSearched = false;
                      });
                    },
                    child: const Text('مسح البحث'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final doc = searchResults[index];
                final data = doc.data() as Map<String, dynamic>;
                final isHidden = data['hidden'] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: _buildProductImage(data),
                    title: Text(
                      data['name'] ?? 'بدون اسم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isHidden ? TextDecoration.lineThrough : null,
                        color: isHidden ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['description'] != null)
                          Text(
                            data['description'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        Row(
                          children: [
                            if (data['category'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data['category'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (isHidden)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'مخفي',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          'السعر: ${data['SalePrice1'] ?? 0} ${data['SaleCurrencyId'] == 2 ? '\$' : 'د.ع'}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF6A11CB)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductScreen(
                              productId: doc.id,
                              productData: data,
                            ),
                          ),
                        ).then((_) {
                          // Refresh search results after editing
                          if (_searchController.text.isNotEmpty) {
                            _performSearch();
                          }
                        });
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProductScreen(
                            productId: doc.id,
                            productData: data,
                          ),
                        ),
                      ).then((_) {
                        // Refresh search results after editing
                        if (_searchController.text.isNotEmpty) {
                          _performSearch();
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> data) {
    final imageUrl = data['thumbnail'];

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null && imageUrl.toString().isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported, color: Colors.grey);
          },
        ),
      )
          : const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}