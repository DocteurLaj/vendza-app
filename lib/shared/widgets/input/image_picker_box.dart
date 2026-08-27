import 'package:flutter/material.dart';

class ImagePickerBox extends StatelessWidget {
  const ImagePickerBox({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 40),
              SizedBox(height: 8),
              Text("Ajouter une image"),
            ],
          ),
        ),
      ),
    );
  }
}
