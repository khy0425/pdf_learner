import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../theme/app_theme.dart';
import 'pdf_static_thumbnail.dart';

class PdfThumbnails extends StatelessWidget {
  final Uint8List pdfData;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;
  final ScrollController controller;

  const PdfThumbnails({
    super.key,
    required this.pdfData,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              '페이지 썸네일',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: totalPages,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                // 페이지 번호는 1부터 시작
                final pageNumber = index + 1;
                final isSelected = pageNumber == currentPage;
                
                return GestureDetector(
                  onTap: () => onPageSelected(pageNumber),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // PDF 썸네일
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                          child: SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: PdfStaticThumbnail(
                              pdfData: pdfData,
                              pageNumber: pageNumber,
                            ),
                          ),
                        ),
                        
                        // 페이지 번호
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$pageNumber',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 