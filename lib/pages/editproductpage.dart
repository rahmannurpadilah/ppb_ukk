import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'mainpage.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  final namaCtrl = TextEditingController();
  final hargaCtrl = TextEditingController();
  final stokCtrl = TextEditingController();
  final deskCtrl = TextEditingController();

  String? selectedKategoriId;

  File? imageFile; // ⭐ gambar baru
  String? oldImageUrl; // ⭐ gambar lama

  bool loading = false;
  String? errorMsg;

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _setInitialData();
    _loadCategories();
  }

  void _setInitialData() {
    final p = widget.product;

    namaCtrl.text = p["nama_produk"] ?? "";
    hargaCtrl.text = p["harga"]?.toString() ?? "";
    stokCtrl.text = p["stok"]?.toString() ?? "";
    deskCtrl.text = p["deskripsi"] ?? "";

    selectedKategoriId = p["id_kategori"]?.toString();

    // Ambil gambar pertama jika ada
    if (p["images"] is List && p["images"].isNotEmpty) {
      oldImageUrl = p["images"][0]["url"];
    }
  }

  Future<void> _loadCategories() async {
    final res = await ApiService().getCategory();

    if (res['success'] == true) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(res['data']);
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
      imageQuality: 85,
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

    final p = widget.product;

    try {
      final api = ApiService();

      final res = await api.updateProduct(
        idProduk: p["id_produk"],
        idKategori: int.parse(selectedKategoriId!),
        namaProduk: namaCtrl.text.trim(),
        harga: int.parse(hargaCtrl.text.trim()),
        stok: int.parse(stokCtrl.text.trim()),
        deskripsi: deskCtrl.text.trim(),
      );

      if (res["success"] != true) {
        errorMsg = res["message"];
      } else {
        // jika user pilih gambar baru
        if (imageFile != null) {
          await api.uploadProductImage(
            idProduk: p["id_produk"],
            imageFile: imageFile!,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perubahan disimpan")),
          );
        }
      }
    } finally {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage(initialIndex: 2)),
        (route) => false,
      );

      loading = false;
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
        : oldImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  oldImageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "Tap untuk upload gambar",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        title: const Text(
          "Edit Produk",
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
                  // ================= TITLE =================
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
                            Icons.edit,
                            size: 48,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Edit Produk",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Perbarui informasi produk",
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
                      child: Text(
                        errorMsg!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ================= INPUT =================
                  buildInput(
                    label: "Nama Produk",
                    icon: Icons.shopping_bag_outlined,
                    controller: namaCtrl,
                  ),

                  buildInput(
                    label: "Harga",
                    icon: Icons.payments_outlined,
                    controller: hargaCtrl,
                    type: TextInputType.number,
                  ),

                  buildInput(
                    label: "Stok",
                    icon: Icons.numbers,
                    controller: stokCtrl,
                    type: TextInputType.number,
                  ),

                  buildInput(
                    label: "Deskripsi",
                    icon: Icons.description_outlined,
                    controller: deskCtrl,
                    maxLines: 3,
                  ),

                  // ================= KATEGORI =================
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
                    onChanged: (v) {
                      setState(() => selectedKategoriId = v);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ================= UPLOAD GAMBAR =================
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: preview,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= SUBMIT =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              "Simpan Perubahan",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
