import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {

  // Fungsi utama yang dipanggil dari UI (misal saat tombol ditekan)
  Future<Position?> handleLocationCheck(BuildContext context) async {
    bool serviceEnabled;

    // 1. Cek status GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // 2. Jika mati, tampilkan Dialog konfirmasi
      // Kita gunakan 'await' agar kode di bawahnya menunggu user menutup dialog
      bool userAgreed = await _showLocationDialog(context);

      if (userAgreed) {
        // 3. Buka pengaturan lokasi HP
        await Geolocator.openLocationSettings();

        // Return null to indicate that settings were opened and user needs to try again
        return null;
      } else {
        // User menolak menyalakan GPS, berikan feedback (misal: pakai lokasi default)
        print("User menolak menyalakan GPS");
        return null;
      }
    }

    // Lanjut ke pengecekan Izin (Permission) seperti kode sebelumnya...
    return await _checkPermissions();
  }

  // Fungsi untuk menampilkan Popup/Dialog
  Future<bool> _showLocationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Lokasi'),
        content: const Text('Untuk mengantar makanan ke tempatmu, mohon nyalakan GPS di HP kamu ya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Tombol Batal
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Tombol Oke
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71), // Sesuaikan warna Foodly
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    ) ?? false; // Default return false jika dialog ditutup paksa
  }

  Future<Position> _checkPermissions() async {
    LocationPermission permission;

    // 2. Cek status Izin (Permission) saat ini
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Jika belum diizinkan, minta izin ke user
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Jika user menolak (klik Deny), kita tidak bisa lanjut
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Jika user menolak permanen (klik "Don't ask again"),
      // arahkan user ke pengaturan HP
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 3. Jika semua aman, ambil posisi saat ini
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }
}