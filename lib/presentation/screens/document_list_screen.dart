import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/localization/app_localizations.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({Key? key}) : super(key: key);
  
  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  // ... (existing code)

  Future<void> _addPdf() async {
    final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // 미회원인 경우 만료 경고 표시
    if (!authViewModel.isLoggedIn) {
      final shouldContinue = await _showGuestWarningDialog();
      if (shouldContinue != true) return;
    }
    
    // PDF 추가 진행
    await pdfViewModel.pickAndAddPDF();
  }
  
  /// 미회원 사용자에게 데이터 만료 경고 대화상자 표시
  Future<bool?> _showGuestWarningDialog() async {
    final localizations = AppLocalizations.of(context);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(localizations.translate('guest_expiration_title')),
          ],
        ),
        content: Text(
          localizations.translate('guest_expiration_message'),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(localizations.translate('continue')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              // 회원가입 화면으로 이동
              Navigator.pushNamed(context, '/signup');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(localizations.translate('signup')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
    return Container(); // 임시 구현
  }
} 