import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mebel_shop/Models/Category.dart';
import 'package:mebel_shop/Models/Product.dart';
import 'package:mebel_shop/Page/CartPage.dart';
import 'package:mebel_shop/Page/ProductDetailsPage.dart';
import 'package:mebel_shop/Page/ProfilePage.dart';
import 'package:mebel_shop/Service/AuthService.dart';
import 'package:mebel_shop/Widgets/ProductCard.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Category> categories = [];
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  int? selectedCategoryId;
  TextEditingController searchController = TextEditingController();

  void searchProducts(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        // If search text is empty, show all products
        filteredProducts = allProducts;
      } else {
        // Filter products based on search text
        filteredProducts = allProducts
            .where((product) =>
                product.name.toLowerCase().contains(searchText.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchAllProducts();
  }

  Future<void> fetchCategories() async {
    try {
      var response = await Dio().get('$api/api/category/');
      var receivedCategories = List.from(response.data)
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList();
      setState(() {
        categories = receivedCategories;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchAllProducts() async {
    try {
      var response = await Dio().get('$api/api/product/');
      var productData = response.data['rows'] as List;
      List<Product> productList =
          productData.map((json) => Product.fromJson(json)).toList();
      setState(() {
        allProducts = productList;
        filteredProducts = productList;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchProductsByCategory(int categoryId) async {
    try {
      var response = await Dio().get('$api/api/product/',
          queryParameters: {"id_category": categoryId});
      var productData = response.data['rows'] as List;
      List<Product> productList =
          productData.map((json) => Product.fromJson(json)).toList();
      setState(() {
        filteredProducts = productList;
        selectedCategoryId = categoryId;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      IconData iconData = rating >= i + 1 ? Icons.star : Icons.star_border;
      stars.add(Icon(iconData,
          color: Colors.yellow[700],
          size: 18)); // размер звезд подбирается под дизайн
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    var width =
        MediaQuery.of(context).size.width / 2 - 10; // Вычитаем 10 для отступов

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: TextField(
          controller: searchController,
          onChanged: (value) => searchProducts(value),
          decoration: InputDecoration(
            hintText: 'Поиск товаров...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Открывает страницу профиля
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CartPage()), // Замените на актуальное имя вашей страницы профиля
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (selectedCategoryId == categories[index].id) {
                      fetchAllProducts(); // Загрузить все товары
                    } else {
                      fetchProductsByCategory(categories[index]
                          .id); // Загрузить товары по выбранной категории
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(4.0),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E40AF),
                      borderRadius: BorderRadius.circular(20),
                      border: selectedCategoryId == categories[index].id
                          ? Border.all(color: Colors.yellow, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        categories[index].name,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Количество столбцов
                crossAxisSpacing: 4.0, // Отступ по горизонтали
                mainAxisSpacing: 4.0, // Отступ по вертикали
                childAspectRatio: 1 / 1.5, // Соотношение сторон карточек
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final imageUrl = '$api/${product.imageUrl}';

                return ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailsPage(product: product),
                    ),
                  ),
                  imageUrl: imageUrl,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
