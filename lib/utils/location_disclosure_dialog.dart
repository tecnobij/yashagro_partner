import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prominent Disclosure Dialog for Background Location Access.
/// Required by Google Play's User Data & Location Policies.
class LocationDisclosureDialog {
  static const String _kDisclosureAcceptedKey =
      'has_accepted_location_disclosure';

  /// Checks if disclosure has already been accepted.
  static Future<bool> isDisclosureAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDisclosureAcceptedKey) ?? false;
  }

  /// Shows the Google Play compliant prominent disclosure dialog.
  /// Must be shown BEFORE requesting system runtime location permissions.
  static Future<bool> ensureDisclosureAndPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAccepted = prefs.getBool(_kDisclosureAcceptedKey) ?? false;

    LocationPermission currentPermission = await Geolocator.checkPermission();
    if (alreadyAccepted &&
        currentPermission != LocationPermission.denied &&
        currentPermission != LocationPermission.deniedForever) {
      return true;
    }

    // Show Google Play Prominent Disclosure Dialog
    final bool? accepted = await Get.dialog<bool>(
      PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Colors.green.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Location Access & Tracking",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Yash Team collects location data to enable the following features:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _bulletPoint(
                  icon: Icons.alt_route_rounded,
                  title: "Work Route & Travel Tracking",
                  desc:
                      "Records your daily work travel route and calculates accurate travel distances during your duty hours.",
                ),
                const SizedBox(height: 10),
                _bulletPoint(
                  icon: Icons.pin_drop_rounded,
                  title: "Farm & Dealer Visit Verification",
                  desc:
                      "Verifies on-site farm visits and dealer interactions for reporting and task completion.",
                ),
                const SizedBox(height: 10),
                _bulletPoint(
                  icon: Icons.shield_outlined,
                  title: "Background Location Collection",
                  desc:
                      "This data is collected in the background even when the app is closed or not in use, but ONLY while you are actively on duty in 'Start Work' mode.",
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    "Your location data is confidential, used strictly for enterprise field-force management, and is never sold or shared with third parties.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text(
                "Deny",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () => Get.back(result: true),
              child: const Text(
                "Agree & Continue",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    if (accepted == true) {
      await prefs.setBool(_kDisclosureAcceptedKey, true);

      // Request system permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }

    return false;
  }

  static Widget _bulletPoint({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
