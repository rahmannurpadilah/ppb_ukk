import 'dart:io';
import 'package:apiflutter/pages/mainpage.dart';
// import 'package:apiflutter/pages/mystorepage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final namaCtrl = TextEditingController();
  final hargaCtrl = TextEditingController();
  final stokCtrl = TextEditingController(text: '1');
  final deskCtrl = TextEditingController();

  String? selectedKategoriId;
  File? imageFile;

  bool loading = false;
  String? errorMsg;

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final res = await ApiService().getCategory();

    if (res['success'] == true) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(res['data']);
        if (categories.isNotEmpty) {
          selectedKategoriId = categories.first['id_kategori'].toString();
        }
      });
    }
  }

  Future<void> pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload gambar belum mendukung Web")),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() => imageFile = File(picked.path));
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final api = ApiService();

      final res = await api.createProduct(
        idKategori: int.parse(selectedKategoriId!),
        namaProduk: namaCtrl.text.trim(),
        harga: hargaCtrl.text.trim(),
        stok: stokCtrl.text.trim(),
        deskripsi: deskCtrl.text.trim(),
      );

      if (res['success'] != true) {
        // tetap tampilkan error tetapi tetap pindah halaman
        errorMsg = res['message'];
      } else {
        final data = res['data'];
        final int? productId = data?['id_produk'] ?? data?['id'];

        if (productId != null && imageFile != null) {
          await api.uploadProductImage(
            idProduk: productId,
            imageFile: imageFile!,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produk berhasil ditambahkan")),
          );
        }
      }

    } finally {
      if (!mounted) return;

      // ================================
      // SELALU PINDAH KE MyStorePage
      // ================================
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage(initialIndex: 2)),
        (route) => false,
      );

      setState(() => loading = false);
    }
  }


  Widget buildInput({
    required String label,
    IconData? icon,
    required TextEditingController controller,
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = imageFile != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageFile!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text("Tap untuk upload gambar",
                  style: TextStyle(color: Colors.grey[600])),
            ],
          );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        title: const Text(
          "Tambah Produk",
          style: TextStyle(color: Color(0xFF2D3748)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_box,
                            size: 48,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Tambah Produk Baru",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Lengkapi informasi produk Anda",
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (errorMsg != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(errorMsg!,
                          style: TextStyle(color: Colors.red[700])),
                    ),

                  const SizedBox(height: 16),

                  buildInput(
                      label: "Nama Produk",
                      icon: Icons.shopping_bag_outlined,
                      controller: namaCtrl),

                  buildInput(
                      label: "Harga",
                      icon: Icons.payments_outlined,
                      controller: hargaCtrl,
                      type: TextInputType.number),

                  buildInput(
                      label: "Stok",
                      icon: Icons.numbers,
                      controller: stokCtrl,
                      type: TextInputType.number),

                  buildInput(
                      label: "Deskripsi",
                      icon: Icons.description_outlined,
                      controller: deskCtrl,
                      maxLines: 3),

                  DropdownButtonFormField<String>(
                    value: selectedKategoriId,
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c['id_kategori'].toString(),
                        child: Text(c['nama_kategori']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedKategoriId = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Pilih kategori" : null,
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: preview,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              "Tambah Produk",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
