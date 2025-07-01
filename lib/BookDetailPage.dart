import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buku_raya/pdf_view_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailPage extends StatefulWidget {
  final String documentId;

  const BookDetailPage({Key? key, required this.documentId}) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  int _currentIndex = -1;
  bool _isFavorite = false;
  bool _isLikeLoading = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    checkIfFavorite();
  }

  Future<DocumentSnapshot> getBookData() async {
    return await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.documentId)
        .get();
  }

  Future<void> checkIfFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final favDoc = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('books')
        .doc(widget.documentId)
        .get();

    setState(() {
      _isFavorite = favDoc.exists;
    });
  }

  Future<void> toggleFavorite() async {
    setState(() {
      _isFavoriteLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('books')
        .doc(widget.documentId);

    if (_isFavorite) {
      await favRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Buku dihapus dari Favorit")),
      );
    } else {
      final bookData = await getBookData();
      if (bookData.exists) {
        await favRef.set(bookData.data() as Map<String, dynamic>);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Buku berhasil disimpan ke Favorit")),
      );
    }

    setState(() {
      _isFavorite = !_isFavorite;
      _isFavoriteLoading = false;
    });
  }

  Future<void> toggleLike() async {
    setState(() {
      _isLikeLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final bookRef = FirebaseFirestore.instance.collection('books').doc(widget.documentId);

    final snapshot = await bookRef.get();
    final likeList = (snapshot.data()?['likes'] as List<dynamic>? ?? []);

    if (likeList.contains(userId)) {
      await bookRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await bookRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });

      // Tampilkan feedback sederhana saat berhasil like
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamu menyukai buku ini")),
      );
    }

    setState(() {
      _isLikeLoading = false;
    });
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .doc(widget.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Buku tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final likeList = (data['likes'] as List<dynamic>? ?? []);
          final isLiked = userId != null && likeList.contains(userId);
          final likeCount = likeList.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(data['gambar']),
                    height: 200,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['judul'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
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
                      icon: _isFavoriteLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Icon(
                              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                              color: _isFavorite ? Colors.black : null,
                            ),
                      onPressed: _isFavoriteLoading ? null : toggleFavorite,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isLikeLoading ? null : toggleLike,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.thumb_up,
                          color: isLiked ? Colors.black : null,
                          size: isLiked ? 30 : 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('$likeCount'),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final pdfUrl = data['link_pdf'];
                    if (pdfUrl.isNotEmpty) {
                      final fileId = pdfUrl.split('id=')[1];
                      final viewerUrl =
                          'https://drive.google.com/viewerng/viewer?embedded=true&url=https://drive.google.com/uc?id=$fileId';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PDFViewerPage(pdfUrl: viewerUrl),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link PDF tidak ditemukan")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Membaca buku'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                Text(
                  data['sinopsis'] ?? 'Sinopsis belum tersedia',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex == -1 ? 0 : _currentIndex,
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
