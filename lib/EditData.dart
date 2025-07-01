import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditDataPage extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final String documentId;

  const EditDataPage({
    Key? key,
    required this.bookData,
    required this.documentId,
  }) : super(key: key);

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  late TextEditingController _judulController;
  late TextEditingController _sinopsisController;
  late TextEditingController _kategoriController;
  late TextEditingController _linkPdfController;
  late TextEditingController _authorController;
  late String _gambarBase64;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.bookData['judul']);
    _sinopsisController = TextEditingController(text: widget.bookData['sinopsis']);
    _kategoriController = TextEditingController(text: widget.bookData['kategori']);
    _linkPdfController = TextEditingController(text: widget.bookData['link_pdf']);
    _authorController = TextEditingController(text: widget.bookData['author']);
    _gambarBase64 = widget.bookData['gambar'] ?? '';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _sinopsisController.dispose();
    _kategoriController.dispose();
    _linkPdfController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _gambarBase64 = base64Encode(bytes);
      });
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
        Navigator.pushReplacementNamed(context, '/add');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('𝓔𝓭𝓲𝓽 𝓑𝓾𝓴𝓾')),
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
                child: _gambarBase64.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_gambarBase64),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(child: Icon(Icons.add_a_photo, size: 50)),
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
                onPressed: _updateBookData,
                child: const Text('Simpan Perubahan'),
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

  Future<void> _updateBookData() async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(widget.documentId).update({
        'judul': _judulController.text,
        'sinopsis': _sinopsisController.text,
        'kategori': _kategoriController.text,
        'link_pdf': _linkPdfController.text,
        'author': _authorController.text,
        'gambar': _gambarBase64,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Data buku berhasil diperbarui.'),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
