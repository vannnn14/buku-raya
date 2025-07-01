import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buku_raya/BookDetailPage.dart';

class BookListByCategoryPage extends StatefulWidget {
  final String kategori;
  const BookListByCategoryPage({super.key, required this.kategori});

  @override
  State<BookListByCategoryPage> createState() => _BookListByCategoryPageState();
}

class _BookListByCategoryPageState extends State<BookListByCategoryPage> {
  String searchQuery = '';

  Stream<List<Map<String, dynamic>>> getBooksByCategory(String kategori) {
    return FirebaseFirestore.instance
        .collection('books')
        .where('kategori', isEqualTo: kategori)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by title or author...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // 🏷️ Label Kategori
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.kategori,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 📚 Grid Buku
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getBooksByCategory(widget.kategori),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final books = snapshot.data!;
                  final filteredBooks = books.where((book) {
                    final title = (book['judul'] ?? '').toString().toLowerCase();
                    final author = (book['author'] ?? '').toString().toLowerCase();
                    return title.contains(searchQuery) || 
                           author.contains(searchQuery);
                  }).toList();

                  if (filteredBooks.isEmpty) {
                    return const Center(child: Text('Tidak ada buku ditemukan.'));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      itemCount: filteredBooks.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        final image = book['gambar'] != null
                            ? Image.memory(base64Decode(book['gambar']), fit: BoxFit.cover)
                            : const Icon(Icons.book, size: 40);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailPage(documentId: book['id']),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: image,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book['judul'] ?? 'Judul',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}