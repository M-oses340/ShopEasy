import 'dart:ui';
import 'package:ecommerce_admin_app/containers/additional_confirm.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/promo_banners_model.dart';
import 'package:flutter/material.dart';

class PromoBannersPage extends StatefulWidget {
  const PromoBannersPage({super.key});

  @override
  State<PromoBannersPage> createState() => _PromoBannersPageState();
}

class _PromoBannersPageState extends State<PromoBannersPage> {
  bool _isInitialized = false;
  bool _isPromo = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        _isPromo = arguments['promo'] ?? true;
      }
      _isInitialized = true;
      setState(() {});
    }
  }

  void _showActionDialog(PromoBannersModel promo) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text("Choose Action", style: theme.textTheme.titleMedium),
          content: Text(
            "Deleting cannot be undone.",
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.pop(context); // Close main dialog
                showDialog(
                  context: context,
                  builder: (context) => AdditionalConfirm(
                    contentText:
                    "Are you sure you want to delete this item?",
                    onYes: () async {
                      setState(() => _isLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      try {
                        await DbService.instance
                            .deletePromo(_isPromo, promo.id);
                        if (!mounted) return;

                        setState(() => _isLoading = false);
                        navigator.pop(); // Close confirmation dialog

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                "${_isPromo ? "Promo" : "Banner"} deleted successfully"),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                    onNo: () => Navigator.pop(context),
                  ),
                );
              },
              child: Text("Delete ${_isPromo ? "Promo" : "Banner"}"),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  "/update_promo",
                  arguments: {
                    "promo": _isPromo,
                    "detail": promo,
                  },
                );
              },
              child: Text("Update ${_isPromo ? "Promo" : "Banner"}"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPromo ? "Promos" : "Banners"),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: DbService.instance.readPromos(_isPromo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading ${_isPromo ? "promos" : "banners"}",
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No ${_isPromo ? "Promos" : "Banners"} found",
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              final promos = PromoBannersModel.fromJsonList(snapshot.data!.docs);

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: promos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  return InkWell(
                    onTap: () => _showActionDialog(promo),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              promo.image,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.broken_image, color: theme.colorScheme.onSurface),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promo.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  promo.category,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                            onPressed: _isLoading
                                ? null
                                : () {
                              Navigator.pushNamed(
                                context,
                                "/update_promo",
                                arguments: {
                                  "promo": _isPromo,
                                  "detail": promo,
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: theme.colorScheme.surface.withValues(alpha: 75),
              child: Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading
            ? null
            : () {
          Navigator.pushNamed(
            context,
            "/update_promo",
            arguments: {"promo": _isPromo},
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
