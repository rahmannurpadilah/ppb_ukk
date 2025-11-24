// lib/pages/mystorepage.dart
import 'package:apiflutter/pages/addproductpage.dart';
import 'package:flutter/material.dart';
import 'package:apiflutter/services/api_service.dart';
import 'package:apiflutter/pages/login.dart';
import 'package:apiflutter/pages/daftartoko.dart';
import 'package:apiflutter/pages/storedetailpage.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  bool loading = true;
  bool isLoggedIn = false;

  Map<String, dynamic>? toko;
  List<Map<String, dynamic>> produk = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      loading = true;
      error = null;
    });

    final token = await ApiService.getToken();
    isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      setState(() => loading = false);
      return;
    }

    // ========== AMBIL DATA TOKO ==========
    final tokoRes = await ApiService().getMyToko();

    if (tokoRes["success"] != true) {
      // Token kadaluwarsa
      if (tokoRes["status"] == 401) {
        isLoggedIn = false;
      }

      error = tokoRes["message"];
      toko = null;
      setState(() => loading = false);
      return;
    }

    toko = tokoRes["data"];

    // ========== AMBIL PRODUK TOKO ==========
    final productRes = await ApiService().getMyProduct();

    if (productRes["success"] == true) {
      produk = List<Map<String, dynamic>>.from(productRes["produk"]);
    } else {
      produk = [];
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF667eea)),
            )

          // ========== BELUM LOGIN ==========
          : !isLoggedIn
              ? _buildNotLoggedIn()

              // ========== ERROR AMBIL DATA ==========
              : error != null
                  ? _buildErrorState()

                  // ========== BELUM PUNYA TOKO ==========
                  : toko == null
                      ? _buildNoStore()

                      // ========== TAMPILKAN TOKO ==========
                      : StoreDetailPage(toko!, produk),

      // ========== FLOATING BUTTON ==========
      floatingActionButton: (isLoggedIn && toko != null)
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF667eea),
              elevation: 4,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                );
                _loadStoreData();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Tambah Produk",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // ========== NOT LOGGED IN STATE ==========
  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.2),
                    const Color(0xFF764ba2).withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_off_outlined,
                size: 80,
                color: Color(0xFF667eea),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              "Login Diperlukan",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              "Silakan login terlebih dahulu untuk mengelola toko dan produk Anda",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            // Login Button
            SizedBox(
              width: 220,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  ).then((_) => _loadStoreData());
                },
                icon: const Icon(Icons.login, size: 22),
                label: const Text(
                  "Login Sekarang",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF667eea).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),

            const SizedBox(height: 12),

            // Error Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                error ?? "Terjadi kesalahan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Retry Button
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loadStoreData,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  "Coba Lagi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== NO STORE STATE ==========
  Widget _buildNoStore() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.2),
                    const Color(0xFF764ba2).withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store_mall_directory_outlined,
                size: 80,
                color: Color(0xFF667eea),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              "Belum Punya Toko",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              "Daftarkan toko Anda sekarang dan mulai berjualan produk kepada pelanggan",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            // Feature List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.inventory_2,
                    title: "Kelola Produk",
                    description: "Tambah dan kelola produk dengan mudah",
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.analytics,
                    title: "Pantau Penjualan",
                    description: "Lihat performa toko Anda",
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.storefront,
                    title: "Branding Toko",
                    description: "Buat identitas toko yang unik",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Daftar Toko Button
            SizedBox(
              width: 240,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DaftarTokoPage()),
                  ).then((_) => _loadStoreData());
                },
                icon: const Icon(Icons.add_business, size: 22),
                label: const Text(
                  "Daftar Toko Sekarang",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF667eea).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF667eea),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}