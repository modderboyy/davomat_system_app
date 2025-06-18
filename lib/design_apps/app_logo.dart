import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const AppLogo({Key? key, this.logoUrl, this.size = 60}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: logoUrl != null &&
                logoUrl!.isNotEmpty &&
                Uri.tryParse(logoUrl!)?.hasScheme == true
            ? Image.network(logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.public,
                    size: size * 0.6, color: Colors.grey[400]))
            : Icon(Icons.public, size: size * 0.6, color: Colors.grey[400]),
      ),
    );
  }
}
