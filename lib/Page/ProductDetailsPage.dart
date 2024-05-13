import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mebel_shop/Models/CartProduct.dart';
import 'package:mebel_shop/Models/Product.dart';
import 'package:mebel_shop/Models/ProductComment.dart';
import 'package:mebel_shop/Models/UserProfile.dart';
import 'package:mebel_shop/Page/CartPage.dart';
import 'package:mebel_shop/Service/AuthService.dart';
import 'package:mebel_shop/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  ProductDetailsPage({required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String? token;
  bool isPhoto = false;
  String? emailUser;
  List<ProductComment> _comments = [];
  TextEditingController _descriptionController = TextEditingController();
  int _ratingValue = 3; // Начальное значение рейтинга
  String _commentDescription = '';
  List<CartProduct> cartProducts = [];

  List<String> _productImages = [];
  bool isInCart = false;
  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadProductComments();
    _productImages.add(widget.product.imageUrl);

    _loadCartProducts();

    _fetchProductImages(widget.product.id).then((images) {
      setState(() {
        if (isPhoto) _productImages = images;
        _productImages.add(widget.product.imageUrl);
      });
    }).catchError((error) {
      print('Error loading product images: $error');
    });
  }

  Future<void> _loadCartProducts() async {
    try {
      var cartProducts =
          await fetchCartProducts(); // Wait for cart products to be fetched
      setState(() {
        isInCart = cartProducts
            .any((cartProduct) => cartProduct.product.id == widget.product.id);
      });
    } catch (error) {
      print('Error fetching cart products: $error');
    }
  }

  Future<List<CartProduct>> fetchCartProducts() async {
    try {
      var response = await Dio().get('$api/api/cart/$email_user');
      var productsRaw = response.data['cart']['cart_products'] as List;
      return productsRaw.map((json) => CartProduct.fromJson(json)).toList();
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch cart products');
    }
  }

  _loadProductComments() async {
    try {
      List<ProductComment> comments =
          await fetchProductComments(widget.product.id);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      print('Error loading product comments: $e');
    }
  }

  _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      emailUser = prefs.getString('email_user');
    });
  }

  _addToCart() async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Вы не авторизованы")),
      );
      return;
    }

    try {
      var response = await Dio().post(
        '$api/api/cart/',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          "id_product": widget.product.id.toString(),
          "email_user": emailUser, // Получите почту пользователя откуда-то
        },
      );

      if (response.statusCode == 200) {
        await _loadCartProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка добавления в корзину")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети")),
      );
    }
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      IconData iconData = rating >= i + 1 ? Icons.star : Icons.star_border;
      stars.add(Icon(iconData, color: Colors.yellow[700]));
    }
    return Row(children: stars);
  }

  Widget _buildRating(int rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      IconData iconData = rating >= i + 1 ? Icons.star : Icons.star_border;
      stars.add(Icon(iconData, color: Colors.yellow[700]));
    }
    return Row(children: stars);
  }

  Future<List<ProductComment>> fetchProductComments(int productId) async {
    try {
      final response = await Dio().get('$api/api/product_comment/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        List<ProductComment> allComments =
            data.map((comment) => ProductComment.fromJson(comment)).toList();
        List<ProductComment> filteredComments = allComments
            .where((comment) => comment.idProduct == productId)
            .toList();
        return filteredComments;
      } else {
        throw Exception('Failed to load product comments');
      }
    } catch (e) {
      print('Error fetching product comments: $e');
      throw Exception('Failed to load product comments');
    }
  }

  Future<UserProfile> fetchUserProfile(String email) async {
    try {
      final response = await Dio().get('$api/api/user_profile/$email');
      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      throw Exception('Failed to load user profile');
    }
  }

  Future<List<String>> _fetchProductImages(int productId) async {
    try {
      final response =
          await Dio().get('$api/api/product_image/?id_product=$productId');
      if (response.statusCode == 200) {
        if (response.data == null) {
          isPhoto == false;
          return [];
        } else {
          isPhoto = true;
          final List<dynamic> data = response.data;

          List<String> imageUrls =
              data.map((image) => image['url_image'] as String).toList();
          return imageUrls;
        }
      } else {
        throw Exception('Failed to load product images');
      }
    } catch (e) {
      print('Error fetching product images: $e');
      throw Exception('Failed to load product images');
    }
  }

  void _addProductComment() async {
    if (_commentDescription.isEmpty) {
      // Проверка на пустое описание
      return;
    }

    try {
      // Отправка запроса на сервер
      var response = await Dio().post(
        '$api/api/product_comment/',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          "mark_comment": _ratingValue.toString(),
          "description_comment": _commentDescription,
          "id_product": widget.product.id.toString(),
          "email_user": emailUser,
        },
      );

      if (response.statusCode == 200) {
        // Обработка успешного ответа
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Отзыв успешно добавлен")),
        );
        // Очистка полей ввода
        _descriptionController.clear();
        setState(() {
          // Обновление списка отзывов
          _loadProductComments();
        });
      } else {
        // Обработка ошибки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка при добавлении отзыва")),
        );
      }
    } catch (e) {
      print(e);
      // Обработка ошибки сети
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Отзыв успешно добавлен")),
      );
      // Очистка полей ввода
      _descriptionController.clear();
      setState(() {
        // Обновление списка отзывов
        _loadProductComments();
      });
    }
  }

  bool isCheck = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 50.0),
            // Добавляем отступ для кнопки
            child: Column(
              children: <Widget>[
                _buildProductImages(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildProductInfo(),
                      _buildSpecificationsAndDescription(),
                      _buildAddToCartButton(),
                      SizedBox(height: 50),
                      if (isCheck) _buildReviewsSection(),
                      ElevatedButton(
                        onPressed: () {
                          if (isCheck) {
                            _addProductComment();
                            setState(() {
                              isCheck = false;
                            });
                          } else {
                            setState(() {
                              isCheck = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green, // Цвет текста кнопки
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 24.0), // Отступы вокруг текста
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // Закругленные углы кнопки
                          ),
                        ),
                        child: Text('Добавить отзыв'),
                      ),
                      _buildCommentsList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImages() {
    return _productImages.isNotEmpty && isPhoto == true
        ? SizedBox(
            height: 400, // Высота списка фотографий
            child: PageView.builder(
              scrollDirection: Axis.horizontal, // Прокрутка по горизонтали
              itemCount: _productImages.length,
              itemBuilder: (context, index) {
                return Image.network(
                  '$api/${_productImages[index]}',
                  width: 150, // Ширина каждой фотографии
                  // Высота каждой фотографии
                  fit: BoxFit.cover,
                );
              },
            ),
          )
        : SizedBox(
            height: 200, // Высота списка фотографий
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Прокрутка по горизонтали
              itemCount: _productImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    '$api/${_productImages[index]}',
                  ),
                );
              },
            ),
          );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.product.name,
          style: Theme.of(context).textTheme.headlineSmall,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          widget.product.articleProduct,
          style: const TextStyle(fontSize: 16),
        ),
        _buildRatingStars(widget.product.rating),
        Text(
          '${widget.product.price} ₽',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 25)
      ],
    );
  }

  Widget _buildSpecificationsAndDescription() {
    return DefaultTabController(
      length: 2, // Количество вкладок
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Характеристики'),
              Tab(text: 'Описание'),
            ],
          ),
          SizedBox(
            height: 240, // Высота контейнера для TabBarView
            child: TabBarView(
              children: [
                _buildSpecifications(),
                _buildDescription(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.product.attributes != null &&
              widget.product.attributes!.isNotEmpty)
            ...widget.product.attributes!.asMap().entries.map((entry) {
              final attributeName = entry.key;
              final attributeSpecification =
                  widget.product.specifications![attributeName];

              // Проверка на null перед созданием виджета Text
              if (entry.value != null && attributeSpecification != null) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
                  child: Text.rich(
                    TextSpan(
                      text: '${entry.value}: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '$attributeSpecification',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return SizedBox
                    .shrink(); // Возвращает пустой виджет, если атрибут или спецификация равны null
              }
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          widget.product.description,
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ElevatedButton(
        onPressed: () {
          // If product is in cart, navigate to cart page
          if (isInCart) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage()),
            );
          } else {
            _addToCart();
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isInCart ? Colors.green : Color(0xFF1E40AF),
          minimumSize: Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text(isInCart ? 'Перейти в корзину' : 'В корзину',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

//я разделил на блоки
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Добавить отзыв:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Описание отзыва',
          ),
          onChanged: (value) {
            setState(() {
              _commentDescription = value;
            });
          },
        ),
        SizedBox(height: 10),
        Text('Рейтинг:'),
        Slider(
          value: _ratingValue.toDouble(),
          onChanged: (double newValue) {
            setState(() {
              _ratingValue = newValue.toInt();
            });
          },
          min: 1,
          max: 5,
          divisions: 4,
          label: _ratingValue.toString(),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCommentsList() {
    return _comments.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Отзывы о товаре:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                children: _comments.map((comment) {
                  return FutureBuilder<UserProfile>(
                    future: fetchUserProfile(comment.emailUser),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Или другой индикатор загрузки
                      } else if (snapshot.hasError) {
                        return Text('Ошибка загрузки профиля пользователя');
                      } else {
                        final userProfile = snapshot.data;
                        final userAvatarUrl =
                            '$api/user_photo/${userProfile?.imageUserProfile ?? ''}';
                        final avatarWidget = userProfile?.imageUserProfile !=
                                null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(userAvatarUrl),
                              )
                            : CircleAvatar(
                                child: Text(
                                  '${userProfile?.firstNameUser?.isNotEmpty ?? false ? userProfile!.firstNameUser![0] : ''}${userProfile?.secondNameUser?.isNotEmpty ?? false ? userProfile!.secondNameUser![0] : ''}',
                                  style: TextStyle(fontSize: 24),
                                ),
                              );
                        return ListTile(
                          leading: avatarWidget,
                          title: Text(
                            '${userProfile?.firstNameUser ?? ''} ${userProfile?.secondNameUser ?? ''}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight
                                    .w500), // Увеличенный размер и жирность для имени пользователя
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.description,
                                style: const TextStyle(
                                    fontSize:
                                        16), // Больший размер текста для описания
                              ),
                              _buildRating(comment.mark),
                              // Другие детали отзыва, такие как дата, могут быть добавлены здесь
                            ],
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          )
        : Container(); // Возвращает пустой контейнер, если нет комментариев
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Локальные переменные для хранения состояния формы в диалоговом окне
        String _localCommentDescription = '';
        double _localRatingValue = 1;

        return AlertDialog(
          title: Text('Добавить отзыв'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Описание отзыва',
                  ),
                  onChanged: (value) {
                    _localCommentDescription = value;
                  },
                ),
                SizedBox(height: 10),
                Text('Рейтинг:'),
                Slider(
                  value: _localRatingValue,
                  onChanged: (double newValue) {
                    // Обновление состояния только внутри showDialog не приводит к перерисовке
                    // В этой ситуации можно использовать StatefulBuilder или собственное состояние для AlertDialog
                    _localRatingValue = newValue;
                  },
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _localRatingValue.toString(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалоговое окно
              },
            ),
            ElevatedButton(
              child: Text('Добавить'),
              onPressed: () {
                // Здесь ваш код для добавления отзыва
                // _addProductComment(_localCommentDescription, _localRatingValue);
                Navigator.of(context)
                    .pop(); // Закрыть диалоговое окно после добавления отзыва
              },
            ),
          ],
        );
      },
    );
  }
}
