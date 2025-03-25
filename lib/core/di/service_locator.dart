import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../presentation/viewmodels/auth_view_model.dart';
import '../../presentation/viewmodels/pdf_viewmodel.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
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