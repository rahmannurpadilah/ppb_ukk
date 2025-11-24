import 'dart:io';
import 'package:apiflutter/pages/mystorepage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class UpdateProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const UpdateProductPage({super.key, required this.product});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();

  final namaCtrl = TextEditingController();
  final hargaCtrl = TextEditingController();
  final stokCtrl = TextEditingController();
  final deskCtrl = TextEditingController();

  String? selectedKategoriId;
  File? imageFile;

  bool loading = false;
  String? errorMsg;

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _prefillData();
    _loadCategories();
  }

  void _prefillData() {
    final p = widget.product;

    namaCtrl.text = p["nama_produk"] ?? "";
    hargaCtrl.text = p["harga"].toString();
    stokCtrl.text = p["stok"].toString();
    deskCtrl.text = p["deskripsi"] ?? "";
    selectedKategoriId = p["id_kategori"].toString();
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

      final res = await api.updateProduct(
        idProduk: widget.product["id_produk"],
        idKategori: int.parse(selectedKategoriId!),
        namaProduk: namaCtrl.text.trim(),
        harga: int.parse(hargaCtrl.text.trim()),
        stok: int.parse(stokCtrl.text.trim()),
        deskripsi: deskCtrl.text.trim(),
      );

      if (res['success'] != true) {
        setState(() => errorMsg = res['message']);
        return;
      }

      if (imageFile != null) {
        await api.uploadProductImage(
          idProduk: widget.product["id_produk"],
          imageFile: imageFile!,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produk berhasil diupdate")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyStorePage()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => loading = false);
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
        : widget.product["images"] != null &&
                widget.product["images"].isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.product["images"][0]["gambar"],
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
          "Update Produk",
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
                        Text("Perbarui informasi produk Anda",
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
                              "Update Produk",
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
