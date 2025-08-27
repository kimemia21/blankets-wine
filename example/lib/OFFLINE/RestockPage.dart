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
  String _updateMode = 'set'; // 'set', 'add', 'remove'
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _loadData();
    _searchController.addListener(_filterProducts);
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
      
      _filteredProducts = List.from(_allProducts);
      _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
      
      _fadeController.forward();
    } catch (e) {
      _showError('Failed to load products: $e');
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
      }).toList();
      
      _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
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
      _stockController.text = '';
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _stockFocus.requestFocus();
    });
  }

  Future<void> _updateStock() async {
    if (_selectedProduct == null || _stockController.text.isEmpty) return;
    
    final quantity = int.tryParse(_stockController.text);
    if (quantity == null || quantity < 0) {
      _showError('Please enter a valid quantity');
      return;
    }

    try {
      bool success = false;
      final userId = 'terminal_user'; // You can make this dynamic
      
      switch (_updateMode) {
        case 'set':
          success = await StockManager.updateStock(
            productId: _selectedProduct!.id,
            newStock: quantity,
            userId: userId,
          );
          break;
        case 'add':
          success = await StockManager.addStock(
            productId: _selectedProduct!.id,
            quantity: quantity,
            userId: userId,
          );
          break;
        case 'remove':
          success = await StockManager.removeStock(
            productId: _selectedProduct!.id,
            quantity: quantity,
            userId: userId,
          );
          break;
      }

      if (success) {
        _showSuccess('Stock updated successfully');
        _stockController.clear();
        setState(() {
          _selectedProduct = null;
          _allProducts = CacheService.getCachedProducts();
        });
        _filterProducts();
        _searchFocus.requestFocus();
      } else {
        _showError('Failed to update stock');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text('${StockManager.getPendingChangesCount()} pending'),
              backgroundColor: StockManager.hasPendingChanges() 
                  ? colorScheme.errorContainer 
                  : colorScheme.surfaceVariant,
              labelStyle: TextStyle(
                color: StockManager.hasPendingChanges()
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
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

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
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
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              // Category filter
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['All', ..._categories.map((cat) => cat.name)]
                      .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? 'All');
                    _filterProducts();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Low stock toggle
              Expanded(
                child: FilterChip(
                  label: const Text('Low Stock'),
                  selected: _showLowStockOnly,
                  onSelected: (selected) {
                    setState(() => _showLowStockOnly = selected);
                    _filterProducts();
                  },
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.errorContainer,
                  checkmarkColor: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              // Results count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatePanel(ThemeData theme) {
    if (_selectedProduct == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedProduct!.name} (ID: ${_selectedProduct!.id})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedProduct = null),
                child: const Text('Cancel'),
              ),
            ],
          ),
          Text(
            'Current Stock: ${_selectedProduct!.stock}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _selectedProduct!.isLowStock 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mode selector
              Expanded(
                flex: 2,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'set', label: Text('Set')),
                    ButtonSegment(value: 'add', label: Text('Add')),
                    ButtonSegment(value: 'remove', label: Text('Remove')),
                  ],
                  selected: {_updateMode},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() => _updateMode = selection.first);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Quantity input
              Expanded(
                child: TextField(
                  controller: _stockController,
                  focusNode: _stockFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _updateStock(),
                ),
              ),
              const SizedBox(width: 12),
              // Update button
              ElevatedButton.icon(
                onPressed: _updateStock,
                icon: const Icon(Icons.check),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(ThemeData theme) {
    if (_filteredProducts.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isSelected = _selectedProduct?.id == product.id;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          elevation: isSelected ? 4 : 1,
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : null,
          child: ListTile(
            leading: CircleAvatar(
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
                ),
              ),
            ),
            title: Text(
              product.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${product.id} • ${_getCategoryName(product.category)}'),
                if (product.lastModified != null)
                  Text(
                    'Last updated: ${_formatDateTime(product.lastModified!)} by ${product.lastModifiedBy ?? "system"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'KSh ${product.price}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
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
            ),
            onTap: () => _selectProduct(product),
          ),
        );
      },
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