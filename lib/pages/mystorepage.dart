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
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
      return;
    }

    final tokoRes = await ApiService().getMyToko();

    if (tokoRes["success"] != true) {
      if (tokoRes["status"] == 401) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
        return;
      }

      error = tokoRes["message"];
      toko = null;
      setState(() => loading = false);
      return;
    }

    toko = tokoRes["data"];

    final productRes = await ApiService().getMyProduct();

    if (productRes["success"] == true) {
      produk = List<Map<String, dynamic>>.from(productRes["produk"]);
    } else {
      produk = [];
    }

    if (mounted) setState(() => loading = false);

    if (toko == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DaftarTokoPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Toko Saya",
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF667eea)),
            )
          : error != null
              ? Center(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : StoreDetailPage(
                  toko!,
                  produk,
                ),

      // ==============================
      // 🔥 Floating Button Tambah Produk
      // ==============================
      floatingActionButton: toko == null
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF667eea),
              elevation: 4,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                );

                // refresh produk setelah tambah baru
                _loadStoreData();
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
