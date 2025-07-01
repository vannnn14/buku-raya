import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buku_raya/BookDetailPage.dart';
import 'package:buku_raya/add_book_page.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  int _currentIndex = 1; // posisi favorit di index ke-1

  Future<List<Map<String, dynamic>>> getFavoriteBooks() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoriteDocs = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('books')
        .get();

    List<Map<String, dynamic>> books = [];

    for (var fav in favoriteDocs.docs) {
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(fav.id)
          .get();

      if (bookDoc.exists) {
        final data = bookDoc.data()!;
        data['id'] = bookDoc.id;
        books.add(data);
      }
    }

    return books;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // sudah di halaman Favorite
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBookPage()),
        );
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('𝓑𝓾𝓴𝓾 𝓕𝓪𝓿𝓸𝓻𝓲𝓽')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getFavoriteBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(child: Text("Belum ada buku favorit"));
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: book['gambar'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(book['gambar']),
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.book),
                title: Text(book['judul'] ?? 'Tanpa Judul'),
                subtitle: Text(book['author'] ?? 'Tanpa Penulis'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailPage(documentId: book['id']),
                    ),
                  );
                },
              );
            },
          );
        },
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
}
