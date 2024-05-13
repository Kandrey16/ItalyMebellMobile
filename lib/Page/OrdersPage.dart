import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mebel_shop/Service/AuthService.dart';
import 'package:mebel_shop/main.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      var response = await Dio().get('$api/api/orders/');
      if (response.statusCode == 200) {
        List<dynamic> allOrders = response.data as List<dynamic>;
        setState(() {
          // Фильтруем заказы по email пользователя
          orders = allOrders
              .where(
                  (order) => order['order_address']['email_user'] == email_user)
              .toList();
        });
      } else {
        print('Ошибка получения заказов: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при выполнении запроса: $e');
    }
  }

  // Function to show modal dialog with order details
  void _showOrderDetailsDialog(Map<String, dynamic> order) async {
    try {
      var productId = order['order_product'][0][
          'id_product']; // Assuming id_product is always present in the order_product list

      var productResponse = await Dio().get('$api/api/product/$productId');
      if (productResponse.statusCode == 200) {
        var productData = productResponse.data;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Детали заказа №${order['number_order']}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Дата заказа: ${order['date_order']}'),
                    Text('Сумма заказа: ${order['price_order']}₽'),
                    SizedBox(height: 10),
                    Text('Информация о товарах:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ListTile(
                      title: Text(
                          'Название товара: ${productData['name_product']}'),
                      subtitle: Text(
                          'Цена: ${productData['price_product']}₽\nАртикул: ${productData['article_product']}\nКоличество: ${order['order_product'][0]['count_order_product']}'),
                    ),
                    // You can add more details as needed
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Закрыть'),
                ),
              ],
            );
          },
        );
      } else {
        print(
            'Ошибка получения данных о товаре: ${productResponse.statusCode}');
      }
    } catch (e) {
      print('Ошибка при выполнении запроса товара: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои заказы'),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          var order = orders[index];

          return ListTile(
            title: Text('Заказ №${order['number_order']}'),
            subtitle: Text(
                'Сумма: ${order['price_order']}₽\nДата заказа: ${order['date_order']}'),
            onTap: () {
              // Show modal dialog with order details when tapped
              _showOrderDetailsDialog(order);
            },
          );
        },
      ),
    );
  }
}
