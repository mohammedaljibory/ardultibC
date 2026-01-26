import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _categories = [];

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

      setState(() {
        _categories = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل التصنيفات: $e')),
      );
    }
  }

  void _showAddEditDialog({QueryDocumentSnapshot? category}) {
    if (category != null) {
      final data = category.data() as Map<String, dynamic>;
      _nameArController.text = data['nameAr'] ?? '';
      _nameEnController.text = data['nameEn'] ?? '';
    } else {
      _nameArController.clear();
      _nameEnController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'إضافة تصنيف جديد' : 'تعديل التصنيف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameArController,
                decoration: InputDecoration(
                  labelText: 'اسم التصنيف (عربي)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: 'Category Name (English)',
                  border: OutlineInputBorder(),
                ),
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
              if (_nameArController.text.isEmpty && _nameEnController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('الرجاء إدخال اسم واحد على الأقل')),
                );
                return;
              }

              try {
                if (category == null) {
                  // Add new category
                  await FirebaseFirestore.instance.collection('categories').add({
                    'nameAr': _nameArController.text,
                    'nameEn': _nameEnController.text,
                    'order': _categories.length + 1,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  // Update existing category
                  await category.reference.update({
                    'nameAr': _nameArController.text,
                    'nameEn': _nameEnController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }

                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(category == null ? 'تم إضافة التصنيف' : 'تم تحديث التصنيف')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: Text(category == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(QueryDocumentSnapshot category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا التصنيف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await category.reference.delete();
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف التصنيف')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في الحذف: $e')),
                );
              }
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleCategoryStatus(QueryDocumentSnapshot category) async {
    final data = category.data() as Map<String, dynamic>;
    final currentStatus = data['isActive'] ?? true;

    try {
      await category.reference.update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الحالة: $e')),
      );
    }
  }

  void _reorderCategory(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);

    // Update order in Firestore
    try {
      for (int i = 0; i < _categories.length; i++) {
        await _categories[i].reference.update({'order': i + 1});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الترتيب')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الترتيب: $e')),
      );
      _loadCategories(); // Reload on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة التصنيفات', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF6A11CB),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'لا توجد تصنيفات',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: Icon(Icons.add),
              label: Text('إضافة تصنيف'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A11CB),
              ),
            ),
          ],
        ),
      )
          : ReorderableListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _categories.length,
        onReorder: _reorderCategory,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final data = category.data() as Map<String, dynamic>;
          final isActive = data['isActive'] ?? true;

          return Card(
            key: ValueKey(category.id),
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drag_handle, color: Colors.grey),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6A11CB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category,
                      color: Color(0xFF6A11CB),
                    ),
                  ),
                ],
              ),
              title: Text(
                data['nameAr'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: !isActive ? TextDecoration.lineThrough : null,
                  color: !isActive ? Colors.grey : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['nameEn'] != null && data['nameEn'].toString().isNotEmpty)
                    Text(
                      data['nameEn'],
                      style: TextStyle(
                        decoration: !isActive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          'الترتيب: ${data['order'] ?? index + 1}',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text(
                          isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        backgroundColor: isActive ? Colors.green[50] : Colors.red[50],
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.visibility : Icons.visibility_off,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleCategoryStatus(category),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAddEditDialog(category: category),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(category),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }
}