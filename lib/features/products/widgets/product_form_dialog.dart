import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/models/product_request.dart';
import '../data/services/product_service.dart';

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    this.productToEdit,
    this.categories = const [],
    required this.productService,
  });

  final ProductModel? productToEdit;
  final List<CategoryModel> categories;
  final ProductService productService;

  static Future<ProductModel?> show(
    BuildContext context, {
    ProductModel? productToEdit,
    List<CategoryModel> categories = const [],
    required ProductService productService,
  }) {
    return showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormDialog(
        productToEdit: productToEdit,
        categories: categories,
        productService: productService,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  int? _selectedCategoryId;
  bool _isLoading = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _titleController = TextEditingController(text: p?.title ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(
      text: (p != null && p.images.isNotEmpty)
          ? p.images.first
          : 'https://placehold.co/600x400',
    );

    if (p?.category != null) {
      _selectedCategoryId = p!.category!.id;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price greater than 0.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final catId = _selectedCategoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : 1);

    final imageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : 'https://placehold.co/600x400';

    final request = ProductRequest(
      title: _titleController.text.trim(),
      price: price,
      description: _descriptionController.text.trim(),
      categoryId: catId,
      images: [imageUrl],
    );

    setState(() => _isLoading = true);

    try {
      ProductModel result;
      if (_isEditing) {
        result = await widget.productService.updateProduct(
          widget.productToEdit!.id,
          request,
        );
      } else {
        result = await widget.productService.createProduct(request);
      }

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Product' : 'Add New Product',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 22,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _titleController,
                hintText: 'Product Title',
                prefixIcon: Icons.shopping_bag_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _priceController,
                hintText: 'Price (\$)',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Description',
                prefixIcon: Icons.description_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _imageUrlController,
                hintText: 'Image URL',
                prefixIcon: Icons.image_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Image URL is required';
                  }
                  return null;
                },
              ),
              if (widget.categories.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedCategoryId,
                      hint: const Text('Select Category'),
                      items: widget.categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                text: _isEditing ? 'Save Changes' : 'Create Product',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
