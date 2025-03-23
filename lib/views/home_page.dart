import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/document_list_viewmodel.dart';
import '../models/pdf_document.dart';
import '../services/auth_service.dart';
import '../views/pdf_viewer_page.dart';
import '../views/login_page.dart';
import '../services/storage_service.dart';
import 'settings_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../widgets/platform_ad_widget.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import '../repositories/pdf_repository.dart';
import '../services/dialog_service.dart';
import '../services/thumbnail_service.dart';
import '../utils/formatters/date_formatter.dart';
import '../viewmodels/document_actions_viewmodel.dart';
import 'components/document_grid_view.dart';
import 'components/document_list_view.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// 웹 전용 라이브러리
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) '../stub_html.dart' as html;
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 표시 모드 (그리드 또는 리스트)
  bool _isGridView = true;
  
  // 검색 관련 상태
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // 뷰모델
  late DocumentListViewModel _listViewModel;
  late DocumentActionsViewModel _actionsViewModel;
  
  // 서비스
  late DialogService _dialogService;
  late ThumbnailService _thumbnailService;
  
  @override
  void initState() {
    super.initState();
    
    // 뷰모델 초기화
    _listViewModel = Provider.of<DocumentListViewModel>(context, listen: false);
    _actionsViewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    
    // 서비스 초기화
    _dialogService = DialogService();
    _thumbnailService = ThumbnailService();
    
    // 문서 목록 로드
      _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  /// 문서 목록 로드
  Future<void> _loadDocuments() async {
    await _listViewModel.loadDocuments();
  }
  
  /// 선택된 문서에 대한 컨텍스트 메뉴 표시
  void _showDocumentOptions(BuildContext context, PDFDocument document) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('이름 변경'),
            onTap: () {
              Navigator.pop(context);
              _dialogService.showRenameDialog(
                context, 
                document.id, 
                document.title,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('삭제', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _dialogService.showDeleteConfirmDialog(
                context, 
                document.id, 
                document.title,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  /// 앱바 구성
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '검색',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _actionsViewModel.searchDocuments(value);
              },
            )
          : const Text('PDF 학습노트'),
      actions: [
        // 검색 버튼
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _actionsViewModel.searchDocuments('');
              }
            });
          },
        ),
        
        // 보기 모드 전환 버튼
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        
        // 정렬 버튼
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _dialogService.showSortOptions(context),
        ),
      ],
    );
  }
  
  /// 본문 구성
  Widget _buildBody() {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(viewModel.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDocuments,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        
        final documents = viewModel.filteredDocuments;
        
        if (documents.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('문서가 없습니다'),
                const SizedBox(height: 8),
                const Text('PDF 파일을 추가해 보세요'),
          const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _dialogService.showAddPdfOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('PDF 추가'),
          ),
        ],
      ),
    );
  }
  
        return _isGridView
            ? DocumentGridView(
                documents: documents,
                onDocumentLongPress: (document) => _showDocumentOptions(context, document),
                isSearching: _isSearching,
              )
            : DocumentListView(
                documents: documents,
                onDocumentLongPress: (document) => _showDocumentOptions(context, document),
                isSearching: _isSearching,
              );
      },
    );
  }
  
  /// 플로팅 액션 버튼 구성
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _dialogService.showAddPdfOptions(context),
      tooltip: 'PDF 추가',
      child: const Icon(Icons.add),
    );
  }
} 