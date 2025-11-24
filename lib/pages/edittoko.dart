import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EditTokoPage extends StatefulWidget {
  final Map<String, dynamic> toko;

  const EditTokoPage({super.key, required this.toko});

  @override
  State<EditTokoPage> createState() => _EditTokoPageState();
}

class _EditTokoPageState extends State<EditTokoPage> {
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

  final picker = ImagePicker();

  bool loading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();

    namaCtrl.text = widget.toko["nama_toko"] ?? "";
    deskCtrl.text = widget.toko["deskripsi"] ?? "";
    kontakCtrl.text = widget.toko["kontak_toko"] ?? "";
    alamatCtrl.text = widget.toko["alamat"] ?? "";
  }

  // ========================= PICK IMAGE =========================
  Future<void> pickImage() async {
    final picked = await picker.pickImage(
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
        imageBytes = null;
        imageName = picked.name;
      });
    }
  }

  // ========================= SUBMIT UPDATE =========================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMsg = null;
    });

    final api = ApiService();
    final id = widget.toko["id"] ??
        widget.toko["id_toko"] ??
        widget.toko["id_store"];

    final res = await api.updateToko(
      id: id,
      namaToko: namaCtrl.text.trim(),
      deskripsi: deskCtrl.text.trim(),
      kontakToko: kontakCtrl.text.trim(),
      alamat: alamatCtrl.text.trim(),
      imagePath: imageFile?.path,
      imageBytes: imageBytes,
      imageFilename: imageName,
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? "Toko berhasil diperbarui"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } else {
      setState(() => errorMsg = res["message"]);
    }
  }

  // ========================= FORM INPUT BUILDER =========================
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
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  // ========================= BUILD =========================
  @override
  Widget build(BuildContext context) {
    final preview = (kIsWeb)
        ? (imageBytes != null
            ? _imageMemory()
            : _networkOrEmpty())
        : (imageFile != null
            ? _imageFile()
            : _networkOrEmpty());

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Edit Toko",
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
                _errorBox(),

              buildInput(label: "Nama Toko", controller: namaCtrl),
              buildInput(label: "Deskripsi", controller: deskCtrl, maxLines: 2),
              buildInput(label: "Kontak", controller: kontakCtrl),
              buildInput(label: "Alamat", controller: alamatCtrl, maxLines: 2),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
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
                          "Perbarui Toko",
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

  // ========================= HELPER UI =========================
  Widget _imageMemory() => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          imageBytes!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );

  Widget _imageFile() => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          imageFile!,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
        ),
      );

  Widget _networkOrEmpty() {
    final url = widget.toko["gambar"]?.toString() ?? "";

    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
        ),
      );
    }
    return _emptyImage();
  }

  Widget _emptyImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text("Tap untuk upload gambar",
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
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
    );
  }
}
