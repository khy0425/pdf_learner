import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
import '../../data/datasources/pdf_local_data_source.dart';
import '../../data/datasources/pdf_local_data_source_impl.dart';
import '../../data/datasources/pdf_remote_data_source.dart';
import '../../data/datasources/pdf_remote_data_source_impl.dart';
import '../../services/storage/storage_service.dart';
import '../../services/storage/thumbnail_service.dart';
import '../utils/web_storage_utils.dart';
// TODO: 인터페이스 임포트 필요
// import '../../data/datasources/auth_data_source.dart';
// import '../../data/datasources/auth_data_source_impl.dart';

/// 의존성 주입을 관리하는 클래스
/// 싱글톤으로 구현되어 전역적으로 접근 가능
class DependencyInjection {
  static final GetIt _getIt = GetIt.instance;
  
  /// GetIt 인스턴스 접근자
  static GetIt get getItInstance => _getIt;
  
  /// 의존성 초기화
  static Future<void> init() async {
    await _registerExternalDependencies();
    _registerFirebaseServices();
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

    // Flutter Secure Storage
    _getIt.registerSingleton<FlutterSecureStorage>(FlutterSecureStorage());
  }
  
  /// 서비스 등록
  static void _registerServices() {
    // PDF 서비스
    _getIt.registerSingleton<PDFService>(PDFServiceImpl());
    
    // 썸네일 서비스
    _getIt.registerSingleton<ThumbnailService>(
      ThumbnailServiceImpl(_getIt<StorageService>())
    );
  }
  
  /// 서비스 등록
  static void _registerFirebaseServices() {
    // Firebase 서비스 래퍼
    _getIt.registerSingleton<FirebaseService>(
      FirebaseService(
        auth: _getIt<FirebaseAuth>(),
        firestore: _getIt<FirebaseFirestore>(),
        storage: _getIt<FirebaseStorage>()
      )
    );
  }

  /// 데이터 소스 등록
  static void _registerDataSources() {
    // 로컬 스토리지 서비스
    _getIt.registerSingleton<StorageService>(
      StorageServiceImpl(
        _getIt<SharedPreferences>()
      ),
    );
    
    // PDF 로컬 데이터 소스
    _getIt.registerSingleton<PDFLocalDataSource>(
      PDFLocalDataSourceImpl(
        storageService: _getIt<StorageService>(),
        prefs: _getIt<SharedPreferences>()
      ),
    );
    
    // PDF 원격 데이터 소스
    _getIt.registerSingleton<PDFRemoteDataSource>(
      FirebasePDFRemoteDataSource(
        firestore: _getIt<FirebaseFirestore>(),
        storage: _getIt<FirebaseStorage>(),
        firebaseService: _getIt<FirebaseService>()
      ),
    );
  }

  /// 리포지토리 등록
  static void _registerRepositories() {
    // PDF 레포지토리
    _getIt.registerSingleton<PDFRepository>(
      PDFRepositoryImpl(
        localDataSource: _getIt<PDFLocalDataSource>(),
        remoteDataSource: _getIt<PDFRemoteDataSource>(),
        storageService: _getIt<StorageService>(),
        firebaseService: _getIt<FirebaseService>(),
        sharedPreferences: _getIt<SharedPreferences>()
      ),
    );
    
    // 인증 레포지토리
    _getIt.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        _getIt<FirebaseService>(),
        _getIt<GoogleSignIn>()
      ),
    );
  }

  /// 뷰모델 등록
  static void _registerViewModels() {
    // ViewModel 등록
    _getIt.registerSingleton<ThemeViewModel>(
      ThemeViewModel(
        sharedPreferences: _getIt<SharedPreferences>()
      ),
    );
    
    _getIt.registerSingleton<LocaleViewModel>(
      LocaleViewModel(
        sharedPreferences: _getIt<SharedPreferences>()
      ),
    );
    
    _getIt.registerSingleton<AuthViewModel>(
      AuthViewModel(
        repository: _getIt<AuthRepository>()
      ),
    );
    
    _getIt.registerSingleton<PDFViewModel>(
      PDFViewModel(
        repository: _getIt<PDFRepository>(),
        pdfService: _getIt<PDFService>()
      ),
    );
    
    _getIt.registerFactory<PDFViewerViewModel>(
      () => PDFViewerViewModel(
        pdfRepository: _getIt<PDFRepository>(),
        pdfViewModel: _getIt<PDFViewModel>(),
        authViewModel: _getIt<AuthViewModel>(),
        pdfService: _getIt<PDFService>(),
        localDataSource: _getIt<PDFLocalDataSource>()
      ),
    );
    
    _getIt.registerSingleton<PDFFileViewModel>(
      PDFFileViewModel(
        repository: _getIt<PDFRepository>(),
        pdfService: _getIt<PDFService>()
      ),
    );
    
    _getIt.registerSingleton<PDFListViewModel>(
      PDFListViewModel(
        repository: _getIt<PDFRepository>()
      ),
    );
    
    _getIt.registerSingleton<SettingsViewModel>(
      SettingsViewModel(
        sharedPreferences: _getIt<SharedPreferences>()
      ),
    );
  }
  
  /// 타입 T의 인스턴스 가져오기
  static T instance<T extends Object>() {
    return _getIt<T>();
  }
}

@module
abstract class FirebaseInjectableModule {
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseStorage get storage => FirebaseStorage.instance;

  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;
}

@module
abstract class ExternalServicesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}

@module
abstract class AppModule {
  @singleton
  PDFService providePDFService() => PDFServiceImpl();

  @lazySingleton
  StorageService storageService(SharedPreferences prefs) => StorageServiceImpl(prefs);
  
  @lazySingleton
  ThumbnailService provideThumbnailService(StorageService storageService) => 
      ThumbnailServiceImpl(storageService);
}

@module
abstract class DataSourceModule {
  @lazySingleton
  PDFLocalDataSource providePDFLocalDataSource(
    StorageService storageService,
    SharedPreferences prefs,
  ) =>
      PDFLocalDataSourceImpl(
        storageService: storageService,
        prefs: prefs,
      );

  @lazySingleton
  PDFRemoteDataSource providePDFRemoteDataSource(
    FirebaseFirestore firestore,
    FirebaseStorage storage,
    FirebaseService firebaseService,
  ) =>
      FirebasePDFRemoteDataSource(
        firestore: firestore,
        storage: storage,
        firebaseService: firebaseService,
      );

  // TODO: AuthDataSource 인터페이스와 FirebaseAuthDataSource 클래스 구현 후 주석 해제
  /*
  @lazySingleton
  AuthDataSource provideAuthDataSource(
    FirebaseAuth auth,
    SharedPreferences prefs,
    FlutterSecureStorage secureStorage,
  ) =>
      FirebaseAuthDataSource(
        auth: auth,
        prefs: prefs,
        secureStorage: secureStorage,
      );
  */
}

@module
abstract class RepositoryModule {
  @lazySingleton
  PDFRepository providePDFRepository(
    PDFLocalDataSource localDataSource,
    PDFRemoteDataSource remoteDataSource,
    StorageService storageService,
    FirebaseService firebaseService,
    SharedPreferences sharedPreferences,
  ) =>
      PDFRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        storageService: storageService,
        firebaseService: firebaseService,
        sharedPreferences: sharedPreferences,
      );

  @lazySingleton
  AuthRepository provideAuthRepository(
    FirebaseService firebaseService,
    GoogleSignIn googleSignIn
  ) =>
      AuthRepositoryImpl(
        firebaseService,
        googleSignIn
      );
}

@module
abstract class ServiceModule {
  @singleton
  FirebaseService provideFirebaseService(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
    FirebaseStorage storage
  ) =>
      FirebaseService(
        auth: auth,
        firestore: firestore,
        storage: storage
      );
}

@module
abstract class ViewModelModule {
  @lazySingleton
  PDFViewModel providePDFViewModel(
    PDFRepository repository,
    PDFService pdfService,
  ) =>
      PDFViewModel(
        repository: repository,
        pdfService: pdfService,
      );

  @lazySingleton
  AuthViewModel provideAuthViewModel(
    AuthRepository repository,
  ) =>
      AuthViewModel(
        repository: repository,
      );

  @lazySingleton
  ThemeViewModel provideThemeViewModel(
    SharedPreferences sharedPreferences,
  ) =>
      ThemeViewModel(
        sharedPreferences: sharedPreferences,
      );

  @lazySingleton
  LocaleViewModel provideLocaleViewModel(
    SharedPreferences sharedPreferences,
  ) =>
      LocaleViewModel(
        sharedPreferences: sharedPreferences,
      );

  @factory
  PDFViewerViewModel providePDFViewerViewModel(
    PDFRepository pdfRepository,
    PDFViewModel pdfViewModel,
    AuthViewModel authViewModel,
    PDFService pdfService,
    PDFLocalDataSource localDataSource,
  ) =>
      PDFViewerViewModel(
        pdfRepository: pdfRepository,
        pdfViewModel: pdfViewModel,
        authViewModel: authViewModel,
        pdfService: pdfService,
        localDataSource: localDataSource,
      );

  @lazySingleton
  PDFFileViewModel providePDFFileViewModel(
    PDFRepository repository,
    PDFService pdfService,
  ) =>
      PDFFileViewModel(
        repository: repository,
        pdfService: pdfService,
      );
  
  @lazySingleton
  PDFListViewModel providePDFListViewModel(
    PDFRepository repository,
  ) =>
      PDFListViewModel(
        repository: repository,
      );
      
  @lazySingleton
  SettingsViewModel provideSettingsViewModel(
    SharedPreferences sharedPreferences,
  ) =>
      SettingsViewModel(
        sharedPreferences: sharedPreferences,
      );
} 