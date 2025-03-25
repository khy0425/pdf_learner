import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 코어 서비스 임포트
import '../../core/services/firebase_service.dart';
import '../../core/services/storage_service.dart';

// 도메인 리포지토리 임포트
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/repositories/auth_repository.dart';

// 데이터 리포지토리 구현 임포트
import '../../data/repositories/pdf_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';

// 뷰모델 임포트
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/pdf_viewmodel.dart';

/// 서비스 로케이터 인스턴스
final getIt = GetIt.instance;

/// 의존성 주입 초기화
Future<void> configureDependencies() async {
  try {
    // External Services
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    
    // Firebase Services
    getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
    getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
    getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);
    
    // Google Services
    getIt.registerSingleton<GoogleSignIn>(GoogleSignIn());

    // Core Services
    getIt.registerSingleton<StorageService>(StorageService(prefs));
    
    getIt.registerSingleton<FirebaseService>(
      FirebaseService(
        getIt<FirebaseAuth>(),
        getIt<FirebaseFirestore>(),
        getIt<FirebaseStorage>()
      )
    );

    // Repositories
    getIt.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        getIt<FirebaseService>(),
        getIt<GoogleSignIn>(),
      ),
    );
    
    getIt.registerSingleton<PDFRepository>(
      PDFRepositoryImpl(
        getIt<FirebaseService>(),
        getIt<StorageService>(),
      ),
    );

    // ViewModels
    getIt.registerFactory<AuthViewModel>(
      () => AuthViewModel(getIt<FirebaseService>()),
    );
    
    getIt.registerFactory<PDFViewModel>(
      () => PDFViewModel(getIt<PDFRepository>()),
    );
  } catch (e) {
    throw Exception('의존성 주입 설정 중 오류 발생: $e');
  }
}

Future<void> resetDependencies() async {
  await getIt.reset();
  await configureDependencies();
} 