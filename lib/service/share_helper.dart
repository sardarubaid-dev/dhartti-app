import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareHelper {
  /// Shares property with its photo and beautifully formatted details.
  /// Works across native share sheet, WhatsApp, and clipboard with deep linking support.
  static Future<void> shareProperty({
    BuildContext? context,
    required dynamic propertyId,
    required String title,
    required String city,
    required String price,
    String? imageUrl,
    String? area,
    String? beds,
    String? baths,
    String? type,
    String? purpose,
  }) async {
    // 1. Build clean, professional text (No emojis)
    final buffer = StringBuffer();
    buffer.writeln(title);
    if (city.trim().isNotEmpty) {
      buffer.writeln('Location: $city');
    }
    if (price.trim().isNotEmpty) {
      buffer.writeln('Price: $price');
    }

    final List<String> details = [];
    if (area != null && area.trim().isNotEmpty) {
      details.add('Area: $area');
    }
    final hasBeds = beds != null && beds.trim().isNotEmpty && beds != '0';
    final hasBaths = baths != null && baths.trim().isNotEmpty && baths != '0';
    if (hasBeds && hasBaths) {
      details.add('$beds Beds | $baths Baths');
    } else if (hasBeds) {
      details.add('$beds Bedrooms');
    } else if (hasBaths) {
      details.add('$baths Bathrooms');
    }
    if (type != null && type.trim().isNotEmpty) {
      final p = (purpose != null && purpose.trim().isNotEmpty) ? ' ($purpose)' : '';
      details.add('Type: $type$p');
    }

    if (details.isNotEmpty) {
      buffer.writeln();
      for (final d in details) {
        buffer.writeln('• $d');
      }
    }

    buffer.writeln();
    buffer.writeln('View property details:');
    buffer.write('https://dhartti.com/room-detail/$propertyId');

    final shareText = buffer.toString();

    // 2. Fast background download of main image (1.5s max so UI never freezes)
    File? tempImageFile;
    if (imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http')) {
      try {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          final ext = imageUrl.split('.').last.split('?').first.toLowerCase();
          final validExt =
              ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
          final filePath =
              '${tempDir.path}/dhartti_prop_${propertyId}_${DateTime.now().millisecondsSinceEpoch}.$validExt';
          tempImageFile = File(filePath);
          await tempImageFile.writeAsBytes(response.bodyBytes);
        }
      } catch (_) {
        // Continue without blocking
      }
    }

    // 3. Attempt native share sheet via SharePlus
    bool shareCompleted = false;
    try {
      if (tempImageFile != null && await tempImageFile.exists()) {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempImageFile.path)],
            text: shareText,
            title: title,
            subject: title,
          ),
        );
        shareCompleted = result.status != ShareResultStatus.unavailable;
      } else {
        final result = await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            title: title,
            subject: title,
          ),
        );
        shareCompleted = result.status != ShareResultStatus.unavailable;
      }
    } catch (e) {
      debugPrint("SharePlus error or not linked in current session: $e");
      shareCompleted = false;
    }

    // 4. Bulletproof Fallback: Direct WhatsApp / Clipboard
    // If SharePlus plugin channel was missing (needs app full rebuild/restart) or user device share failed:
    if (!shareCompleted) {
      bool waLaunched = false;
      try {
        final encoded = Uri.encodeComponent(shareText);
        final nativeWa = Uri.parse("whatsapp://send?text=$encoded");
        if (await canLaunchUrl(nativeWa)) {
          waLaunched = await launchUrl(nativeWa, mode: LaunchMode.externalApplication);
        }
        if (!waLaunched) {
          final webWa = Uri.parse("https://api.whatsapp.com/send?text=$encoded");
          waLaunched = await launchUrl(webWa, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}

      // Always copy to clipboard as ultimate safety net
      await Clipboard.setData(ClipboardData(text: shareText));

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              waLaunched
                  ? "Sharing via WhatsApp..."
                  : "Property details & link copied to clipboard!",
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
