import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mebel_shop/Models/CartProduct.dart'; // Make sure this import is correct
import 'package:mebel_shop/Models/DeliveryMethod.dart';
import 'package:mebel_shop/Models/PaymentMethod.dart';
import 'package:mebel_shop/Page/BottomNavigationPage.dart';
import 'package:mebel_shop/Page/ProductsPage.dart';
import 'package:mebel_shop/Service/AuthService.dart';
import 'package:mebel_shop/main.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartProduct> cartProducts; // This should be List<CartProduct>
  late final double total;

  CheckoutPage({required this.cartProducts, required this.total});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  final _entryController = TextEditingController();
  final _floorController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedDeliveryMethod = -1; // по умолчанию ни один не выбран
  int _selectedPaymentMethod = -1; // по умолчанию ни один не выбран
  double _deliveryPrice = 0.0;

  @override
  void dispose() {
    _addressController.dispose();
    _entryController.dispose();
    _floorController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> submitOrder() async {
    final randomNumber = Random().nextInt(1000000);
    final currentDate = DateTime.now().toIso8601String();

    final orderData = {
      "order": {
        "number_order": randomNumber,
        "price_order": widget.total,
        "date_order": currentDate,
      },
      "address": {
        "address_order": _addressController.text,
        "entrance_order": int.tryParse(_entryController.text) ?? 0,
        "floor_order": int.tryParse(_floorController.text) ?? 0,
        "home_code_order": _codeController.text,
        "email_user": email_user,
      },
      "products": widget.cartProducts.map((cartProduct) {
        return {
          "count_order_product": cartProduct.countCartProduct,
          "id_cart_product": cartProduct.idCartProduct,
        };
      }).toList(),
      "payment_method": {
        "id_payment_method":
            _selectedPaymentMethod, // Pass the selected payment method ID here
      },
      "order_delivery": {
        "id_order_delivery":
            _selectedDeliveryMethod, // Pass the selected delivery method ID here
      },
      "order_status": {
        "id_order_status": 2, // This remains constant
      }
    };

    try {
      var response = await Dio().post(
        '$api/api/orders/',
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: orderData,
      );
      int _selectedPaymentMethod = -1; // по умолчанию ни один не выбран

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Заказ оформлен"),
            content: Text("Ваш заказ успешно оформлен!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BottomNavigationPage()), // Assuming ProductsPage is correctly imported and available
                    (Route<dynamic> route) =>
                        false, // This removes all the routes beneath the new route
                  );
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to create order.');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      Dio dio = Dio();
      Response response = await dio.get('$api/api/payment_method/');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => PaymentMethod.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payment methods');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }

  Future<List<DeliveryMethod>> fetchDeliveryMethods() async {
    try {
      Dio dio = Dio();
      Response response = await dio.get('$api/api/order_delivery/');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => DeliveryMethod.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load delivery methods');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Оформление заказа"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.cartProducts.length,
                    itemBuilder: (context, index) {
                      final cartProduct = widget.cartProducts[index];
                      return ListTile(
                        leading: Image.network(
                          '$api/${cartProduct.product.imageUrl}',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        title: Text(cartProduct.product.name),
                        subtitle:
                            Text('Количество: ${cartProduct.countCartProduct}'),
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Адрес доставки',
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Поле не может быть пустым'
                                : null,
                          ),
                          TextFormField(
                            controller: _entryController,
                            decoration: InputDecoration(
                              labelText: 'Подъезд',
                            ),
                          ),
                          TextFormField(
                            controller: _floorController,
                            decoration: InputDecoration(
                              labelText: 'Этаж',
                            ),
                          ),
                          TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Код домофона',
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Способ оплаты',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          FutureBuilder<List<PaymentMethod>>(
                            future:
                                fetchPaymentMethods(), // функция для загрузки данных о способах оплаты
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(); // показать индикатор загрузки пока данные загружаются
                              } else if (snapshot.hasError) {
                                return Text(
                                    'Ошибка загрузки данных о способах оплаты');
                              } else {
                                // данные успешно загружены, показать радиокнопки
                                List<PaymentMethod> paymentMethods =
                                    snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: paymentMethods.map((paymentMethod) {
                                    return RadioListTile(
                                      title: Text(paymentMethod.name),
                                      value: paymentMethod.id,
                                      groupValue: _selectedPaymentMethod,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPaymentMethod = value!;
                                        });
                                      },
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Способ доставки',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          FutureBuilder(
                            future: fetchDeliveryMethods(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text(
                                    'Ошибка загрузки данных о способах доставки');
                              } else {
                                List<DeliveryMethod> deliveryMethods =
                                    snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      deliveryMethods.map((deliveryMethod) {
                                    return RadioListTile(
                                      title: Text(
                                          '${deliveryMethod.name} - ${deliveryMethod.price} ₽'),
                                      value: deliveryMethod.id,
                                      groupValue: _selectedDeliveryMethod,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDeliveryMethod = value!;
                                          // Update the total price based on the selected delivery method
                                          _deliveryPrice =
                                              deliveryMethod.price.toDouble();
                                        });
                                      },
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Итоговая сумма: ${(widget.total + _deliveryPrice).toStringAsFixed(2)} ₽',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_validateAndSave()) {
                        widget.total + _deliveryPrice;
                        submitOrder(); // Вызов функции отправки заказа
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF1E40AF), // Цвет текста
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text('Подтвердить заказ',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
