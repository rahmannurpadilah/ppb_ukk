import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ApiService{
  final String baseUrl = "https://learncode.biz.id/api";

  // Login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');

    // JANGAN pakai application/json
    final headers = {
      'Accept': 'application/json',
    };

    // Gunakan format form-urlencoded
    final body = {
      'username': username,
      'password': password,
    };

    try {
      final res = await http.post(
        uri,
        headers: headers,
        body: body,   // <= bukan jsonEncode
      );

      final Map<String, dynamic> bodyJson = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final token = bodyJson['token']?.toString();
        final data = bodyJson['data'];

        // Simpan token
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
        }

        // Simpan user data
        if (data != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data));
        }

        return {
          'success': true,
          'message': bodyJson['message'] ?? 'Login berhasil.',
          'token': token,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': bodyJson['message'] ?? 'Login gagal',
          'status': res.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Simpan token ke SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Ambil token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Hapus token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, tidak bisa logout.'
        };
      }

      final uri = Uri.parse('$baseUrl/logout');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // POST tanpa body
      final res = await http.post(uri, headers: headers);

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // Hapus token dan data user setelah logout
        await prefs.remove('auth_token');
        await prefs.remove('user_data');

        return {
          'success': true,
          'message': body['message'] ?? 'Logout berhasil.'
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Logout gagal.',
        'status': res.statusCode
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Registrasi
  Future<Map<String, dynamic>> register({
    required String nama,
    required String kontak,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/register');

    // sesuai Postman → jangan pakai Content-Type json
    final headers = {
      'Accept': 'application/json',
    };

    // body pakai form-urlencoded
    final body = {
      'nama': nama,
      'kontak': kontak,
      'username': username,
      'password': password,
    };

    try {
      final res = await http.post(uri, headers: headers, body: body);
      final Map<String, dynamic> json = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // TIDAK auto login → jangan simpan token di sini!
        return {
          'success': true,
          'message': json['message'] ?? 'Register berhasil',
          'data': json['data'],
          'token': json['token'], // hanya dikembalikan, bukan disimpan
        };
      }

      if (res.statusCode == 400 || res.statusCode == 422) {
        return {
          'success': false,
          'message': json['message'] ?? json['errors'] ?? 'Data tidak valid'
        };
      }

      return {
        'success': false,
        'message': 'Server error (${res.statusCode})'
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Get profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Ambil token lewat getToken()
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, silakan login.'
        };
      }

      final uri = Uri.parse('$baseUrl/profile');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.get(uri, headers: headers);
      final body = jsonDecode(res.body);

      // ================= SUCCESS =================
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(body['data']);

        // simpan user_data tembakan terbaru
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data));

        return {
          'success': true,
          'data': data,
          'message': body['message'] ?? 'Berhasil mengambil profil.',
        };
      }

      // ================= TOKEN INVALID =================
      if (res.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('user_data');

        return {
          'success': false,
          'message': 'Token sudah kadaluarsa atau tidak valid.',
          'status': 401,
        };
      }

      // ================= ERROR LAIN =================
      return {
        'success': false,
        'message': body['message'] ?? 'Gagal mengambil profil.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String kontak,
    required String username,
    String? password,
  }) async {
    try {
      // Ambil token via static method
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, silakan login terlebih dahulu.'
        };
      }

      final uri = Uri.parse('$baseUrl/profile/update');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Body sesuai Postman → form-data (bukan JSON)
      final body = {
        'nama': nama,
        'kontak': kontak,
        'username': username,
        'password': password,
      };

      final res = await http.post(uri, headers: headers, body: body);
      final json = jsonDecode(res.body);

      // ================= SUCCESS =================
      if (res.statusCode == 200) {
        final updated = Map<String, dynamic>.from(json['data']);

        // Simpan user_data baru ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updated));

        return {
          'success': true,
          'message': json['message'] ?? 'Profil berhasil diperbarui.',
          'data': updated,
        };
      }

      // ================= TOKEN INVALID =================
      if (res.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('user_data');

        return {
          'success': false,
          'message': 'Token tidak valid atau sudah kadaluarsa.',
          'status': 401,
        };
      }

      // ================= ERROR LAIN =================
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal memperbarui profil.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Create Toko
  Future<Map<String, dynamic>> createStore({
    required String namaToko,
    required String deskripsi,
    required String kontakToko,
    required String alamat,
    String? imagePath,          // ANDROID
    Uint8List? imageBytes,      // WEB
    String? imageFilename,      // WEB filename
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, silakan login dulu.'
        };
      }

      final uri = Uri.parse('$baseUrl/stores/save');

      final request = http.MultipartRequest('POST', uri);

      // Header
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Fields
      request.fields['nama_toko'] = namaToko;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kontak_toko'] = kontakToko;
      request.fields['alamat'] = alamat;

      // =========================
      // 🔥 FILE UPLOAD HANDLER
      // =========================
      if (imageBytes != null) {
        // WEB upload
        request.files.add(
          http.MultipartFile.fromBytes(
            'gambar',
            imageBytes,
            filename: imageFilename ?? 'image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else if (imagePath != null) {
        // ANDROID upload
        request.files.add(
          await http.MultipartFile.fromPath(
            'gambar',
            imagePath,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': json['message'] ?? 'Toko berhasil dibuat.',
          'data': json['data'],
        };
      }

      return {
        'success': false,
        'message': json['message'] ?? 'Gagal membuat toko.',
        'status': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Update Toko
  Future<Map<String, dynamic>> updateToko({
    required dynamic id,
    required String namaToko,
    required String deskripsi,
    required String kontakToko,
    required String alamat,
    String? imagePath,          // ANDROID
    Uint8List? imageBytes,      // WEB
    String? imageFilename,      // WEB
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, silakan login dulu.'
        };
      }

      final uri = Uri.parse('$baseUrl/stores/update/$id'); // API update yang benar

      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // TEXT FIELDS
      request.fields['nama_toko'] = namaToko;
      request.fields['deskripsi'] = deskripsi;
      request.fields['kontak_toko'] = kontakToko;
      request.fields['alamat'] = alamat;

      // ======================
      // 🔥 Handle FILE Upload
      // ======================
      if (imageBytes != null) {
        // WEB
        request.files.add(
          http.MultipartFile.fromBytes(
            'gambar',
            imageBytes,
            filename: imageFilename ?? "gambar.jpg",
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else if (imagePath != null) {
        // ANDROID
        request.files.add(
          await http.MultipartFile.fromPath(
            'gambar',
            imagePath,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'Toko berhasil diperbarui.',
          'data': json['data'],
        };
      }

      return {
        'success': false,
        'message': json['message'] ?? 'Gagal memperbarui toko.',
        'status': response.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Get Toko Saya
  Future<Map<String, dynamic>> getMyToko() async {
    try {
      // Ambil token
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, silakan login terlebih dahulu.'
        };
      }

      final uri = Uri.parse('$baseUrl/stores');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.get(uri, headers: headers);
      final json = jsonDecode(res.body);

      // ============= SUCCESS =============
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(json['data']);

        return {
          'success': true,
          'message': json['message'] ?? 'Data toko berhasil diambil.',
          'data': data,
        };
      }

      // ============= TOKEN INVALID =============
      if (res.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('user_data');

        return {
          'success': false,
          'message': 'Token tidak valid atau sudah kadaluarsa.',
          'status': 401,
        };
      }

      // ============= ERROR LAIN =============
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengambil data toko.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Delete Toko
  Future<Map<String, dynamic>> deleteToko(int idToko) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          "success": false,
          "message": "Token tidak ditemukan, silakan login."
        };
      }

      final uri = Uri.parse('$baseUrl/stores/$idToko/delete');

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final res = await http.post(uri, headers: headers);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          "success": true,
          "message": json["message"] ?? "Toko berhasil dihapus.",
          "data": json["data"],
        };
      }

      return {
        "success": false,
        "message": json["message"] ?? "Gagal menghapus toko.",
        "status": res.statusCode,
      };
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

  // Get Categories
  Future<Map<String, dynamic>> getCategory() async {
    try {
      final uri = Uri.parse('$baseUrl/categories');

      // Tidak perlu bearer token → No Auth
      final headers = {
        'Accept': 'application/json',
      };

      final res = await http.get(uri, headers: headers);
      final json = jsonDecode(res.body);

      // ========= SUCCESS =========
      if (res.statusCode == 200) {
        final List<dynamic> list = json['data'] ?? [];

        return {
          'success': true,
          'message': json['message'] ?? 'Daftar kategori berhasil diambil.',
          'data': list
              .map((e) => Map<String, dynamic>.from(e))
              .toList(), // list kategori
        };
      }

      // ========= ERROR =========
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengambil kategori.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Get Products
  Future<Map<String, dynamic>> getProducts() async {
    try {
      final uriBase = '$baseUrl/products';

      final headers = {
        'Accept': 'application/json',
      };

      int page = 1;
      int lastPage = 1;

      List<Map<String, dynamic>> allProducts = [];

      do {
        final url = Uri.parse('$uriBase?page=$page');
        final res = await http.get(url, headers: headers);

        if (res.statusCode != 200) {
          final body = jsonDecode(res.body);
          return {
            'success': false,
            'message': body['message'] ?? 'Gagal mengambil produk.',
            'status': res.statusCode,
          };
        }

        final body = jsonDecode(res.body);

        // Ambil pagination
        if (body['pagination'] != null) {
          lastPage = int.tryParse(body['pagination']['last_page'].toString()) ?? 1;
        }

        // Ambil data list produk
        if (body['data'] != null && body['data'] is List) {
          final List listData = body['data'];
          allProducts.addAll(listData.map((e) => Map<String, dynamic>.from(e)));
        }

        page++;

      } while (page <= lastPage);

      return {
        'success': true,
        'message': 'Daftar produk berhasil diambil.',
        'total': allProducts.length,
        'products': allProducts,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Detail Product
  Future<Map<String, dynamic>> detailProduct(int idProduk) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$idProduk/show');

      // Tidak menggunakan bearer token (NO AUTH)
      final headers = {
        'Accept': 'application/json',
      };

      final res = await http.get(uri, headers: headers);
      final json = jsonDecode(res.body);

      // ============== SUCCESS ==============
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(json['data']);

        // pastikan images adalah list
        List images = [];
        if (data.containsKey('images') && data['images'] is List) {
          images = data['images'];
        }

        return {
          'success': true,
          'message': json['message'] ?? 'Detail produk berhasil diambil.',
          'data': data,
          'images': images, // <-- ADD IMAGES HERE
        };
      }

      // ============== ERROR ==============
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengambil detail produk.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Daftar Product Toko
  Future<Map<String, dynamic>> getMyProduct() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Harap login terlebih dahulu'};
      }

      final uri = Uri.parse('$baseUrl/stores/products');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.get(uri, headers: headers);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final data = json['data'];

        List produk = data['produk'] ?? [];
        List<Map<String, dynamic>> out = produk.map((p) => {
              'id_produk': p['id_produk'],
              'nama_produk': p['nama_produk'],
              'nama_kategori': p['nama_kategori'],
              'harga': p['harga'],
              'stok': p['stok'],
              'deskripsi': p['deskripsi'],
              'tanggal_upload': p['tanggal_upload'],
              'images': p['images'] ?? [],
            }).toList();

        return {
          'success': true,
          'nama_toko': data['nama_toko'],
          'id_toko': data['id_toko'],
          'produk': out,
        };
      }

      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengambil data toko',
        'status': res.statusCode
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Get Image Product
  Future<Map<String, dynamic>> getProductImages(int idProduk) async {
    try {
      // Ambil token dari SharedPreferences
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada token, silakan login terlebih dahulu.'
        };
      }

      // URL endpoint
      final uri = Uri.parse('$baseUrl/products/$idProduk/images');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.get(uri, headers: headers);

      final json = jsonDecode(res.body);

      // ================= SUCCESS =================
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'],
          'data': List<Map<String, dynamic>>.from(json['data']),
        };
      }

      // ================= TOKEN INVALID =================
      if (res.statusCode == 401) {
        return {
          'success': false,
          'message': 'Token tidak valid atau kadaluarsa',
          'status': 401,
        };
      }

      // ================= OTHER ERROR =================
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengambil gambar produk.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Search Product
  Future<Map<String, dynamic>> productSearch(String keyword) async {
    try {
      // Base URL + query parameter
      final uri = Uri.parse('$baseUrl/products/search?keyword=$keyword');

      // No Auth → tetap pakai Accept JSON
      final headers = {
        'Accept': 'application/json',
      };

      final res = await http.get(uri, headers: headers);

      final json = jsonDecode(res.body);

      // ======================= SUCCESS =======================
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'Berhasil mengambil hasil pencarian.',
          'data': List<Map<String, dynamic>>.from(json['data'] ?? []),
        };
      }

      // ======================= ERROR =========================
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mencari produk.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Get Product By Category
  Future<Map<String, dynamic>> getProductsByCategory(int idKategori) async {
    try {
      final uri = Uri.parse('$baseUrl/products/category/$idKategori');

      // Tanpa token → No Auth
      final headers = {
        'Accept': 'application/json',
      };

      final res = await http.get(uri, headers: headers);
      final json = jsonDecode(res.body);

      // ================= SUCCESS =================
      if (res.statusCode == 200) {

        // data berupa LIST
        final List dataList = json['data'] ?? [];

        final products = dataList.map((e) => Map<String, dynamic>.from(e)).toList();

        return {
          'success': true,
          'message': json['message'] ?? 'Berhasil mengambil produk kategori.',
          'data': products,
        };
      }

      // ================= ERROR =================
      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengambil produk kategori.',
        'status': res.statusCode,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Create Product
  Future<Map<String, dynamic>> createProduct({
    required int idKategori,
    required String namaProduk,
    required String harga,
    required String stok,
    required String deskripsi,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          "success": false,
          "message": "Token tidak ditemukan, silakan login kembali."
        };
      }

      final uri = Uri.parse('$baseUrl/products/save');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        "id_kategori": idKategori,
        "nama_produk": namaProduk,
        "harga": harga,
        "stok": stok,
        "deskripsi": deskripsi,
      });

      final res = await http.post(uri, headers: headers, body: body);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          "success": true,
          "message": json["message"] ?? "Produk berhasil ditambahkan.",
          "data": json["data"],
        };
      }

      return {
        "success": false,
        "message": json["message"] ?? "Gagal menambah produk.",
        "status": res.statusCode,
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Exception: $e",
      };
    }
  }

  // Upload Product Image
  Future<Map<String, dynamic>> uploadProductImage({
    required int idProduk,
    required File imageFile,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          "success": false,
          "message": "Token tidak ditemukan, silakan login kembali."
        };
      }

      final uri = Uri.parse('$baseUrl/products/images/upload');

      var request = http.MultipartRequest("POST", uri);

      // Header Bearer Token
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Form fields
      request.fields['id_produk'] = idProduk.toString();

      // File
      request.files.add(
        await http.MultipartFile.fromPath(
          'gambar',
          imageFile.path,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": json["message"] ?? "Gambar berhasil diupload.",
          "data": json["data"],
        };
      }

      return {
        "success": false,
        "message": json["message"] ?? "Gagal upload gambar.",
        "status": response.statusCode,
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Exception: $e",
      };
    }
  }

  // Update Product
  Future<Map<String, dynamic>> updateProduct({
    required int idProduk,
    required int idKategori,
    required String namaProduk,
    required int harga,
    required int stok,
    required String deskripsi,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan, silakan login kembali.'
        };
      }

      final uri = Uri.parse('$baseUrl/products/save');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        "id_produk": idProduk,
        "id_kategori": idKategori,
        "nama_produk": namaProduk,
        "harga": harga,
        "stok": stok,
        "deskripsi": deskripsi,
      });

      final res = await http.post(uri, headers: headers, body: body);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'],
          'data': json['data'],
        };
      }

      return {
        'success': false,
        'message': json['message'] ?? 'Gagal mengupdate produk.',
        'status': res.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Delete Product
  Future<Map<String, dynamic>> deleteProduct(int idProduk) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan, silakan login kembali.'
        };
      }

      final uri = Uri.parse('$baseUrl/products/$idProduk/delete');

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.post(uri, headers: headers);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'],
          'data': json['data'],
        };
      }

      return {
        'success': false,
        'message': json['message'] ?? 'Gagal menghapus produk.',
        'status': res.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Delete Product Image
  Future<Map<String, dynamic>> deleteProductImage(int idGambar) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          "success": false,
          "message": "Token tidak ditemukan, silakan login."
        };
      }

      final uri = Uri.parse('$baseUrl/products/images/$idGambar/delete');

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final res = await http.post(uri, headers: headers);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          "success": true,
          "message": json["message"] ?? "Gambar berhasil dihapus.",
          "data": json["data"],
        };
      }

      return {
        "success": false,
        "message": json["message"] ?? "Gagal menghapus gambar.",
        "status": res.statusCode,
      };
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

}
