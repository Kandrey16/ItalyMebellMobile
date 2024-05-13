import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mebel_shop/Models/Product.dart';
import 'package:mebel_shop/Page/ProductDetailsPage.dart';
import 'package:mebel_shop/Service/AuthService.dart';
import 'package:mebel_shop/Widgets/ProductCard.dart';

class ProductsByCategoryPage extends StatefulWidget {
  final int categoryId;

  const ProductsByCategoryPage({Key? key, required this.categoryId})
      : super(key: key);

  @override
  State<ProductsByCategoryPage> createState() => _ProductsByCategoryPageState();
}

class _ProductsByCategoryPageState extends State<ProductsByCategoryPage> {
  late List<Product> products = [];

  @override
  void initState() {
    super.initState();
    fetchProductsByCategory(widget.categoryId);
  }

  Future<void> fetchProductsByCategory(int categoryId) async {
    try {
      var response = await Dio().get('$api/api/product/',
          queryParameters: {"id_category": categoryId});
      var productData = response.data['rows'] as List;
      List<Product> productList =
          productData.map((json) => Product.fromJson(json)).toList();
      setState(() {
        products = productList;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Товары по категории'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(4.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Количество столбцов
          crossAxisSpacing: 4.0, // Отступ по горизонтали
          mainAxisSpacing: 4.0, // Отступ по вертикали
          childAspectRatio: 1 / 1.5, // Соотношение сторон карточек
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final imageUrl = '$api/${product.imageUrl}';

          return ProductCard(
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(product: product),
              ),
            ),
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }
}
