import 'dart:io';

import 'package:ecommerce_admin_app/containers/additional_confirm.dart';
import 'package:ecommerce_admin_app/controllers/cloudinary_service.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/categories_model.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      body: Consumer<AdminProvider>(
        builder: (context, value, child) {
          final categories = CategoriesModel.fromJsonList(value.categories);

          if (categories.isEmpty) {
            return Center(
              child: Text(
                "No Categories Found",
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final imageUrl = (category.image.isEmpty)
                  ? "https://demofree.sirv.com/nope-not-here.jpg"
                  : category.image;

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                onTap: () => _showCategoryActions(context, category),
                title: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  "Priority: ${category.priority}",
                  style: TextStyle(color: theme.colorScheme.surfaceContainerHighest
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                  onPressed: () => _showModifyCategoryDialog(context, category),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showModifyCategoryDialog(context, null),
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  void _showCategoryActions(BuildContext context, CategoriesModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What do you want to do?"),
        content: const Text("Delete action cannot be undone"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close main dialog
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: context,
                builder: (context) => AdditionalConfirm(
                  contentText: "Are you sure you want to delete this?",
                  onYes: () async {
                    await DbService.instance.deleteCategory(category.id);
                    if (!mounted) return;
                    navigator.pop(); // Close confirmation
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Category deleted successfully.")),
                    );
                  },
                  onNo: () => Navigator.pop(context),
                ),
              );
            },
            child: const Text("Delete Category"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showModifyCategoryDialog(context, category);
            },
            child: const Text("Update Category"),
          ),
        ],
      ),
    );
  }

  void _showModifyCategoryDialog(BuildContext context, CategoriesModel? category) {
    showDialog(
      context: context,
      builder: (context) => ModifyCategory(
        isUpdating: category != null,
        categoryId: category?.id ?? "",
        name: category?.name,
        image: category?.image,
        priority: category?.priority ?? 0,
      ),
    );
  }
}

class ModifyCategory extends StatefulWidget {
  final bool isUpdating;
  final String? name;
  final String categoryId;
  final String? image;
  final int priority;

  const ModifyCategory({
    super.key,
    required this.isUpdating,
    this.name,
    required this.categoryId,
    this.image,
    required this.priority,
  });

  @override
  State<ModifyCategory> createState() => _ModifyCategoryState();
}

class _ModifyCategoryState extends State<ModifyCategory> {
  final formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();
  XFile? image;
  late final TextEditingController categoryController;
  late final TextEditingController imageController;
  late final TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    categoryController = TextEditingController(text: widget.name ?? "");
    imageController = TextEditingController(text: widget.image ?? "");
    priorityController = TextEditingController(text: widget.priority.toString());
  }

  @override
  void dispose() {
    categoryController.dispose();
    imageController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndUpload() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final uploadedUrl = await uploadToCloudinary(picked);
      if (uploadedUrl != null && mounted) {
        setState(() => imageController.text = uploadedUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.isUpdating ? "Update Category" : "Add Category"),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("All will be converted to lowercase"),
              const SizedBox(height: 10),
              TextFormField(
                controller: categoryController,
                validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                decoration: InputDecoration(
                  hintText: "Category Name",
                  labelText: "Category Name",
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 40),
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
              const Text("This will be used in ordering categories"),
              const SizedBox(height: 10),
              TextFormField(
                controller: priorityController,
                validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Priority",
                  labelText: "Priority",
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 40),
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
              if (image != null)
                Container(
                  margin: const EdgeInsets.all(20),
                  height: 200,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 40),
                  child: Image.file(File(image!.path), fit: BoxFit.contain),
                )
              else if (imageController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(20),
                  height: 100,
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 40),
                  child: Image.network(imageController.text, fit: BoxFit.contain),
                ),
              ElevatedButton(
                onPressed: _pickImageAndUpload,
                child: const Text("Pick Image"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: imageController,
                validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                decoration: InputDecoration(
                  hintText: "Image Link",
                  labelText: "Image Link",
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 40),
                  filled: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            final data = {
              "name": categoryController.text.toLowerCase(),
              "image": imageController.text,
              "priority": int.parse(priorityController.text),
            };

            if (widget.isUpdating) {
              await DbService.instance.updateCategory(widget.categoryId, data);
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Category Updated")));
            } else {
              await DbService.instance.createCategory(data);
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Category Added")));
            }
          },
          child: Text(widget.isUpdating ? "Update" : "Add"),
        ),
      ],
    );
  }
}
