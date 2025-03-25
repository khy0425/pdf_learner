import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/pdf_viewmodel.dart';

/// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 렌더링된 후 PDF 목록을 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PDFViewModel>(context, listen: false).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, PDFViewModel>(
      builder: (context, authViewModel, pdfViewModel, child) {
        // 인증되지 않은 상태이면 로그인 페이지로 이동
        if (authViewModel.isUnauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
        
        // 인증 관련 에러 상태이면 스낵바 표시
        if (authViewModel.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authViewModel.error ?? '인증 오류가 발생했습니다')),
            );
            // 에러 메시지를 표시한 후 상태 초기화
            authViewModel.clearError();
          });
        }
        
        // PDF 관련 에러 상태이면 스낵바 표시
        if (pdfViewModel.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(pdfViewModel.error ?? 'PDF 처리 중 오류가 발생했습니다')),
            );
            // 에러 메시지를 표시한 후 상태 초기화
            pdfViewModel.clearError();
          });
        }
        
        // 로딩 상태이면 로딩 인디케이터 표시
        if (authViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // 인증된 상태이면 홈 화면 표시
        if (authViewModel.isAuthenticated && authViewModel.currentUser != null) {
          final user = authViewModel.currentUser!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('PDF Learner'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    pdfViewModel.pickAndAddPDF();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    authViewModel.signOut();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // 사용자 정보 요약 표시
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (user.photoURL != null) ...[
                        CircleAvatar(
                          radius: 24.0,
                          backgroundImage: NetworkImage(user.photoURL!),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.displayName ?? '사용자'}님 환영합니다',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // PDF 목록 표시
                Expanded(
                  child: pdfViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : pdfViewModel.documents.isEmpty
                      ? const Center(child: Text('문서가 없습니다. PDF를 추가해주세요.'))
                      : ListView.builder(
                          itemCount: pdfViewModel.documents.length,
                          itemBuilder: (context, index) {
                            final document = pdfViewModel.documents[index];
                            return ListTile(
                              leading: document.thumbnailUrl != null
                                ? Image.network(
                                    document.thumbnailUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.picture_as_pdf),
                              title: Text(document.title),
                              subtitle: Text(
                                '페이지: ${document.currentPage}/${document.pageCount}',
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  document.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                ),
                                onPressed: () {
                                  pdfViewModel.toggleFavorite(document.id);
                                },
                              ),
                              onTap: () {
                                // TODO: PDF 뷰어로 이동
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
        
        // 기본적으로 로딩 인디케이터 표시
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
} 