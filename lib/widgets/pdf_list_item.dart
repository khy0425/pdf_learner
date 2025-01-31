import 'package:flutter/material.dart';
import 'dart:io';

class PDFListItem extends StatelessWidget {
  final File? pdfFile;
  
  const PDFListItem({this.pdfFile, super.key});

  @override
  Widget build(BuildContext context) {
    if (pdfFile == null) return const SizedBox.shrink();
    
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf),
      title: Text(pdfFile!.path.split('/').last),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(pdfFile: pdfFile!),
          ),
        );
      },
    );
  }
} 