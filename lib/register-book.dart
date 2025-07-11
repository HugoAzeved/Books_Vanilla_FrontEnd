
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class RegisterBook extends StatefulWidget {
  const RegisterBook({super.key});

  @override
  State<RegisterBook> createState() => _RegisterBookState();
}

class _RegisterBookState extends State<RegisterBook> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _synopsisController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  final TextEditingController _stockBook = TextEditingController();
  final TextEditingController _publisher = TextEditingController();


  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final dio = Dio();

    final formData = FormData.fromMap({
      "title": _titleController.text,
      "synopsis": _synopsisController.text,
      "publicationYear": int.parse(_releaseDateController.text),
      "isbn": _isbnController.text,
      "author": _authorController.text,
      "price": double.tryParse(_priceController.text.replaceAll('R\$', '').replaceAll(',', '.')) ?? 0.0,
      "stock": int.parse(_stockBook.text),
      "publisher": _publisher.text,
      "genre": 'generico',
      "editionNumber": 1,
      "numberOfPages": 208,
      "format": "Brochura",
      "language": "Português",
      "ebook": false,
      "status": "ON",
      if (_selectedImage != null)
        "image": await MultipartFile.fromFile(_selectedImage!.path, filename: "livro.jpg"),
    });

    try {
      final response = await dio.post(
        'http://10.144.31.70:8080/api/book/register',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro cadastrado com sucesso!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${response.data}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao conectar com o servidor: $e')),
      );
    }
  }

  String _parseDate(String date) {
    try {
      final inputFormat = DateFormat("dd/MM/yyyy");
      final outputFormat = DateFormat("yyyy-MM-dd");
      return outputFormat.format(inputFormat.parse(date));
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text('Cadastre seu livro', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Será possível adicionar fotos ao livro após o cadastro', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),

              _buildTextField(_titleController, 'Título'),
              _buildTextField(_synopsisController, 'Sinopse', maxLines: 3),

              const SizedBox(height: 20),
              _buildTextField(_releaseDateController, 'Data de lançamento(apenas o ano)'),
              _buildTextField(_isbnController, 'ISBN'),
              _buildTextField(_authorController, 'Autor(a)'),
              _buildTextField(_publisher, 'Editora'),
              _buildTextField(_priceController, 'Preço'),
              _buildTextField(_stockBook, 'Quantidade no estoque'),

/*              const SizedBox(height: 12),
              const Text('Selecione o genero', style: TextStyle(color: Colors.white)),
              Column(
                children: _allCategories.map((category) {
                  return CheckboxListTile(
                    title: Text(category),
                    value: _selectedCategories.contains(category),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.blue,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),*/

              Center(
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Image.file(_selectedImage!, height: 150),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Adicionar Foto'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('Cadastrar Livro', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = true, int maxLines = 1, String? hint, String? prefixText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Campo obrigatório';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}


