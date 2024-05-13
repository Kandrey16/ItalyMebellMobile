import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mebel_shop/Service/AuthService.dart';
import 'package:mebel_shop/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';

class UserProfileEditPage extends StatefulWidget {
  @override
  _UserProfileEditPageState createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  String? userEmail;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

Future<void> loadUserProfile() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  userEmail = prefs.getString('email_user');
  if (userEmail != null) {
    try {
      var response = await Dio().get('$api/api/user_profile/$userEmail');
      if (response.statusCode == 200) {
        setState(() {
          firstNameController.text = response.data['first_name_user'] ?? '';
          lastNameController.text = response.data['second_name_user'] ?? '';
          phoneNumberController.text = response.data['phone_number_client'] ?? '';
        });
      } else {
        print('Ошибка получения профиля: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при выполнении запроса: $e');
    }
  }
}


  Future<void> updateUserProfile() async {
    if (!_formKey.currentState!.validate() || userEmail == null) return;

    String fileName = _imageFile != null ? basename(_imageFile!.path) : '';
    Map<String, dynamic> data = {
      "first_name_user": firstNameController.text,
      "second_name_user": lastNameController.text,
      "phone_number_client": phoneNumberController.text,
    };

    // Если выбран файл изображения, добавляем его в данные формы
    if (_imageFile != null) {
      data["image_user_profile"] =
          await MultipartFile.fromFile(_imageFile!.path, filename: fileName);
    }

    FormData formData = FormData.fromMap(data);

    Dio dio = Dio();
    try {
      var response = await dio.put(
        '$api/api/user_profile/$userEmail',
        data: formData,
        options: Options(
          headers: {
            "accept": "application/json",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200) {
      } else {}
    } catch (e) {}
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Редактировать профиль"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_imageFile != null)
                Center(
                  child: SizedBox(
                    height: 200,
                    child:
                        Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  ),
                ),
              Center(
                // Надпись "Изменить фото" в центре
                child: TextButton(
                  onPressed: pickImage,
                  child: Text("Изменить фото"),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF1E40AF),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'Имя'),
                validator: (value) =>
                    value!.isEmpty ? "Пожалуйста, введите ваше имя" : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Фамилия'),
                validator: (value) =>
                    value!.isEmpty ? "Пожалуйста, введите вашу фамилию" : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Номер телефона'),
                validator: (value) => value!.isEmpty
                    ? "Пожалуйста, введите ваш номер телефона"
                    : null,
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: updateUserProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF1E40AF),
                  alignment: Alignment.center, // Выравнивание текста по центру
                ),
                child: Center(
                  child: Text(
                    "Обновить профиль",
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
