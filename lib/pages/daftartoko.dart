// lib/pages/daftar_toko_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class DaftarTokoPage extends StatefulWidget {
  const DaftarTokoPage({super.key});

  @override
  State<DaftarTokoPage> createState() => _DaftarTokoPageState();
}

class _DaftarTokoPageState extends State<DaftarTokoPage> {
  final _formKey = GlobalKey<FormState>();

  final namaCtrl = TextEditingController();
  final deskCtrl = TextEditingController();
  final kontakCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();

  // ANDROID
  File? imageFile;

  // WEB
  Uint8List? imageBytes;
  String? imageName;

  final ImagePicker _picker = ImagePicker();

  bool loading = false;
  String? errorMsg;

  // ===================== UPLOAD GAMBAR =====================
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();

      setState(() {
        imageBytes = bytes;
        imageName = picked.name;
        imageFile = null;
      });
    } else {
      setState(() {
        imageFile = File(picked.path);
        imageName = picked.name;
        imageBytes = null;
      });
    }
  }

  // ===================== SUBMIT =====================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (imageFile == null && imageBytes == null) {
      setState(() => errorMsg = "Gambar toko wajib diupload");
      return;
    }

    setState(() {
      loading = true;
      errorMsg = null;
    });

    final api = ApiService();

    final result = await api.createStore(
      namaToko: namaCtrl.text.trim(),
      deskripsi: deskCtrl.text.trim(),
      kontakToko: kontakCtrl.text.trim(),
      alamat: alamatCtrl.text.trim(),

      // ANDROID
      imagePath: imageFile?.path,

      // WEB
      imageBytes: imageBytes,
      imageFilename: imageName,
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toko berhasil dibuat")),
      );
      Navigator.pop(context);
    } else {
      setState(() => errorMsg = result['message'] ?? "Gagal membuat toko");
    }
  }

  // ===================== INPUT BUILDER =====================
  Widget buildInput({
    required String label,
    required TextEditingController controller,
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = (kIsWeb)
        ? (imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  imageBytes!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              )
            : _emptyImage())
        : (imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  imageFile!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              )
            : _emptyImage());

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Buat Toko Baru",
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (errorMsg != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(errorMsg!)),
                    ],
                  ),
                ),

              buildInput(label: "Nama Toko", controller: namaCtrl),
              buildInput(label: "Deskripsi", controller: deskCtrl, maxLines: 2),
              buildInput(label: "Kontak", controller: kontakCtrl),
              buildInput(label: "Alamat", controller: alamatCtrl, maxLines: 2),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: preview,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          "Daftarkan Toko",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            "Tap untuk upload gambar",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
