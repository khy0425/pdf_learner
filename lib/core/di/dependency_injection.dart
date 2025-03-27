import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/firebase_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../services/pdf/pdf_service.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pdf_viewmodel.dart';
import '../../presentation/viewmodels/pdf_list_viewmodel.dart';
import '../../presentation/viewmodels/pdf_viewer_viewmodel.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';
import '../../presentation/viewmodels/settings_viewmodel.dart';
import '../../presentation/viewmodels/pdf_file_viewmodel.dart';
import '../../presentation/viewmodels/locale_viewmodel.dart';
import '../../data/datasources/pdf_local_datasource.dart';
import '../../data/datasources/pdf_remote_datasource.dart';
import '../../services/storage/storage_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/payment/payment_service.dart';

/// 의존성 주입 관리자
class DependencyInjection {
  static final GetIt _getIt = GetIt.instance;

  /// GetIt 인스턴스 접근자
  static GetIt get instance => _getIt;

  /// 의존성 등록 및 초기화
  static Future<void> init() async {
    await _registerExternalDependencies();
    _registerServices();
    _registerDataSources();
    _registerRepositories();
    _registerViewModels();
  }

  /// 외부 라이브러리 의존성 등록
  static Future<void> _registerExternalDependencies() async {
    // SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerSingleton(sharedPreferences);

    // Firebase
    _getIt.registerSingleton(FirebaseFirestore.instance);
    _getIt.registerSingleton(FirebaseStorage.instance);
    _getIt.registerSingleton(FirebaseAuth.instance);
    _getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  }

  /// 서비스 등록
  static void _registerServices() {
    _getIt.registerSingleton<FirebaseService>(
      FirebaseService(
        auth: _getIt<FirebaseAuth>(),
        firestore: _getIt<FirebaseFirestore>(),
        storage: _getIt<FirebaseStorage>(),
      ),
    );

    _getIt.registerSingleton<StorageService>(
      FirebaseStorageServiceImpl(),
    );

    _getIt.registerSingleton<PDFService>(
      PDFServiceImpl(),
    );

    _getIt.registerSingleton<AnalyticsService>(
      AnalyticsServiceImpl(),
    );
    
    // 결제 서비스 등록
    _getIt.registerFactory<PayPalPaymentProvider>(
      () => PayPalPaymentProvider(
        sandboxMode: true,
        clientId: 'sandbox-client-id', // 테스트용 기본 값
        secret: 'sandbox-secret',      // 테스트용 기본 값
      ),
    );
    
    _getIt.registerFactory<PaymentService>(
      () => PaymentService(
        paypalProvider: _getIt<PayPalPaymentProvider>(),
      ),
    );
  }

  /// 데이터 소스 등록
  static void _registerDataSources() {
    _getIt.registerSingleton<PDFLocalDataSource>(
      PDFLocalDataSourceImpl(
        _getIt<StorageService>(),
        _getIt<SharedPreferences>(),
      ),
    );

    _getIt.registerSingleton<PDFRemoteDataSource>(
      FirebasePDFRemoteDataSource(
        _getIt<FirebaseFirestore>(),
        _getIt<FirebaseStorage>(),
      ),
    );
  }

  /// 리포지토리 등록
  static void _registerRepositories() {
    _getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        _getIt<FirebaseService>(),
        _getIt<GoogleSignIn>(),
      ),
    );

    _getIt.registerSingleton<PDFRepository>(
      PDFRepositoryImpl(
        _getIt<FirebaseService>(),
        _getIt<SharedPreferences>(),
        _getIt<PDFLocalDataSource>(),
        _getIt<PDFRemoteDataSource>(),
        _getIt<StorageService>(),
      ),
    );
  }

  /// 뷰모델 등록
  static void _registerViewModels() {
    // 싱글톤으로 관리해야 하는 뷰모델
    _getIt.registerSingleton(
      ThemeViewModel(sharedPreferences: _getIt<SharedPreferences>()),
    );
    
    _getIt.registerSingleton(
      SettingsViewModel(_getIt<SharedPreferences>()),
    );
    
    _getIt.registerSingleton(
      PdfFileViewModel(repository: _getIt<PDFRepository>()),
    );
    
    _getIt.registerSingleton(
      LocaleViewModel(sharedPreferences: _getIt<SharedPreferences>()),
    );

    // 팩토리로 관리해야 하는 뷰모델 (화면마다 새로운 인스턴스)
    _getIt.registerFactory(
      () => AuthViewModel(firebaseService: _getIt<FirebaseService>()),
    );
    
    _getIt.registerFactory(
      () => PDFViewModel(
        repository: _getIt<PDFRepository>(),
        firebaseService: _getIt<FirebaseService>(),
        analyticsService: _getIt<AnalyticsService>(),
      ),
    );
    
    _getIt.registerFactory(
      () => PDFListViewModel(
        repository: _getIt<PDFRepository>(),
        storageService: _getIt<StorageService>(),
      ),
    );
    
    _getIt.registerFactory(
      () => PDFViewerViewModel(
        pdfRepository: _getIt<PDFRepository>(),
        pdfViewModel: _getIt<PDFViewModel>(),
        authViewModel: _getIt<AuthViewModel>(),
        pdfService: _getIt<PDFService>(),
        localDataSource: _getIt<PDFLocalDataSource>(),
      ),
    );
  }

  /// 의존성 초기화
  static Future<void> reset() async {
    await _getIt.reset();
    await init();
  }
} 