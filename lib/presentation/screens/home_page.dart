import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/pdf_document.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pdf_viewmodel.dart';
import '../../presentation/screens/pdf_viewer_page.dart';
import '../../presentation/widgets/document_card_widget.dart';
import '../../presentation/viewmodels/pdf_viewer_viewmodel.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/pdf/pdf_service.dart';
import '../../data/datasources/pdf_local_datasource.dart';
import 'login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/extensions/firebase_user_extension.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import './pdf_viewer_screen.dart';
import 'language_selection_screen.dart';
import '../../core/localization/app_localizations.dart';

/// 홈 페이지
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('app_name')),
        actions: [
          // 언어 선택 드롭다운
          const LanguageDropdown(),
          
          // 기타 앱바 아이콘들
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 기능
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // 프로필 화면으로 이동
            },
          ),
        ],
      ),
      body: Center(
              child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 콘텐츠
            Text(
              localizations.translate('home'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            
            const SizedBox(height: 20),
            
            // 로그인/로그아웃 버튼
            Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                if (authViewModel.isLoggedIn) {
                  return ElevatedButton(
                    onPressed: () async {
                      await authViewModel.logout();
                    },
                    child: Text(localizations.translate('logout')),
                  );
                } else {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(localizations.translate('login')),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
            onPressed: () {
          // PDF 추가
        },
        tooltip: localizations.translate('add_pdf'),
        child: const Icon(Icons.add),
      ),
    );
  }
} 