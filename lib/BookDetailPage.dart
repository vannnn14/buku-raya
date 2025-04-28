import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buku_raya/pdf_view_page.dart'; // Import halaman PDFViewerPage
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailPage extends StatelessWidget {
  final String documentId;

  const BookDetailPage({Key? key, required this.documentId}) : super(key: key);

  Future<DocumentSnapshot> getBookData() async {
    return await FirebaseFirestore.instance
        .collection('books')
        .doc(documentId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: FutureBuilder<DocumentSnapshot>(
        future: getBookData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Buku tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gambar buku
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(data['gambar']),
                      height: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Judul buku
                Center(
                  child: Text(
                    data['judul'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                // Informasi penulis
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 6),
                    Text(data['author'], style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.bookmark_border),
                      onPressed: () {
                        // Aksi simpan
                      },
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: () {
                        // Aksi love
                      },
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        // Aksi komentar
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // Tombol baca
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final pdfUrl = data['link_pdf'];
                      if (pdfUrl.isNotEmpty) {
                        final fileId = pdfUrl.split('id=')[1];
                        final viewerUrl =
                            'https://drive.google.com/viewerng/viewer?embedded=true&url=https://drive.google.com/uc?id=$fileId';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PDFViewerPage(pdfUrl: viewerUrl),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Link PDF tidak ditemukan"),
                          ),
                        );
                      }
                    },
                    child: const Text('Membaca buku'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),

                // Sinopsis
                Text(
                  data['sinopsis'] ?? 'Sinopsis belum tersedia',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
