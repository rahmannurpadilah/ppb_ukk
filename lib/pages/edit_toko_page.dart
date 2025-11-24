import 'dart:io';
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

  File? imageFile;

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

  // ============================
  // PICK IMAGE (Mobile only)
  // ============================
  Future<void> pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload gambar belum mendukung Web")),
      );
      return;
    }

    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked == null) return;

    setState(() => imageFile = File(picked.path));
  }

  // ============================
  // SUBMIT UPDATE
  // ============================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
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
        imageBytes: null,
        imageFilename: null,
      );

      if (res["success"] != true) {
        setState(() => errorMsg = res["message"]);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toko berhasil diperbarui")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => errorMsg = "Exception: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = imageFile != null
        ? Image.file(
            imageFile!,
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
          )
        : (widget.toko["gambar"] != null && widget.toko["gambar"] != ""
            ? Image.network(
                widget.toko["gambar"],
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              )
            : const Center(child: Text("Tap untuk pilih gambar")));

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Toko")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (errorMsg != null)
                Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red),
                ),

              // ================= IMAGE PICKER =================
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey[200],
                  child: preview,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: "Nama Toko"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Nama tidak boleh kosong" : null,
              ),

              TextFormField(
                controller: kontakCtrl,
                decoration: const InputDecoration(labelText: "Kontak Toko"),
              ),

              TextFormField(
                controller: alamatCtrl,
                decoration: const InputDecoration(labelText: "Alamat"),
              ),

              TextFormField(
                controller: deskCtrl,
                decoration: const InputDecoration(labelText: "Deskripsi"),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text("Perbarui Toko"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
