import 'package:flutter/material.dart';
import 'package:apiflutter/services/api_service.dart';
import 'package:apiflutter/pages/editproductpage.dart';
import 'package:apiflutter/pages/detailproductpage.dart';

class StoreDetailPage extends StatelessWidget {
  final Map<String, dynamic> toko;
  final List<Map<String, dynamic>> produk;

  final VoidCallback? onRefresh;   // ⭐ callback agar MyStorePage bisa refresh

  const StoreDetailPage(
    this.toko,
    this.produk, {
    this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          toko["nama_toko"] ?? "Toko Saya",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // =================== INFO TOKO ====================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toko["nama_toko"] ?? "-",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      toko["deskripsi"] ?? "Tidak ada deskripsi",
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Color(0xFF667eea)),
                        const SizedBox(width: 8),
                        Text(toko["kontak_toko"] ?? "-"),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // =================== LIST PRODUK ====================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Produk Saya",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ),

            produk.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      "Belum ada produk",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                :

                // =================== GRID PRODUK ====================
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.66,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: produk.length,
                    itemBuilder: (context, index) {
                      final p = produk[index];
                      final gambar = (p["images"] is List && p["images"].isNotEmpty)
                          ? p["images"][0]["url"]
                          : null;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailProductPage(product: p),
                            ),
                          );
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ================= IMAGE =================
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: gambar != null
                                    ? Image.network(
                                        gambar,
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 130,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p["nama_produk"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rp ${_formatHarga(p["harga"])}",
                                      style: const TextStyle(
                                        color: Color(0xFF667eea),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // ================= BUTTON EDIT & DELETE =================
                                    Row(
                                      children: [
                                        // ⭐ EDIT BUTTON
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditProductPage(product: p),
                                              ),
                                            );
                                            if (onRefresh != null) onRefresh!();
                                          },
                                        ),

                                        // ⭐ DELETE BUTTON
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            _hapusProduk(context, p["id_produk"]);
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // ===================== HAPUS PRODUK ===================== ⭐
  void _hapusProduk(BuildContext context, int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Hapus Produk"),
          content: const Text("Yakin ingin menghapus produk ini?"),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: const Text("Hapus"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final res = await ApiService().deleteProduct(id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"])),
    );

    if (res["success"] == true && onRefresh != null) {
      onRefresh!();
    }
  }

  String _formatHarga(dynamic value) {
    final intVal = int.tryParse(value.toString()) ?? 0;
    return intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
