import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mebel_shop/Models/Category.dart';
import 'package:mebel_shop/Page/ProductsByCategoryPage.dart';
import 'package:mebel_shop/Service/AuthService.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late List<Category> categories = [];
  late List<Category> filteredCategories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    Dio dio = Dio();
    try {
      final response = await dio.get('$api/api/category/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          categories =
              data.map((category) => Category.fromJson(category)).toList();
          filteredCategories = List.from(
              categories); // Используем filteredCategories для вывода всех категорий с самого начала
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to load categories');
    }
  }

  void filterCategories(String query) {
    setState(() {
      filteredCategories = categories
          .where((category) =>
              category.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Категории'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 1.0,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (BuildContext context, int index) {
                return CategoryCard(category: filteredCategories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductsByCategoryPage(categoryId: category.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Stack(
          alignment: Alignment.center, // Выравнивание по центру
          children: <Widget>[
            Positioned.fill(
              child: Image.network(
                '$api/category_photo/${category.image}',
                fit: BoxFit.cover, // Заполняем весь размер карточки
              ),
            ),
            Container(
              // Оверлей который не только улучшает читаемость текста, но и добавляет стильный дизайн элемент
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
