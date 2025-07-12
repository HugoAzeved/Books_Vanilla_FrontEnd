import 'dart:io' if (dart.library.html) 'dart:html'; // Importa File para mobile e html para web
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List; // Importa kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // Necessário para MediaType

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

  // Alterar o tipo da variável para ser compatível com web e mobile
  // Para web, armazenamos os bytes, para mobile, o File
  Uint8List? _selectedImageBytes;
  File? _selectedImageFile; // Manter para uso com File.fromFile em mobile

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Para web, leia os bytes do XFile
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null; // Garante que o File é nulo na web
        });
      } else {
        // Para mobile, crie um File a partir do path
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageBytes = null; // Garante que os bytes são nulos em mobile
        });
      }
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
      if (!kIsWeb && _selectedImageFile != null) // Para mobile, use File.fromFile
        "image": await MultipartFile.fromFile(_selectedImageFile!.path, filename: "livro.jpg"),
      if (kIsWeb && _selectedImageBytes != null) // Para web, use MultipartFile.fromBytes
        "image": MultipartFile.fromBytes(
          _selectedImageBytes!,
          filename: "livro.jpg", // Nome do arquivo é importante
          contentType: MediaType('image', 'jpeg'), // Tipo de conteúdo
        ),
    });

    try {
      final response = await dio.post(
        'http://10.144.31.70:8080/api/book/register',
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType, // Use Headers.multipartFormDataContentType
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
        leading: const BackButton(color: Colors.white),
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

              Center(
                child: Column(
                  children: [
                    if (kIsWeb && _selectedImageBytes != null) // Exibe imagem por bytes na web
                      Image.memory(_selectedImageBytes!, height: 150),
                    if (!kIsWeb && _selectedImageFile != null) // Exibe imagem por File em mobile
                      Image.file(_selectedImageFile!, height: 150),
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