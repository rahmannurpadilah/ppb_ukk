// lib/pages/edit_toko_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EditTokoPage extends StatefulWidget {
  final Map<String, dynamic> toko;
  const EditTokoPage({required this.toko, super.key});

  @override
  State<EditTokoPage> createState() => _EditTokoPageState();
}

class _EditTokoPageState extends State<EditTokoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController namaCtrl;
  late TextEditingController deskCtrl;
  late TextEditingController kontakCtrl;
  late TextEditingController alamatCtrl;

  File? imageFile;         // Aplikasi Android
  Uint8List? imageBytes;   // Browser/Web
  String? imageName;

  bool loading = false;
  String? errorMsg;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final t = widget.toko;
    namaCtrl = TextEditingController(text: (t['nama_toko'] ?? t['nama'] ?? '').toString());
    deskCtrl = TextEditingController(text: (t['deskripsi'] ?? '').toString());
    kontakCtrl = TextEditingController(text: (t['kontak_toko'] ?? t['kontak'] ?? '').toString());
    alamatCtrl = TextEditingController(text: (t['alamat'] ?? '').toString());
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    deskCtrl.dispose();
    kontakCtrl.dispose();
    alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMsg = null;
    });

    final api = ApiService();

    final id = widget.toko['id'] ??
        widget.toko['id_toko'] ??
        widget.toko['id_store'];

    final result = await api.updateToko(
      id: id,
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

    setState(() => loading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'] ?? "Toko diperbarui")));
      Navigator.pop(context, true);
    } else {
      setState(() => errorMsg = result['message'] ?? "Gagal memperbarui toko");
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialImage = widget.toko['gambar']?.toString();

    Widget preview;
    if (kIsWeb) {
      preview = imageBytes != null
          ? Image.memory(imageBytes!, width: double.infinity, height: 150, fit: BoxFit.cover)
          : (initialImage != null && initialImage.isNotEmpty
              ? Image.network(initialImage, width: double.infinity, height: 150, fit: BoxFit.cover)
              : const Center(child: Text("Tap untuk upload gambar (web)")));
    } else {
      preview = imageFile != null
          ? Image.file(imageFile!, width: double.infinity, height: 150, fit: BoxFit.cover)
          : (initialImage != null && initialImage.isNotEmpty
              ? Image.network(initialImage, width: double.infinity, height: 150, fit: BoxFit.cover)
              : const Center(child: Text("Tap untuk upload gambar")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Toko")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (errorMsg != null)
                Text(errorMsg!, style: const TextStyle(color: Colors.red)),

              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: "Nama Toko"),
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: deskCtrl,
                decoration: const InputDecoration(labelText: "Deskripsi"),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: kontakCtrl,
                decoration: const InputDecoration(labelText: "Kontak"),
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: alamatCtrl,
                decoration: const InputDecoration(labelText: "Alamat"),
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey[200],
                  child: preview,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Simpan Perubahan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
