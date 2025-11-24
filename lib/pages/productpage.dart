import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login.dart';
import 'daftartoko.dart';
import 'detailproductpage.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool loadingProducts = true;
  bool loadingCategories = true;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];

  String? selectedCategory;
  String searchText = "";

  bool isLoggedIn = false;
  bool hasStore = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadInit();
  }

  Future<void> loadInit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    isLoggedIn = token != null;

    if (isLoggedIn) {
      final res = await ApiService().getMyToko();
      hasStore = (res["success"] == true && res["data"] != null);
    }

    loadCategories();
    loadProducts();
  }

  Future<void> loadCategories() async {
    setState(() => loadingCategories = true);

    final res = await ApiService().getCategory();
    if (res['success']) {
      categories = List<Map<String, dynamic>>.from(res['data']);
    }

    setState(() => loadingCategories = false);
  }

  Future<void> loadProducts() async {
    setState(() => loadingProducts = true);

    final res = await ApiService().getProducts();
    if (res['success']) {
      products = List<Map<String, dynamic>>.from(res['products']);
    }

    setState(() => loadingProducts = false);
  }

  Future<void> searchProducts(String keyword) async {
    searchText = keyword;

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
      products = List<Map<String, dynamic>>.from(res['data']);
    }

    selectedCategory = id;

    setState(() => loadingProducts = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ========================= APP BAR ala HOMEPAGE =========================
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
              "Semua Produk",
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),

        actions: [
          if (!isLoggedIn)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  );
                },
                icon: const Icon(Icons.login, size: 18),
                label: const Text("Login"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (isLoggedIn && !hasStore)
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (isLoggedIn)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: IconButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove("auth_token");
                  await prefs.remove("user_data");
                  setState(() => isLoggedIn = false);
                },
                icon: const Icon(Icons.logout),
                color: Colors.red[400],
              ),
            )
        ],
      ),

      // ========================= BODY =========================
      body: RefreshIndicator(
        onRefresh: loadProducts,
        color: const Color(0xFF667eea),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================== HERO SECTION HOMEPAGE ===========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cari Produk Favoritmu!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Semua produk tersedia di sini",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================== SEARCH BAR ===========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
                      hintText: "Cari produk yang Anda inginkan...",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      searchText = value;

                      if (_debounce?.isActive ?? false) _debounce!.cancel();

                      _debounce = Timer(const Duration(milliseconds: 400), () {
                        searchProducts(value);
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================== DROPDOWN CATEGORY ===========================
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
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),

                    loadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(Icons.category, color: Color(0xFF667eea)),
                                hintText: "Pilih kategori",
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
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =========================== GRID PRODUK (HOMEPAGE STYLE) ===========================
              loadingProducts
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF667eea),
                        ),
                      ),
                    )
                  : products.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  "Produk tidak ditemukan",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, index) {
                              final p = products[index];
                              final img =
                                  (p["images"] is List && p["images"].isNotEmpty)
                                      ? p["images"][0]["gambar"]
                                      : null;

                              return GestureDetector(
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: img != null
                                            ? Image.network(
                                                img,
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                height: 140,
                                                width: double.infinity,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image, size: 50),
                                              ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p["nama_produk"] ?? "-",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF2D3748),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Rp ${p["harga"]}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF667eea),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              p["nama_toko"] ?? "Toko tidak ada",
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
                        ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
