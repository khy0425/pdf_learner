import 'package:get_it/get_it.dart';
import '../../data/datasources/pdf_local_datasource.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../services/pdf/pdf_service.dart';
import '../../services/storage/file_storage_service.dart';
import '../../services/thumbnail/thumbnail_service.dart';
import '../../presentation/viewmodels/pdf_viewer_viewmodel.dart';

final sl = GetIt.instance;

/// 의존성 주입 초기화
Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => FileStorageService());
  sl.registerLazySingleton(() => ThumbnailService());
  
  // Data sources
  sl.registerLazySingleton<PDFLocalDataSource>(
    () => PDFLocalDataSourceImpl(
      fileStorage: sl(),
      thumbnailService: sl(),
    ),
  );
  
  // Repositories
  sl.registerLazySingleton<PDFRepository>(
    () => PDFRepositoryImpl(
      localDataSource: sl(),
    ),
  );
  
  // Services
  sl.registerLazySingleton<PDFService>(
    () => PDFServiceImpl(
      repository: sl(),
    ),
  );
  
  // ViewModels
  sl.registerFactory(
    () => PDFViewerViewModel(
      repository: sl(),
    ),
  );
}

/// 테스트용 의존성 주입 초기화
Future<void> initTest() async {
  // Core
  sl.registerLazySingleton(() => MockFileStorageService());
  sl.registerLazySingleton(() => MockThumbnailService());
  
  // Data sources
  sl.registerLazySingleton<PDFLocalDataSource>(
    () => MockPDFLocalDataSource(),
  );
  
  // Repositories
  sl.registerLazySingleton<PDFRepository>(
    () => PDFRepositoryImpl(
      localDataSource: sl(),
    ),
  );
  
  // Services
  sl.registerLazySingleton<PDFService>(
    () => MockPDFService(),
  );
  
  // ViewModels
  sl.registerFactory(
    () => PDFViewerViewModel(
      repository: sl(),
    ),
  );
} 