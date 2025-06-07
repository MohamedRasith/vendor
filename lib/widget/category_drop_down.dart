import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDropdown extends StatefulWidget {
  final TextEditingController controller;

  const CategoryDropdown({super.key, required this.controller});

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  List<String> categories = [];
  String? selectedCategory;
  bool showAddButton = false;
  final TextEditingController customCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      categories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> addCategory(String name) async {
    await FirebaseFirestore.instance.collection('categories').add({'name': name});
    setState(() {
      categories.add(name);
      selectedCategory = name;
      widget.controller.text = name;
      showAddButton = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category "$name" added.')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
              widget.controller.text = value!;
              showAddButton = false;
              customCategoryController.text = value;
            });
          },
          validator: (value) => value == null || value.isEmpty ? 'Category is required' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: customCategoryController,
          decoration: const InputDecoration(
            labelText: 'Or type a new category',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              showAddButton = value.trim().isNotEmpty && !categories.contains(value.trim());
            });
          },
        ),
        if (showAddButton)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                final typed = customCategoryController.text.trim();
                if (typed.isNotEmpty && !categories.contains(typed)) {
                  addCategory(typed);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Category"),
            ),
          ),
      ],
    );
  }
}
