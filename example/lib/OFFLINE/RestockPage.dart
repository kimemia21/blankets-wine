import 'package:blankets_and_wines_example/OFFLINE/StockManger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blankets_and_wines_example/OFFLINE/CacheService.dart';
import 'package:blankets_and_wines_example/data/models/Product.dart';
import 'package:blankets_and_wines_example/data/models/DrinkCategory.dart';

class RestockPage extends StatefulWidget {
  const RestockPage({super.key});

  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> with TickerProviderStateMixin {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<DrinkCategory> _categories = [];
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _stockFocus = FocusNode();
  
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _showLowStockOnly = false;
  Product? _selectedProduct;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadData();
    _searchController.addListener(_filterProducts);
  }

  void _initializeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, 
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stockController.dispose();
    _searchFocus.dispose();
    _stockFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      _allProducts = CacheService.getCachedProducts();
      _categories = CacheService.getCachedCategories();
      
      _filteredProducts = List.from(_allProducts)
        ..sort((a, b) => a.name.compareTo(b.name));
      
      _fadeController.forward();
    } catch (e) {
      _showSnackBar('Failed to load products: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesSearch = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.id.toString().contains(query);
        
        final matchesCategory = _selectedCategory == 'All' ||
            _getCategoryName(product.category) == _selectedCategory;
        
        final matchesStock = !_showLowStockOnly || product.isLowStock;
        
        return matchesSearch && matchesCategory && matchesStock;
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  String _getCategoryName(int categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _stockController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _stockFocus.requestFocus();
    });
  }

  Future<void> _addStock() async {
    if (_selectedProduct == null || _stockController.text.isEmpty) return;
    
    final quantity = int.tryParse(_stockController.text);
    if (quantity == null || quantity <= 0) {
      _showSnackBar('Please enter a valid quantity', isError: true);
      return;
    }

    try {
      final success = await StockManager.addStock(
        productId: _selectedProduct!.id,
        quantity: quantity,
        userId: 'terminal_user', // Make this dynamic if needed
      );

      if (success) {
        _showSnackBar('Stock added successfully');
        _stockController.clear();
        setState(() {
          _selectedProduct = null;
          _allProducts = CacheService.getCachedProducts();
        });
        _filterProducts();
        _searchFocus.requestFocus();
      } else {
        _showSnackBar('Failed to add stock', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restock Terminal'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
          _buildPendingChangesChip(colorScheme),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildSearchAndFilters(theme),
                  _buildUpdatePanel(theme),
                  Expanded(child: _buildProductList(theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingChangesChip(ColorScheme colorScheme) {
    final hasPending = StockManager.hasPendingChanges();
    final count = StockManager.getPendingChangesCount();
    
    return Chip(
      label: Text('$count pending'),
      backgroundColor: hasPending 
          ? colorScheme.errorContainer 
          : colorScheme.surfaceVariant,
      labelStyle: TextStyle(
        color: hasPending
            ? colorScheme.onErrorContainer
            : colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSearchBar(theme),
          const SizedBox(height: 16),
          _buildFilterRow(theme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search products (name or ID)...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchFocus.requestFocus();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildCategoryDropdown(theme),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildLowStockFilter(theme),
        ),
        const SizedBox(width: 16),
        _buildResultsCount(theme),
      ],
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, 
          vertical: 8,
        ),
      ),
      items: ['All', ..._categories.map((cat) => cat.name)]
          .map((name) => DropdownMenuItem(
                value: name, 
                child: Text(name),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedCategory = value ?? 'All');
        _filterProducts();
      },
    );
  }

  Widget _buildLowStockFilter(ThemeData theme) {
    return FilterChip(
      label: const Text('Low Stock'),
      selected: _showLowStockOnly,
      onSelected: (selected) {
        setState(() => _showLowStockOnly = selected);
        _filterProducts();
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.errorContainer,
      checkmarkColor: theme.colorScheme.onErrorContainer,
    );
  }

  Widget _buildResultsCount(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_filteredProducts.length} items',
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUpdatePanel(ThemeData theme) {
    if (_selectedProduct == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(theme),
          const SizedBox(height: 8),
          _buildCurrentStock(theme),
          const SizedBox(height: 16),
          _buildStockInput(theme),
        ],
      ),
    );
  }

  Widget _buildProductHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_selectedProduct!.name} ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () => setState(() => _selectedProduct = null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildCurrentStock(ThemeData theme) {
    return Text(
      'Current Stock: ${_selectedProduct!.stock}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: _selectedProduct!.isLowStock 
            ? theme.colorScheme.error 
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStockInput(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _stockController,
            focusNode: _stockFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Quantity to Add',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, 
                vertical: 8,
              ),
            ),
            onSubmitted: (_) => _addStock(),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _addStock,
          icon: const Icon(Icons.add),
          label: const Text('Add Stock'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(ThemeData theme) {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, theme);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme) {
    final isSelected = _selectedProduct?.id == product.id;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 8,
        ),
        leading: _buildStockAvatar(product, theme),
        title: Text(
          product.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: _buildProductSubtitle(product, theme),
        trailing: _buildProductTrailing(product, theme),
        onTap: () => _selectProduct(product),
      ),
    );
  }

  Widget _buildStockAvatar(Product product, ThemeData theme) {
    return CircleAvatar(
      backgroundColor: product.isLowStock
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Text(
        product.stock.toString(),
        style: TextStyle(
          color: product.isLowStock
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildProductSubtitle(Product product, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text('${_getCategoryName(product.category)}'),
        if (product.lastModified != null) ...[
          const SizedBox(height: 2),
          Text(
            'Last updated: ${_formatDateTime(product.lastModified!)} by ${product.lastModifiedBy ?? "system"}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductTrailing(Product product, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'KSh ${product.price}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (product.isLowStock)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'LOW',
              style: TextStyle(
                color: theme.colorScheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}