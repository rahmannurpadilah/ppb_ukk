import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login.dart';
import 'daftartoko.dart';
import 'detailproductpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loadingProducts = true;
  bool loadingCategories = true;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];

  String? selectedCategory;
  String? token;
  String searchText = "";

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadToken();
    loadCategories();
    loadProducts();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("auth_token");
    });
  }

  Future<void> loadCategories() async {
    final res = await ApiService().getCategory();
    if (res['success']) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(res['data']);
      });
    }
    setState(() => loadingCategories = false);
  }

  Future<void> loadProducts() async {
    setState(() => loadingProducts = true);

    final res = await ApiService().getProducts();
    if (res['success']) {
      setState(() {
        products = List<Map<String, dynamic>>.from(res['products']);
      });
    }

    setState(() => loadingProducts = false);
  }

  Future<void> searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadProducts();
      return;
    }

    final res = await ApiService().productSearch(keyword);
    if (res['success']) {
      setState(() {
        products = List<Map<String, dynamic>>.from(res['data']);
      });
    }
  }

  Future<void> filterCategory(String? id) async {
    if (id == null) return;

    setState(() => loadingProducts = true);

    final res = await ApiService().getProductsByCategory(int.parse(id));

    if (res['success']) {
      setState(() {
        products = List<Map<String, dynamic>>.from(res['data']);
        selectedCategory = id;
      });
    }

    setState(() => loadingProducts = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");

    setState(() {
      token = null;
    });
  }

  // ================================
  // UI START HERE
  // ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Store App",
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (token == null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  ).then((_) => loadToken());
                },
                icon: const Icon(Icons.login, size: 18),
                label: const Text("Login"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          if (token != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DaftarTokoPage()),
                  );
                },
                icon: const Icon(Icons.add_business, size: 18),
                label: const Text("Daftar Toko"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF667eea),
                  side: const BorderSide(color: Color(0xFF667eea)),
                ),
              ),
            ),

          if (token != null)
            IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              color: Colors.red,
            ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async => loadProducts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HERO =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Selamat Datang! 👋",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Temukan produk terbaik untuk Anda",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ================= SEARCH =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
                      hintText: "Cari produk...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      searchText = value;

                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        searchProducts(value);
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= CATEGORY =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kategori Produk",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    loadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            value: selectedCategory,
                            items: categories.map((c) {
                              return DropdownMenuItem(
                                value: c["id_kategori"].toString(),
                                child: Text(c["nama_kategori"]),
                              );
                            }).toList(),
                            onChanged: filterCategory,
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ================= PRODUCT TITLE =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Produk Tersedia",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("${products.length} produk"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= PRODUCT GRID =================
              loadingProducts
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ================================
  // PRODUCT GRID (SUDAH ADA onTap)
  // ================================
  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          final p = products[index];

          final firstImage = (p["images"] is List && p["images"].isNotEmpty)
              ? p["images"][0]["gambar"]
              : null;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailProductPage(product: p),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======== GAMBAR ========
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: firstImage != null
                          ? Image.network(
                              firstImage,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.image, size: 40, color: Colors.grey[400]),
                    ),
                  ),

                  // ======== TEKS ========
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p["nama_produk"] ?? "Produk",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Rp ${p["harga"]}",
                          style: const TextStyle(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p["nama_toko"] ?? "",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
