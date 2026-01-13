import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DocumentPreview extends StatelessWidget {
  final String? imageUrl; // Cloudinary URL
  final XFile? file; // Local picked file (mobile/desktop/web)
  final double height;
  final double borderRadius;
  final IconData? placeholderIcon;

  const DocumentPreview({
    super.key,
    required this.imageUrl,
    required this.file,
    this.height = 120,
    this.borderRadius = 12,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    // Logic: Prioritize NEW file (local preview) over EXISTING URL (remote).
    if (file != null) {
      if (kIsWeb) {
        // Web: File path is likely a blob URL
        child = Image.network(
          file!.path,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text(
              'Preview N/A',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        );
      } else {
        // Mobile/Desktop: Use Image.file
        child = Image.file(
          File(file!.path),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      // Placeholder
      child = Center(
        child: Icon(
          placeholderIcon ?? Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: child,
      ),
    );
  }
}
