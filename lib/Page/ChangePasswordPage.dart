import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mebel_shop/Service/AuthService.dart'; // Import your authentication service
import 'package:mebel_shop/main.dart'; // Import your main.dart for the api URL

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _changePassword() async {
    try {
      var response = await Dio().put(
        '$api/api/user_profile/change_password',
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "email_user": email_user,
          "old_password": _oldPasswordController.text,
          "new_password": _newPasswordController.text,
          "confirm_password": _confirmPasswordController.text,
        },
      );
      if (response.statusCode == 200) {
        // Password changed successfully, navigate back
// Inside the _changePassword method, after successful password change
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Пароль изменён!'),
            duration: Duration(seconds: 2), // Adjust the duration as needed
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Handle other status codes or errors from the server
        print('Не удалось изменить пароль: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors from Dio or network issues
      print('Ошибка изменения пароля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Изменить пароль'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Старый пароль',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Пожалуйста, введите ваш старый пароль';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Новый пароль',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Пожалуйста, введите ваш новый пароль';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Подтвердите пароль',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Пожалуйста, подтвердите ваш новый пароль';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _changePassword();
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      Color(0xFF1E40AF), // Белый цвет текста кнопки
                ),
                child: Text('Сменить пароль'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
