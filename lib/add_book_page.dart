import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({Key? key}) : super(key: key);

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  final TextEditingController _linkPdfController = TextEditingController();
  final TextEditingController _sinopsisController = TextEditingController();

  File? _selectedImageFile;
  String? _base64Image;
  int _currentIndex = 2;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishBook() async {
    if (_judulController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _kategoriController.text.isEmpty ||
        _sinopsisController.text.isEmpty ||
        _base64Image == null) {
      _showSnackbar('Semua field harus diisi dan gambar harus dipilih');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackbar('Anda harus login terlebih dahulu');
        return;
      }

      await FirebaseFirestore.instance.collection('books').add({
        'judul': _judulController.text,
        'author': _authorController.text,
        'kategori': _kategoriController.text,
        'link_pdf': _linkPdfController.text,
        'sinopsis': _sinopsisController.text,
        'gambar': _base64Image,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
      });

      _showSuccessDialog();
    } catch (e) {
      _showSnackbar('Gagal publikasi: $e');
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/favorite');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sukses'),
        content: const Text('Buku berhasil ditambahkan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('𝓣𝓪𝓶𝓫𝓪𝓱 𝓑𝓾𝓴𝓾')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                      )
                    : const Center(child: Text('Ketuk untuk menambahkan gambar')),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(_judulController, 'Judul Buku'),
            _buildTextField(_authorController, 'Penulis'),
            _buildTextField(_kategoriController, 'Kategori'),
            _buildTextField(_linkPdfController, 'Link PDF'),
            _buildTextField(_sinopsisController, 'Sinopsis', maxLines: 5),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _publishBook,
                child: const Text('Publikasi'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Favorit'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
