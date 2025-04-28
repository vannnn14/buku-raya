import 'package:flutter/material.dart';
import 'package:buku_raya/service/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buku_raya/BookDetailPage.dart';
import 'package:buku_raya/add_book_page.dart';
import 'dart:convert'; // untuk base64Decode
import 'dart:typed_data'; // untuk Uint8List


class HomePage extends StatelessWidget {
  // Fungsi untuk mengambil buku berdasarkan kategori
  Stream<List<Map<String, dynamic>>> getBooksByCategory(String kategori) {
    return FirebaseFirestore.instance
        .collection('books')
        .where('kategori', isEqualTo: kategori)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id; // ← ini penting
                return data;
              }).toList(),
        );
  }

  // Fungsi untuk mengambil kategori yang ada di Firestore
  Stream<List<String>> getCategories() {
    return FirebaseFirestore.instance
        .collection('books')
        .snapshots()
        .map((snapshot) {
          final categories = <String>{}; // Menggunakan set untuk menghindari duplikasi
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            categories.add(data['kategori']); // Menambahkan kategori ke set
          }
          return categories.toList(); // Mengubah set menjadi list
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beranda"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // sementara 0, berarti halaman ini Home
        onTap: (index) {
          if (index == 2) { // ✏️ tombol ketiga
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBookPage()),
            );
          }
          // kalau mau nanti index 1 (bookmark) dan 3 (profile) ada navigasi lain, tinggal tambahin if else di sini
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      body: SafeArea(
        child: ListView(
          children: [
            // Search bar + notification
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari buku',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.notifications_outlined),
                ],
              ),
            ),

            // Banner slider
            SizedBox(
              height: 180,
              child: PageView(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // Indicator (static dummy)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: EdgeInsets.all(4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),

            // StreamBuilder untuk mengambil kategori
            StreamBuilder<List<String>>(
              stream: getCategories(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return CircularProgressIndicator();

                // Menampilkan kategori secara dinamis
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!.map((category) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: getBooksByCategory(category),
                      builder: (context, booksSnapshot) {
                        if (booksSnapshot.hasError) return Text('Error: ${booksSnapshot.error}');
                        if (!booksSnapshot.hasData) return CircularProgressIndicator();

                        return _buildBookCategory(
                          title: category,
                          books: booksSnapshot.data!,
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan kategori dan buku
  Widget _buildBookCategory({
    required String title,
    required List<Map<String, dynamic>> books,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header kategori
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Lihat selengkapnya >', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        // Buku (horizontal scroll)
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailPage(documentId: book['id']),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(left: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: book['gambar'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(
                                    book['gambar'],
                                  ), // Decode string base64 jadi gambar
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.book),
                      ),
                      SizedBox(height: 4),
                      Text(
                        book['judul'] ?? 'Tanpa Judul',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
