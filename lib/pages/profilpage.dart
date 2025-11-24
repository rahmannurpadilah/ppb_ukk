import 'package:apiflutter/pages/daftartoko.dart';
import 'package:apiflutter/pages/storedetailpage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool loading = true;
  Map<String, dynamic>? user;
  Map<String, dynamic>? toko;
  String? error;

  // FORM CONTROLLERS
  final namaCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final kontakCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);

    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        loading = false;
        user = null;
        toko = null;
      });
      return;
    }

    try {
      final u = await ApiService().getProfile();
      final t = await ApiService().getMyToko();

      if (u["success"] == true) {
        user = u["data"];
        namaCtrl.text = user?["nama"] ?? "";
        usernameCtrl.text = user?["username"] ?? "";
        kontakCtrl.text = user?["kontak"] ?? "";
      }

      if (t["success"] == true) {
        toko = t["data"];
      }
    } catch (e) {
      error = "$e";
    }

    if (mounted) setState(() => loading = false);
  }

  // LOGOUT
  Future<void> _logout() async {
    final res = await ApiService().logout();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"])),
    );

    if (res["success"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    }
  }

  // UPDATE PROFIL
  Future<void> _updateProfile() async {
    final api = ApiService();
    final res = await api.updateProfile(
      nama: namaCtrl.text.trim(),
      username: usernameCtrl.text.trim(),
      kontak: kontakCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Update gagal")),
    );

    if (res["success"] == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil")),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              ).then((_) => _loadProfile());
            },
            child: const Text("Login"),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Informasi Profil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                labelText: "Nama",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: kontakCtrl,
              decoration: const InputDecoration(
                labelText: "Kontak",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Update Profil"),
              ),
            ),

            const SizedBox(height: 30),

            const Text("Toko Saya",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _buildStoreCard(),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // STORE CARD SIMPLE (ANTI ERROR)
  // ================================
  Widget _buildStoreCard() {
    if (toko == null) {
      return Column(
        children: [
          const Text("Anda belum memiliki toko."),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaftarTokoPage()),
              ).then((_) => _loadProfile());
            },
            child: const Text("Daftar Toko"),
          )
        ],
      );
    }

    final nama = toko!["nama_toko"]?.toString() ?? "-";
    final desk = toko!["deskripsi"]?.toString() ?? "-";

    // FIX GAMBAR NULL / MAP / STRING RUSAK
    final raw = toko!["gambar"];
    String gambar = "";

    if (raw is String && raw.isNotEmpty) {
      gambar = raw;
    } else if (raw is Map && raw["url"] != null) {
      gambar = raw["url"];
    } else {
      gambar = "";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // ============ AVATAR 40X40 SAFE =============
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: gambar.isNotEmpty
                  ? Image.network(
                      gambar,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.store, color: Colors.white, size: 20),
                    )
                  : const Icon(Icons.store,
                      color: Colors.white, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  desk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Column(
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreDetailPage(toko!, const []),
                      ),
                    );
                  },
                  child: const Text("Lihat"),
                ),
              ),
              const SizedBox(height: 6),

              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Edit"),
                ),
              ),
              const SizedBox(height: 6),

              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Hapus"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
