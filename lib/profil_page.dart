import 'dart:convert';
import 'package:buku_raya/EditData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:buku_raya/BookDetailPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _currentIndex = 3; // karena posisi profil di index ke-3

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigasi antar halaman sesuai tab
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
        // sudah di halaman profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Pengguna"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child:
            user == null
                ? const Center(child: Text('Silakan login terlebih dahulu'))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user!.displayName ?? 'Profil',
                            style: const TextStyle(fontSize: 20),
                          ),
                          Text('@${user!.email?.split('@')[0]}'),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Karya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('books')
                                .where('user_id', isEqualTo: user!.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('Belum ada karya'));
                          }

                          final books = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final data =
                                  books[index].data() as Map<String, dynamic>;
                              final imageBase64 = data['gambar'] as String?;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      imageBase64 != null &&
                                              imageBase64.isNotEmpty
                                          ? Image.memory(
                                            base64Decode(
                                              imageBase64.split(',').last,
                                            ),
                                            width: 70,
                                            height: 130,
                                            fit: BoxFit.contain,
                                          )
                                          : Container(
                                            width: 70,
                                            height: 130,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.book,
                                              size: 50,
                                            ),
                                          ),
                                ),
                                title: Text(data['judul'] ?? 'Tanpa Judul'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => EditDataPage(
                                                  bookData: data,
                                                  documentId: books[index].id,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        _showDeleteConfirmationDialog(
                                          context,
                                          books[index].id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BookDetailPage(
                                            documentId: books[index].id,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
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

  void _showDeleteConfirmationDialog(BuildContext context, String bookId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Penghapusan'),
          content: const Text('Apakah Anda yakin ingin menghapus buku ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseFirestore.instance
                      .collection('books')
                      .doc(bookId)
                      .delete();

                  await Future.delayed(const Duration(milliseconds: 300));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Buku berhasil dihapus.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus buku: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
