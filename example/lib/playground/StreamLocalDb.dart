
// class StreamsExample extends StatefulWidget {
//   @override
//   _StreamsExampleState createState() => _StreamsExampleState();
// }

// class _StreamsExampleState extends State<StreamsExample> {
//   late BnwDatabase database;
//   late CategoriesDao categoriesDao;
//   late ProductsDao productsDao;

//   @override
//   void initState() {
//     super.initState();
//     _initializeDatabase();
//   }

//   Future<void> _initializeDatabase() async {
//     database = BnwDatabase();
//     categoriesDao = CategoriesDao(database);
//     productsDao = ProductsDao(database);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Streams Example'),
//         backgroundColor: Colors.blue,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Action Buttons
//             _buildActionButtons(),
//             SizedBox(height: 20),

//             // Categories Stream
//             _buildCategoriesSection(),
//             SizedBox(height: 20),

//             // Products Stream
//             _buildProductsSection(),
//             SizedBox(height: 20),

//             // Products by Category Stream
//             _buildProductsByCategorySection(),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================
//   // ACTION BUTTONS SECTION
//   // =========================
//   Widget _buildActionButtons() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Actions',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Wrap(
//               spacing: 10,
//               children: [
//                 ElevatedButton(
//                   onPressed: _addSampleCategory,
//                   child: Text('Add Category'),
//                 ),
//                 ElevatedButton(
//                   onPressed: _addSampleProduct,
//                   child: Text('Add Product'),
//                 ),
//                 ElevatedButton(
//                   onPressed: _toggleRandomProductStatus,
//                   child: Text('Toggle Product Status'),
//                 ),
//                 ElevatedButton(
//                   onPressed: _deleteRandomProduct,
//                   child: Text('Delete Random Product'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================
//   // CATEGORIES STREAM SECTION
//   // =========================
//   Widget _buildCategoriesSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Categories (Real-time)',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),

//             // StreamBuilder for Categories
//             StreamBuilder<List<Category>>(
//               stream: categoriesDao.watchAllCategories(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Text('Error: ${snapshot.error}');
//                 }

//                 final categories = snapshot.data ?? [];

//                 if (categories.isEmpty) {
//                   return Text('No categories found. Add some categories!');
//                 }

//                 return Column(
//                   children:
//                       categories
//                           .map(
//                             (category) => ListTile(
//                               leading: Icon(Icons.category, color: Colors.blue),
//                               title: Text(category.name),
//                               subtitle: Text('ID: ${category.id}'),
//                               trailing: IconButton(
//                                 icon: Icon(Icons.delete, color: Colors.red),
//                                 onPressed: () => _deleteCategory(category.id),
//                               ),
//                             ),
//                           )
//                           .toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================
//   // PRODUCTS STREAM SECTION
//   // =========================
//   Widget _buildProductsSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'All Products (Real-time)',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),

//             // StreamBuilder for Products
//             StreamBuilder<List<Product>>(
//               stream: productsDao.watchAllProducts(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Text('Error: ${snapshot.error}');
//                 }

//                 final products = snapshot.data ?? [];

//                 if (products.isEmpty) {
//                   return Text('No products found. Add some products!');
//                 }

//                 return Column(
//                   children:
//                       products
//                           .map(
//                             (product) => Card(
//                               margin: EdgeInsets.symmetric(vertical: 4),
//                               child: ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor:
//                                       product.isActive == true
//                                           ? Colors.green
//                                           : Colors.red,
//                                   child: Text('${product.id}'),
//                                 ),
//                                 title: Text(product.name),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Sale: \$${product.salePrice.toStringAsFixed(2)}',
//                                     ),
//                                     Text(
//                                       'Retail: \$${product.retailPrice.toStringAsFixed(2)}',
//                                     ),
//                                     Text(
//                                       'Category ID: ${product.productCategory}',
//                                     ),
//                                   ],
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: Icon(
//                                         product.isActive == true
//                                             ? Icons.toggle_on
//                                             : Icons.toggle_off,
//                                         color:
//                                             product.isActive == true
//                                                 ? Colors.green
//                                                 : Colors.grey,
//                                       ),
//                                       onPressed:
//                                           () => _toggleProductStatus(
//                                             product.id,
//                                             !(product.isActive ?? false),
//                                           ),
//                                     ),
//                                     IconButton(
//                                       icon: Icon(
//                                         Icons.delete,
//                                         color: Colors.red,
//                                       ),
//                                       onPressed:
//                                           () => _deleteProduct(product.id),
//                                     ),
//                                   ],
//                                 ),
//                                 isThreeLine: true,
//                               ),
//                             ),
//                           )
//                           .toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================
//   // PRODUCTS BY CATEGORY STREAM
//   // =========================
//   Widget _buildProductsByCategorySection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Products by Category (Real-time)',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),

//             // First, get categories to show products for each
//             StreamBuilder<List<Category>>(
//               stream: categoriesDao.watchAllCategories(),
//               builder: (context, categoriesSnapshot) {
//                 if (!categoriesSnapshot.hasData ||
//                     categoriesSnapshot.data!.isEmpty) {
//                   return Text('No categories to show products for.');
//                 }

//                 final categories = categoriesSnapshot.data!;

//                 return Column(
//                   children:
//                       categories
//                           .map(
//                             (category) => ExpansionTile(
//                               title: Text(category.name),
//                               subtitle: Text('Category ID: ${category.id}'),
//                               children: [
//                                 // StreamBuilder for products in this category
//                                 StreamBuilder<List<Product>>(
//                                   stream: productsDao.watchProductsByCategory(
//                                     category.id,
//                                   ),
//                                   builder: (context, productsSnapshot) {
//                                     if (productsSnapshot.connectionState ==
//                                         ConnectionState.waiting) {
//                                       return Padding(
//                                         padding: EdgeInsets.all(16),
//                                         child: Center(
//                                           child: CircularProgressIndicator(),
//                                         ),
//                                       );
//                                     }

//                                     final products =
//                                         productsSnapshot.data ?? [];

//                                     if (products.isEmpty) {
//                                       return Padding(
//                                         padding: EdgeInsets.all(16),
//                                         child: Text(
//                                           'No products in this category',
//                                         ),
//                                       );
//                                     }

//                                     return Column(
//                                       children:
//                                           products
//                                               .map(
//                                                 (product) => ListTile(
//                                                   leading: Icon(
//                                                     Icons.shopping_bag,
//                                                   ),
//                                                   title: Text(product.name),
//                                                   subtitle: Text(
//                                                     '\$${product.salePrice.toStringAsFixed(2)}',
//                                                   ),
//                                                   trailing: Icon(
//                                                     product.isActive == true
//                                                         ? Icons.check_circle
//                                                         : Icons.cancel,
//                                                     color:
//                                                         product.isActive == true
//                                                             ? Colors.green
//                                                             : Colors.red,
//                                                   ),
//                                                 ),
//                                               )
//                                               .toList(),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           )
//                           .toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================
//   // COMBINED STREAM EXAMPLE
//   // =========================
//   Widget _buildCombinedStreamExample() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Combined Streams Example',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),

//             // Using StreamBuilder.builder for multiple streams
//             StreamBuilder<List<Category>>(
//               stream: categoriesDao.watchAllCategories(),
//               builder: (context, categoriesSnapshot) {
//                 return StreamBuilder<List<Product>>(
//                   stream: productsDao.watchAllProducts(),
//                   builder: (context, productsSnapshot) {
//                     final categories = categoriesSnapshot.data ?? [];
//                     final products = productsSnapshot.data ?? [];

//                     return Column(
//                       children: [
//                         Text('Total Categories: ${categories.length}'),
//                         Text('Total Products: ${products.length}'),
//                         Text(
//                           'Active Products: ${products.where((p) => p.isActive == true).length}',
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================
//   // DATABASE OPERATIONS
//   // =========================

//   Future<void> _addSampleCategory() async {
//     final categories = [
//       'Electronics',
//       'Clothing',
//       'Books',
//       'Home',
//       'Sports',
//       'Beauty',
//       'Toys',
//     ];
//     final randomCategory =
//         categories[DateTime.now().millisecond % categories.length];

//     try {
//       await categoriesDao.insertCategory(
//         CategoriesCompanion.insert(
//           name: '$randomCategory ${DateTime.now().millisecond}',
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
//     }
//   }

//   Future<void> _addSampleProduct() async {
//     final products = [
//       'Smartphone',
//       'Laptop',
//       'T-Shirt',
//       'Book',
//       'Chair',
//       'Watch',
//     ];
//     final randomProduct =
//         products[DateTime.now().millisecond % products.length];

//     // Get a random category
//     final categories = await categoriesDao.getAllCategories();
//     if (categories.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Please add a category first!')));
//       return;
//     }

//     final randomCategory =
//         categories[DateTime.now().millisecond % categories.length];

//     try {
//       await productsDao.insertProduct(
//         ProductsCompanion.insert(
//           name: '$randomProduct ${DateTime.now().millisecond}',
//           description: drift.Value('Sample product description'),
//           salePrice: (DateTime.now().millisecond % 100 + 10).toDouble(),
//           retailPrice: (DateTime.now().millisecond % 100 + 20).toDouble(),
//           productCategory: randomCategory.id,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error adding product: $e')));
//     }
//   }

//   Future<void> _toggleRandomProductStatus() async {
//     final products = await productsDao.getAllProducts();
//     if (products.isEmpty) return;

//     final randomProduct =
//         products[DateTime.now().millisecond % products.length];
//     await productsDao.toggleProductStatus(
//       randomProduct.id,
//       !(randomProduct.isActive ?? false),
//     );
//   }

//   Future<void> _deleteRandomProduct() async {
//     final products = await productsDao.getAllProducts();
//     if (products.isEmpty) return;

//     final randomProduct =
//         products[DateTime.now().millisecond % products.length];
//     await productsDao.deleteProduct(randomProduct.id);
//   }

//   Future<void> _toggleProductStatus(int productId, bool newStatus) async {
//     await productsDao.toggleProductStatus(productId, newStatus);
//   }

//   Future<void> _deleteProduct(int productId) async {
//     await productsDao.deleteProduct(productId);
//   }

//   Future<void> _deleteCategory(int categoryId) async {
//     await categoriesDao.deleteCategory(categoryId);
//   }

//   @override
//   void dispose() {
//     database.close();
//     super.dispose();
//   }
// }

// // =========================
// // ADVANCED STREAM USAGE
// // =========================

// class AdvancedStreamsExample extends StatefulWidget {
//   @override
//   _AdvancedStreamsExampleState createState() => _AdvancedStreamsExampleState();
// }

// class _AdvancedStreamsExampleState extends State<AdvancedStreamsExample> {
//   late BnwDatabase database;
//   late ProductsDao productsDao;

//   // Stream controllers for filtering
//   final _categoryFilterController = StreamController<int?>.broadcast();
//   final _searchController = StreamController<String>.broadcast();

//   @override
//   void initState() {
//     super.initState();
//     database = BnwDatabase();
//     productsDao = ProductsDao(database);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Advanced Streams')),
//       body: Column(
//         children: [
//           // Filter controls
//           Padding(
//             padding: EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(labelText: 'Search products'),
//                     onChanged: (value) => _searchController.add(value),
//                   ),
//                 ),
//                 SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () => _categoryFilterController.add(null),
//                   child: Text('Clear Filter'),
//                 ),
//               ],
//             ),
//           ),

//           // Filtered products stream
//           Expanded(
//             child: StreamBuilder<String>(
//               stream: _searchController.stream.distinct(),
//               initialData: '',
//               builder: (context, searchSnapshot) {
//                 final searchTerm = searchSnapshot.data ?? '';

//                 return StreamBuilder<List<Product>>(
//                   stream: _getFilteredProductsStream(searchTerm),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Center(child: CircularProgressIndicator());
//                     }

//                     final products = snapshot.data ?? [];

//                     return ListView.builder(
//                       itemCount: products.length,
//                       itemBuilder: (context, index) {
//                         final product = products[index];
//                         return ListTile(
//                           title: Text(product.name),
//                           subtitle: Text('\$${product.salePrice}'),
//                           trailing: Text(
//                             product.isActive == true ? 'Active' : 'Inactive',
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Stream<List<Product>> _getFilteredProductsStream(String searchTerm) {
//     if (searchTerm.isEmpty) {
//       return productsDao.watchAllProducts();
//     } else {
//       // For search, we need to create a custom stream
//       return Stream.periodic(
//         Duration(milliseconds: 500),
//       ).asyncMap((_) => productsDao.searchProductsByName(searchTerm));
//     }
//   }

//   @override
//   void dispose() {
//     _categoryFilterController.close();
//     _searchController.close();
//     database.close();
//     super.dispose();
//   }
// }

// // =========================
// // MAIN APP INTEGRATION
// // =========================

// class StreamsApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'BNW Streams Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: StreamsExample(),
//     );
//   }
// }

// // To run this, use:
