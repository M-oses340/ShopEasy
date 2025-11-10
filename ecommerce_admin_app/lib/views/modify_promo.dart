import 'dart:io';
import 'package:ecommerce_admin_app/controllers/cloudinary_service.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/promo_banners_model.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ModifyPromo extends StatefulWidget {
  const ModifyPromo({super.key});

  @override
  State<ModifyPromo> createState() => _ModifyPromoState();
}

class _ModifyPromoState extends State<ModifyPromo> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final imageController = TextEditingController();

  String promoId = "";
  bool _isPromo = true;
  bool _isLoading = false;

  final ImagePicker picker = ImagePicker();
  XFile? pickedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is Map<String, dynamic>) {
      _isPromo = args["promo"] ?? true;

      if (args["detail"] is PromoBannersModel) {
        final data = args["detail"] as PromoBannersModel;
        promoId = data.id;
        titleController.text = data.title;
        categoryController.text = data.category;
        imageController.text = data.image;
      }
    }
  }

  /// Pick image and upload to Cloudinary safely
  Future<void> pickImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context); // capture before await
    final url = await uploadToCloudinary(img);

    if (!mounted) return;

    setState(() {
      pickedImage = img;
      if (url != null) imageController.text = url;
      _isLoading = false;
    });

    if (url != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully")),
      );
    }
  }

  /// Save promo or banner safely
  Future<void> savePromo() async {
    if (!formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context); // capture before await
    final navigator = Navigator.of(context); // capture before await

    final data = {
      "title": titleController.text,
      "category": categoryController.text,
      "image": imageController.text,
    };

    setState(() => _isLoading = true);

    try {
      if (promoId.isEmpty) {
        await DbService.instance.createPromo(_isPromo, data);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text("${_isPromo ? "Promo" : "Banner"} Added")),
        );
      } else {
        await DbService.instance.updatePromo(_isPromo, promoId, data);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text("${_isPromo ? "Promo" : "Banner"} Updated")),
        );
      }

      if (!mounted) return;
      navigator.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = promoId.isEmpty
        ? (_isPromo ? "Add Promo" : "Add Banner")
        : (_isPromo ? "Update Promo" : "Update Banner");

    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // Title
                  TextFormField(
                    controller: titleController,
                    validator: (v) => v!.isEmpty ? "This cannot be empty" : null,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  const SizedBox(height: 10),

                  // Category
                  TextFormField(
                    controller: categoryController,
                    readOnly: true,
                    validator: (v) => v!.isEmpty ? "This cannot be empty" : null,
                    decoration: const InputDecoration(labelText: "Category"),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Select Category"),
                          content: Consumer<AdminProvider>(
                            builder: (context, value, child) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: value.categories
                                  .map(
                                    (e) => TextButton(
                                  onPressed: () {
                                    categoryController.text = e["name"];
                                    Navigator.pop(context);
                                  },
                                  child: Text(e["name"]),
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Image preview
                  if (pickedImage != null || imageController.text.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.deepPurple.shade50,
                      child: pickedImage != null
                          ? Image.file(File(pickedImage!.path), fit: BoxFit.contain)
                          : Image.network(imageController.text, fit: BoxFit.contain),
                    ),
                  const SizedBox(height: 10),

                  // Pick Image Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : pickImage,
                    child: const Text("Pick Image"),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : savePromo,
                      child: Text(titleText),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
