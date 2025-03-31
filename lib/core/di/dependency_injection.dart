import 'dart:typed_data';
import 'package:get_it/get_it.dart';
// import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';

import '../../data/datasources/pdf_local_data_source.dart';
import '../../data/datasources/pdf_local_data_source_impl.dart';
import '../../data/datasources/pdf_remote_data_source.dart';
import '../../data/datasources/pdf_remote_data_source_impl.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/models/pdf_document.dart';
import '../../domain/services/pdf_service.dart' as domain_pdf;
import '../../core/base/result.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pdf_viewmodel.dart';
import '../../presentation/viewmodels/pdf_file_viewmodel.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';
import '../../presentation/viewmodels/locale_viewmodel.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/analytics/analytics_service_impl.dart' as analytics_impl;
import '../../services/firebase/firebase_service.dart';
import '../../services/firebase/firebase_service_impl.dart';
import '../../services/storage/storage_service.dart';
import '../../services/storage/storage_service_impl.dart' as storage_impl;
import '../../services/pdf/pdf_service.dart';
import '../../services/pdf/pdf_service_impl.dart' as pdf_impl;
import '../../services/storage/thumbnail_service.dart';
import '../../core/utils/web_utils.dart';

final getIt = GetIt.instance;

/// 의존성 주입 관리 클래스
class DependencyInjection {
  /// GetIt 인스턴스
  static GetIt get instance => getIt;
  
  /// 의존성 초기화
  static Future<void> init() async {
    await setupDependencies();
  }
}

/// 애플리케이션의 의존성을 설정합니다.
Future<void> setupDependencies() async {
  // 선행 의존성 초기화
  await _initializeDependencies();
  
  _registerServices();
  _registerDataSources();
  _registerRepositories();
  _registerViewModels();
}

/// 선행 의존성 초기화
Future<void> _initializeDependencies() async {
  // SharedPreferences 초기화
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // WebUtils 초기화
  WebUtils.registerSingleton();
}

/// 서비스 의존성을 등록합니다.
void _registerServices() {
  // FirebaseService 먼저 등록 (다른 서비스가 의존하기 때문)
  getIt.registerLazySingleton<FirebaseService>(() {
    final service = FirebaseServiceImpl();
    service.initialize();
    return service;
  });
  
  // AnalyticsService 등록
  getIt.registerLazySingleton<AnalyticsService>(() => 
    analytics_impl.AnalyticsServiceImpl(
      firebaseService: getIt<FirebaseService>(),
    )
  );
  
  // StorageService 등록
  getIt.registerLazySingleton<StorageService>(() => 
    storage_impl.StorageServiceImpl(
      preferences: getIt<SharedPreferences>(),
    )
  );
  
  // ThumbnailService 등록 - 올바른 클래스 참조
  getIt.registerLazySingleton<ThumbnailService>(() => 
    ThumbnailServiceImpl(getIt<StorageService>())
  );
  
  // PDFService 등록
  getIt.registerLazySingleton<PDFService>(() => 
    pdf_impl.PDFServiceImpl(
      storageService: getIt<StorageService>(),
    )
  );
  
  // 도메인 PDFService 등록 (PDFService를 도메인 PDFService 인터페이스로 어댑팅)
  getIt.registerLazySingleton<domain_pdf.PDFService>(() => 
    PDFServiceAdapter(getIt<PDFService>())
  );
}

/// 데이터 소스 의존성을 등록합니다.
void _registerDataSources() {
  // PDF 로컬 데이터 소스 등록
  getIt.registerLazySingleton<PDFLocalDataSource>(() => 
    PDFLocalDataSourceImpl(
      getIt<StorageService>(), 
      getIt<SharedPreferences>()
    )
  );
  
  // PDF 원격 데이터 소스 등록
  getIt.registerLazySingleton<PDFRemoteDataSource>(() => 
    PDFRemoteDataSourceImpl(
      firebaseService: getIt<FirebaseService>()
    )
  );
}

/// 레포지토리 의존성을 등록합니다.
void _registerRepositories() {
  // PDF 레포지토리 등록
  getIt.registerLazySingleton<PDFRepository>(() => 
    PDFRepositoryImpl(
      localDataSource: getIt<PDFLocalDataSource>(),
      remoteDataSource: getIt<PDFRemoteDataSource>(),
      sharedPreferences: getIt<SharedPreferences>(),
      firebaseService: getIt<FirebaseService>(),
      storageService: getIt<StorageService>(),
      webUtils: getIt<WebUtils>(),
    )
  );
}

/// 뷰모델 의존성을 등록합니다.
void _registerViewModels() {
  // ThemeViewModel 등록 - 싱글톤으로 변경하여 항상 동일한 인스턴스 사용하도록 수정
  getIt.registerLazySingleton<ThemeViewModel>(() => 
    ThemeViewModel(
      sharedPreferences: getIt<SharedPreferences>(),
    )
  );
  
  // LocaleViewModel 등록 - 싱글톤으로 변경
  getIt.registerLazySingleton<LocaleViewModel>(() => 
    LocaleViewModel(
      sharedPreferences: getIt<SharedPreferences>(),
    )
  );
  
  // 인증 뷰모델 등록
  getIt.registerFactory<AuthViewModel>(() => 
    AuthViewModel(
      firebaseService: getIt<FirebaseService>(),
    )
  );
  
  // PDF 뷰모델 등록
  getIt.registerFactory<PDFViewModel>(() => 
    PDFViewModel(
      repository: getIt<PDFRepository>(),
      pdfService: getIt<domain_pdf.PDFService>(),
      analyticsService: getIt<AnalyticsService>(),
      firebaseService: getIt<FirebaseService>(),
      storageService: getIt<StorageService>(),
    )
  );
  
  // PDF 파일 뷰모델 등록
  getIt.registerFactory<PdfFileViewModel>(() => 
    PdfFileViewModel(
      repository: getIt<PDFRepository>(),
      pdfService: getIt<domain_pdf.PDFService>(),
      thumbnailService: getIt<ThumbnailService>(),
      storageService: getIt<StorageService>(),
    )
  );
}

/// 서비스 어댑터 - 서비스 구현을 도메인 인터페이스에 맞게 변환
class PDFServiceAdapter implements domain_pdf.PDFService {
  final PDFService _service;
  
  PDFServiceAdapter(this._service);
  
  @override
  Future<PDFDocument> openDocument(String path) => _service.openDocument(path);
  
  @override
  Future<void> closeDocument(String id) => _service.closeDocument(id);
  
  @override
  Future<Uint8List> renderPage(String id, int pageNumber, {int width = 800, int height = 1200}) => 
    _service.renderPage(id, pageNumber, width: width, height: height);
    
  @override
  Future<Uint8List> generateThumbnail(String id) => _service.generateThumbnail(id);
  
  @override
  Future<String> extractText(String id, int pageNumber) => _service.extractText(id, pageNumber);
  
  @override
  Future<Map<String, dynamic>> extractMetadata(String id) => _service.extractMetadata(id);
  
  @override
  Future<int> getPageCount(String id) => _service.getPageCount(id);
  
  @override
  Future<Result<String>> downloadPdf(String url) => _service.downloadPdf(url);
  
  @override
  Future<List<Map<String, dynamic>>> searchText(String id, String query) => _service.searchText(id, query);
  
  @override
  void dispose() => _service.dispose();
} 