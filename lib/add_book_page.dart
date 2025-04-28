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

  File? _imageFile;
  String? _base64Image;

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishBook() async {
    if (_judulController.text.isEmpty || _authorController.text.isEmpty || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi dan gambar harus dipilih')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
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
        'user_id': user.uid, // Menambahkan user_id ke data
      });

      Navigator.pop(context); // Kembali ke halaman sebelumnya setelah publikasi
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal publikasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Buku'),
      ),
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
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Center(child: Text('Ketuk untuk menambahkan media')),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            TextField(
              controller: _kategoriController,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            TextField(
              controller: _linkPdfController,
              decoration: const InputDecoration(labelText: 'Link PDF'),
            ),
            TextField(
              controller: _sinopsisController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Sinopsis'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publishBook,
              child: const Text('Publikasi'),
            ),
          ],
        ),
      ),
    );
  }
}
