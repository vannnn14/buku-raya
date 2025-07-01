import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buku_raya/service/firebase_auth_service.dart';
import 'package:buku_raya/BookDetailPage.dart';
import 'package:buku_raya/add_book_page.dart';
import 'package:buku_raya/BookListByCategoryPage.dart';
import 'package:buku_raya/favorite_page.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final _cacheManager = CacheManager(
    Config('bookImagesCache', stalePeriod: const Duration(days: 7)),
  );
  int _selectedIndex = 0;

  @override
  bool get wantKeepAlive => true;

  Stream<List<Map<String, dynamic>>> getBanners() {
    return FirebaseFirestore.instance
        .collection('banners')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  Stream<List<String>> getCategories() {
    return FirebaseFirestore.instance.collection('books').snapshots().map((snapshot) {
      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('kategori')) {
          categories.add(data['kategori']);
        }
      }
      return categories.toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getBooksByCategory(String kategori) {
    return FirebaseFirestore.instance
        .collection('books')
        .where('kategori', isEqualTo: kategori)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('judul', isGreaterThanOrEqualTo: query)
        .where('judul', isLessThan: query + 'z')
        .get();

    final results = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    final authorSnapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('author', isGreaterThanOrEqualTo: query)
        .where('author', isLessThan: query + 'z')
        .get();

    final authorResults = authorSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    final combinedResults = [...results, ...authorResults];
    final uniqueResults = <String, Map<String, dynamic>>{};
    for (var result in combinedResults) {
      uniqueResults[result['id']] = result;
    }

    setState(() {
      _searchResults = uniqueResults.values.toList();
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoritePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddBookPage()),
      );
    } else if (index == 3) {
      Navigator.pushNamed(context, '/profil');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari buku atau penulis...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _performSearch(value);
                },
              )
            : const Text('𝓑𝓾𝓴𝓾 𝓡𝓪𝔂𝓪'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchResults = [];
                }
              });
            },
          ),
          if (!_isSearching)
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
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
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
      body: SafeArea(
        child: _isSearching
            ? _buildSearchResults()
            : ListView(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getBanners(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final banners = snapshot.data!;
                      if (banners.isEmpty) return const SizedBox();

                      return Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: banners.length,
                              onPageChanged: (index) {
                                setState(() => _currentBannerIndex = index);
                              },
                              itemBuilder: (context, index) {
                                final banner = banners[index];
                                final imageBytes = base64Decode(banner['gambar'] ?? '');
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: MemoryImage(imageBytes),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(banners.length, (index) {
                              final active = index == _currentBannerIndex;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: active ? 12 : 8,
                                height: active ? 12 : 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active ? Colors.black : Colors.grey,
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                  StreamBuilder<List<String>>(
                    stream: getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final categories = snapshot.data!;
                      return Column(
                        children: categories.map((kategori) {
                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: getBooksByCategory(kategori),
                            builder: (context, bookSnap) {
                              if (!bookSnap.hasData) return const SizedBox();
                              final books = bookSnap.data!;
                              return _buildCategory(kategori, books);
                            },
                          );
                        }).toList(),
                      );
                    },
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text('Masukkan judul atau nama penulis untuk mencari'));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('Tidak ada hasil ditemukan'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return ListTile(
          leading: _buildBookImage(book),
          title: Text(book['judul'] ?? 'Tanpa Judul'),
          subtitle: Text(book['author'] ?? 'Penulis tidak diketahui'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailPage(documentId: book['id'])),
            );
          },
        );
      },
    );
  }

  Widget _buildCategory(String title, List<Map<String, dynamic>> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookListByCategoryPage(kategori: title)),
                  );
                },
                child: const Text('Lihat selengkapnya >', style: TextStyle(fontSize: 12, color: Colors.blue)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(left: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookDetailPage(documentId: book['id'])),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildBookImage(book),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book['judul'] ?? 'Tanpa Judul',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookImage(Map<String, dynamic> book) {
    if (book['gambar'] == null) {
      return const Icon(Icons.book, size: 40);
    }

    final imageBytes = base64Decode(book['gambar']);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        cacheHeight: 200,
        cacheWidth: 150,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            child: child,
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }
}
