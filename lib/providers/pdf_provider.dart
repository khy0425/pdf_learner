import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async'; // 타임아웃 예외 사용
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js' as js;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import './subscription_service.dart';  // 같은 디렉토리 내 subscription_service.dart 참조

/// PDF 파일 정보를 담는 모델 클래스
class PdfFileInfo {
  final String id;
  final String fileName;
  final String? url;
  final File? file;
  final DateTime createdAt;
  final int size;
  final Uint8List? bytes;  // 웹에서 사용하는 바이트 데이터
  final String userId;     // 파일 소유자 ID
  final String? firestoreId; // Firestore 문서 ID
  
  PdfFileInfo({
    required this.id,
    required this.fileName,
    this.url,
    this.file,
    required this.createdAt,
    required this.size,
    this.bytes,
    required this.userId,
    this.firestoreId,
  });
  
  bool get isWeb => url != null;
  bool get isLocal => file != null;
  bool get hasBytes => bytes != null;
  bool get isCloudStored => url != null && url!.contains('firebasestorage.googleapis.com');
  
  // 파일 경로 반환 (로컬 파일인 경우 파일 경로, 웹 파일인 경우 URL)
  String get path => isLocal ? file!.path : (url ?? '');
  
  // 로컬 파일 경로 (웹에서는 null)
  String? get localPath => isLocal ? file?.path : null;
  
  // 클라우드 URL (로컬 파일만 있는 경우 null)
  String? get cloudUrl => url;
  
  // 복사본 생성 메서드 (속성 변경 가능)
  PdfFileInfo copyWith({
    String? id,
    String? fileName,
    String? url,
    File? file,
    DateTime? createdAt,
    int? size,
    Uint8List? bytes,
    String? userId,
    String? firestoreId,
    String? cloudUrl,
  }) {
    return PdfFileInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      url: cloudUrl ?? url ?? this.url,
      file: file ?? this.file,
      createdAt: createdAt ?? this.createdAt,
      size: size ?? this.size,
      bytes: bytes ?? this.bytes,
      userId: userId ?? this.userId,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }
  
  // Bytes 데이터 읽기 메서드
  Future<Uint8List> readAsBytes() async {
    if (kDebugMode) {
      print('[PdfFileInfo] PDF 바이트 읽기 시작 - 파일명: $fileName');
      print('[PdfFileInfo] 읽기 유형 - hasBytes: $hasBytes, isLocal: $isLocal, isWeb: $isWeb');
    }
    
    if (hasBytes) {
      if (kDebugMode) {
        print('[PdfFileInfo] 이미 메모리에 바이트 데이터가 있음: ${bytes!.length} 바이트');
      }
      return bytes!;
    } else if (isLocal && file != null) {
      try {
        if (kDebugMode) {
          print('[PdfFileInfo] 로컬 파일에서 바이트 읽기 시작: ${file!.path}');
        }
        final fileBytes = await file!.readAsBytes();
        if (kDebugMode) {
          print('[PdfFileInfo] 로컬 파일에서 바이트 읽기 성공: ${fileBytes.length} 바이트');
        }
        return fileBytes;
      } catch (e) {
        if (kDebugMode) {
          print('[PdfFileInfo] 로컬 파일에서 바이트 읽기 실패: $e');
        }
        throw Exception('로컬 PDF 파일을 읽을 수 없습니다: $e');
      }
    } else if (isWeb && url != null) {
      // URL에서 파일 다운로드
      try {
        if (kDebugMode) {
          print('[PdfFileInfo] URL에서 바이트 다운로드 시작: $url');
        }
        final response = await http.get(Uri.parse(url!));
        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('[PdfFileInfo] URL에서 바이트 다운로드 성공: ${response.bodyBytes.length} 바이트');
          }
          return response.bodyBytes;
        } else {
          if (kDebugMode) {
            print('[PdfFileInfo] URL에서 바이트 다운로드 실패: 상태 코드 ${response.statusCode}');
          }
          throw Exception('PDF 파일을 가져올 수 없습니다 (상태 코드: ${response.statusCode})');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PdfFileInfo] PDF 파일 다운로드 오류: $e');
        }
        throw Exception('PDF 파일 다운로드 오류: $e');
      }
    } else {
      if (kDebugMode) {
        print('[PdfFileInfo] PDF 파일을 읽을 수 없음 - 유효한 파일 정보 없음');
      }
      throw Exception('PDF 파일을 읽을 수 없습니다: 유효한 파일 정보가 없습니다');
    }
  }
  
  // JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'size': size,
      'userId': userId,
      'firestoreId': firestoreId,
    };
  }
  
  // JSON에서 객체 생성 메서드
  factory PdfFileInfo.fromJson(Map<String, dynamic> json) {
    return PdfFileInfo(
      id: json['id'],
      fileName: json['fileName'],
      url: json['url'],
      createdAt: DateTime.parse(json['createdAt']),
      size: json['size'],
      userId: json['userId'] ?? '', // 기존 데이터 호환성 유지
      firestoreId: json['firestoreId'],
    );
  }
  
  // Firestore 데이터로부터 객체 생성
  factory PdfFileInfo.fromFirestore(Map<String, dynamic> data, String docId) {
    return PdfFileInfo(
      id: data['createdAt']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: data['fileName'] ?? '알 수 없는 PDF',
      url: data['url'],
      createdAt: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      size: data['size'] ?? 0,
      userId: data['userId'] ?? '',
      firestoreId: docId,
    );
  }
}

class PDFProvider with ChangeNotifier {
  List<PdfFileInfo> _pdfFiles = [];
  PdfFileInfo? _currentPdf;
  bool _isLoading = false;
  String _currentUserId = ''; // 현재 사용자 ID 저장
  
  // 서비스 클래스 - Firebase 초기화 이후에 지연 초기화
  StorageService? _storageService;
  SubscriptionService? _subscriptionService;
  
  // 생성자
  PDFProvider() {
    if (kDebugMode) {
      print('🟢 [PDFProvider] 생성자 호출됨');
    }
    
    // StorageService 지연 초기화를 위해 비동기 메서드 호출
    _initializeStorageService();
    
    // 웹 환경에서 사용자 정보 확인
    _checkUserInfoInWeb();
  }
  
  // 웹 환경에서 사용자 정보 확인
  Future<void> _checkUserInfoInWeb() async {
    if (kIsWeb) {
      try {
        // 1초 대기 후 사용자 정보 확인 (Firebase 초기화 기다림)
        await Future.delayed(const Duration(seconds: 1));
        
        if (kDebugMode) {
          print('🟢 [PDFProvider] 웹 사용자 정보 확인 시작');
        }
        
        // JS 함수 호출로 사용자 정보 가져오기 (안전하게 null 체크 추가)
        dynamic userDetails;
        try {
          userDetails = js.context.callMethod('getUserDetails', []);
        } catch (e) {
          if (kDebugMode) {
            print('🔴 [PDFProvider] 사용자 정보 가져오기 JS 호출 오류: $e');
          }
          userDetails = null;
        }
        
        if (userDetails != null && 
            userDetails['uid'] != null && 
            userDetails['uid'].toString().isNotEmpty) {
          final userId = userDetails['uid'].toString();
          
          if (kDebugMode) {
            print('🟢 [PDFProvider] 웹에서 사용자 ID 가져옴: $userId');
          }
          
          // 사용자 ID 설정
          if (_currentUserId != userId) {
            setCurrentUser(userId);
          }
        } else {
          if (kDebugMode) {
            print('🟢 [PDFProvider] 웹에서 사용자 정보를 찾을 수 없음, 익명 사용자로 설정');
          }
          // 사용자 정보가 없는 경우 익명 사용자로 설정
          if (_currentUserId.isEmpty) {
            setCurrentUser('anonymous_${DateTime.now().millisecondsSinceEpoch}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔴 [PDFProvider] 웹 사용자 정보 확인 오류: $e');
        }
      }
    }
  }
  
  // 웹에서 사용자 ID 설정
  Future<bool> setUserIdInWeb(String userId) async {
    if (kIsWeb) {
      try {
        // JS 함수 호출로 사용자 정보 설정
        final result = js.context.callMethod('setUserDetails', [userId]);
        
        if (result == true) {
          if (kDebugMode) {
            print('🟢 [PDFProvider] 웹에서 사용자 ID 설정 성공: $userId');
          }
          
          // PDFProvider에도 사용자 ID 설정
          setCurrentUser(userId);
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔴 [PDFProvider] 웹 사용자 ID 설정 오류: $e');
        }
      }
    }
    
    return false;
  }
  
  // 웹에서 로그아웃
  Future<bool> logoutFromWeb() async {
    if (kIsWeb) {
      try {
        // JS 함수 호출로 로그아웃
        final result = js.context.callMethod('logoutUser', []);
        
        if (result == true) {
          if (kDebugMode) {
            print('🟢 [PDFProvider] 웹에서 로그아웃 성공');
          }
          
          // 익명 사용자로 설정
          setCurrentUser('anonymous_${DateTime.now().millisecondsSinceEpoch}');
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔴 [PDFProvider] 웹 로그아웃 오류: $e');
        }
      }
    }
    
    return false;
  }
  
  // StorageService 초기화 (비동기)
  Future<void> _initializeStorageService() async {
    try {
      if (kDebugMode) {
        print('🟢 [PDFProvider] StorageService 초기화 시작');
      }
      
      // 이미 초기화되어 있으면 건너뜀
      if (_storageService != null) {
        if (kDebugMode) {
          print('🟢 [PDFProvider] StorageService 이미 초기화됨');
        }
        return;
      }
      
      // StorageService 생성
      _storageService = StorageService();
      
      if (kDebugMode) {
        print('🟢 [PDFProvider] StorageService 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [PDFProvider] StorageService 초기화 오류: $e');
      }
    }
  }
  
  // StorageService 안전하게 가져오기 getter
  StorageService get storageService {
    if (_storageService == null) {
      throw Exception('StorageService가 초기화되지 않았습니다');
    }
    return _storageService!;
  }

  // SubscriptionService 주입
  void setSubscriptionService(SubscriptionService subscriptionService) {
    if (kDebugMode) {
      print('🟢 [PDFProvider] SubscriptionService 설정 시작');
      print('🟢 [PDFProvider] 전달된 SubscriptionService 타입: ${subscriptionService.runtimeType}');
    }
    
    try {
      // 서비스 설정 전에 현재 상태 확인
      if (_subscriptionService != null) {
        if (kDebugMode) {
          print('🟠 [PDFProvider] 기존 SubscriptionService가 이미 설정되어 있습니다: ${_subscriptionService.runtimeType}');
        }
      }
      
      // 서비스 설정
      _subscriptionService = subscriptionService;
      
      // 성공 로그
      if (kDebugMode) {
        print('🟢 [PDFProvider] SubscriptionService 설정 완료');
        
        // isPaidUser 테스트
        try {
          final isPaid = _subscriptionService?.isPaidUser;
          print('🟢 [PDFProvider] isPaidUser 확인: $isPaid');
        } catch (e) {
          print('🔴 [PDFProvider] isPaidUser 테스트 중 오류: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [PDFProvider] SubscriptionService 설정 중 오류: $e');
      }
    }
  }

  List<PdfFileInfo> get pdfFiles => _pdfFiles.where((pdf) => pdf.userId == _currentUserId || _currentUserId.isEmpty).toList();
  PdfFileInfo? get currentPdf => _currentPdf;
  bool get isLoading => _isLoading;
  String get currentUserId => _currentUserId; // 현재 사용자 ID getter 추가
  
  // 유료 사용자인지 확인 (클라우드 동기화 기능 가능 여부)
  bool get isPaidUser {
    // 일단 모든 사용자에게 클라우드 동기화 기능 제공 (비로그인 사용자 제외)
    if (_currentUserId.isEmpty || _currentUserId.startsWith('anonymous_')) {
      return false;
    }
    return true;
    
    // 아래는 기존 유료 회원 체크 로직 (현재는 주석 처리)
    /*
    if (_subscriptionService == null) {
      if (kDebugMode) {
        print('🔴 [PDFProvider] isPaidUser 확인 실패: SubscriptionService가 null입니다');
      }
      return false;
    }
    
    bool result = false;
    try {
      if (kDebugMode) {
        print('🟢 [PDFProvider] isPaidUser 확인 시도, SubscriptionService 타입: ${_subscriptionService.runtimeType}');
      }
      
      result = _subscriptionService!.isPaidUser;
      
      if (kDebugMode) {
        print('🟢 [PDFProvider] isPaidUser 확인 결과: $result');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [PDFProvider] isPaidUser 오류: $e');
      }
    }
    return result;
    */
  }
  
  // 현재 사용자 ID 설정
  void setCurrentUser(String userId) {
    if (userId.isNotEmpty) {
      if (kDebugMode) {
        print('[PDFProvider] 사용자 ID 설정: $userId (이전: $_currentUserId)');
      }
      
      // 익명 ID에서 실제 계정으로 전환하는 경우 데이터 마이그레이션
      final bool wasAnonymous = _currentUserId.startsWith('anonymous_') && _currentUserId.isNotEmpty;
      final String oldUserId = _currentUserId;
      
      // 새 사용자 ID 설정
      _currentUserId = userId;
      notifyListeners();
      
      // 사용자 변경 시 해당 사용자의 PDF 목록을 로드
      loadSavedPDFs();
      
      // 이전에 익명 사용자였고 새로운 ID가 익명이 아니면 데이터 마이그레이션
      if (wasAnonymous && !userId.startsWith('anonymous_')) {
        // 약간의 지연 후 마이그레이션 시도 (로드가 완료된 후 실행되도록)
        Future.delayed(const Duration(milliseconds: 500), () {
          migrateAnonymousData(oldUserId, userId);
        });
      }
      
      // 로그인한 모든 사용자는 클라우드 PDF 불러오기 시도
      if (!_currentUserId.startsWith('anonymous_')) {
        try {
          // 클라우드 PDF 로드 시도 (3초 후 다시 한번 시도 - 초기화 지연 대비)
          loadCloudPDFs();
          Future.delayed(const Duration(seconds: 3), () {
            if (_pdfFiles.isEmpty) {
              loadCloudPDFs();  // 한번 더 시도
            }
          });
        } catch (e) {
          if (kDebugMode) {
            print('[PDFProvider] 클라우드 PDF 로드 시도 중 오류: $e');
          }
        }
      }
    }
  }
  
  // 익명 사용자 데이터를 새 계정으로 마이그레이션
  Future<void> migrateAnonymousData(String anonymousId, String newUserId) async {
    if (anonymousId.isEmpty || !anonymousId.startsWith('anonymous_') || newUserId.isEmpty) {
      print('[PDFProvider] 마이그레이션 실패: 유효하지 않은 사용자 ID');
      return;
    }
    
    try {
      print('[PDFProvider] 익명 사용자($anonymousId)에서 새 계정($newUserId)으로 데이터 마이그레이션 시작');
      
      // 익명 사용자의 PDF 파일 찾기
      final anonymousPdfs = _pdfFiles.where((pdf) => pdf.userId == anonymousId).toList();
      
      if (anonymousPdfs.isEmpty) {
        print('[PDFProvider] 마이그레이션할 PDF 파일이 없습니다.');
        return;
      }
      
      print('[PDFProvider] ${anonymousPdfs.length}개의 PDF 파일을 마이그레이션합니다.');
      
      // 각 PDF 파일의 소유자 ID 변경 및 클라우드 동기화
      for (final pdf in anonymousPdfs) {
        // 파일 정보 복사 및 소유자 ID 업데이트
        final updatedPdf = pdf.copyWith(userId: newUserId);
        
        // 로컬 저장소에 변경사항 저장
        final index = _pdfFiles.indexWhere((p) => p.id == pdf.id);
        if (index >= 0) {
          _pdfFiles[index] = updatedPdf;
        }
        
        // 클라우드 동기화 (파일 업로드)
        if (_storageService != null && updatedPdf.localPath != null) {
          try {
            // 로컬 파일 읽기
            final file = File(updatedPdf.localPath!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              
              // 클라우드에 업로드
              final cloudUrl = await _storageService!.uploadPdf(
                updatedPdf.fileName,
                bytes,
                userId: newUserId,
              );
              
              // 클라우드 URL 업데이트
              if (cloudUrl != null) {
                final finalPdf = updatedPdf.copyWith(cloudUrl: cloudUrl);
                
                // 메모리 내 PDF 목록 업데이트
                final index = _pdfFiles.indexWhere((p) => p.id == pdf.id);
                if (index >= 0) {
                  _pdfFiles[index] = finalPdf;
                }
              }
            }
          } catch (e) {
            print('[PDFProvider] PDF 파일 ${pdf.fileName} 업로드 중 오류: $e');
          }
        }
      }
      
      // 변경사항 저장
      await _savePdfs();
      
      print('[PDFProvider] 데이터 마이그레이션 완료');
      notifyListeners();
      
    } catch (e) {
      print('[PDFProvider] 데이터 마이그레이션 중 오류: $e');
    }
  }
  
  // 클라우드에 저장된 PDF 파일 로드 - 외부에서 호출 가능하도록 public으로 변경
  Future<void> loadCloudPDFs() => _loadCloudPDFs();
  
  // 클라우드에 저장된 PDF 파일 로드
  Future<void> _loadCloudPDFs() async {
    // 익명 사용자 체크
    if (_currentUserId.isEmpty || _currentUserId.startsWith('anonymous_')) {
      if (kDebugMode) {
        print('[PDFProvider] 익명 사용자는 클라우드 PDF 로드를 건너뜁니다.');
      }
      return;
    }
    
    if (_currentUserId.isEmpty) return;
    
    try {
      if (kDebugMode) {
        print('[PDFProvider] 클라우드 PDF 로드 시작');
      }
      
      _isLoading = true;
      notifyListeners();
      
      // 타임아웃 추가 (10초)
      final result = await Future.any([
        _fetchCloudPdfs(),
        Future.delayed(const Duration(seconds: 10), () => 
          throw TimeoutException('클라우드 PDF 로드 시간 초과 (10초)')
        ),
      ]);
      
      if (result != null && result.isNotEmpty) {
        if (kDebugMode) {
          print('[PDFProvider] 클라우드 PDF ${result.length}개 발견');
        }
        
        for (final cloudPdf in result) {
          final firestoreId = cloudPdf['id'];
          
          // 이미 동일한 Firestore ID를 가진 PDF가 있는지 확인
          final existingIndex = _pdfFiles.indexWhere((pdf) => pdf.firestoreId == firestoreId);
          
          // 새로운 PDF 객체 생성
          final newPdf = PdfFileInfo.fromFirestore(cloudPdf, firestoreId);
          
          if (existingIndex >= 0) {
            // 기존 항목 업데이트
            _pdfFiles[existingIndex] = newPdf;
          } else {
            // 새 항목 추가
            _pdfFiles.add(newPdf);
          }
        }
        
        // 변경 사항을 로컬에도 저장
        await _savePdfs();
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('[PDFProvider] 클라우드 PDF 로드 타임아웃: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PDFProvider] 클라우드 PDF 로드 오류: $e');
      }
    } finally {
      // 무한 로딩 방지를 위해 강제로 로딩 상태 해제
      _isLoading = false;
      notifyListeners();
    }
  }

  // 클라우드 PDF를 가져오는 작업을 별도 메서드로 분리
  Future<List<Map<String, dynamic>>> _fetchCloudPdfs() async {
    try {
      if (_storageService == null) {
        _initializeStorageService();  // 지연 초기화 시도
        
        if (_storageService == null) {
          if (kDebugMode) {
            print('[PDFProvider] StorageService가 초기화되지 않았습니다');
          }
          return [];
        }
      }
      
      if (_currentUserId.isEmpty || _currentUserId.startsWith('anonymous_')) {
        if (kDebugMode) {
          print('[PDFProvider] 로그인한 사용자가 아니어서 클라우드 PDF를 가져올 수 없습니다');
        }
        return [];
      }
      
      // Firebase에서 해당 사용자의 PDF 메타데이터 가져오기
      if (kDebugMode) {
        print('[PDFProvider] 사용자 ID로 클라우드 PDF 가져오기 시도: $_currentUserId');
      }
      
      final cloudPdfs = await _storageService!.getUserPdfFiles(_currentUserId);
      
      if (cloudPdfs.isEmpty && kDebugMode) {
        print('[PDFProvider] 클라우드에서 가져온 PDF가 없습니다');
      }
      
      return cloudPdfs;
    } catch (e) {
      if (kDebugMode) {
        print('[PDFProvider] Firebase PDF 조회 중 오류: $e');
      }
      return [];
    }
  }

  // PDF 파일 선택
  Future<void> pickPDF(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 익명 사용자 ID 설정 (로그인하지 않은 경우)
      if (_currentUserId.isEmpty) {
        // 디바이스 ID나 세션 ID를 활용한 익명 사용자 식별
        _currentUserId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
        
        if (kDebugMode) {
          print('🟠 [PDFProvider] 익명 사용자 ID 생성: $_currentUserId');
        }
      }
      
      // 비로그인 사용자 PDF 추가 횟수 확인
      if (_currentUserId.startsWith('anonymous_')) {
        final int anonymousCount = _pdfFiles.where((pdf) => 
          pdf.userId.startsWith('anonymous_')).length;
          
        // 익명 사용자 최대 3개 제한
        if (anonymousCount >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('비로그인 사용자는 최대 3개까지 PDF를 추가할 수 있습니다. 더 많은 PDF를 관리하려면 로그인하세요.'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: '로그인',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: 로그인 화면으로 이동하는 로직 구현
                  if (kDebugMode) {
                    print('로그인 기능은 아직 구현되지 않았습니다.');
                  }
                },
              ),
            ),
          );
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // 항상 데이터를 가져옴 (웹과 네이티브 모두)
      );
      
      if (result != null) {
        final fileName = result.files.single.name;
        final bytes = result.files.single.bytes;
        
        if (bytes != null) {
          // PDF 파일 크기 제한 (비로그인: 5MB 이하)
          final bool isAnonymous = _currentUserId.startsWith('anonymous_');
          final int maxSize = isAnonymous ? 5 * 1024 * 1024 : 50 * 1024 * 1024; // 5MB or 50MB
          
          if (isAnonymous && bytes.length > maxSize) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('비로그인 사용자는 5MB 이하의 PDF만 추가할 수 있습니다. 더 큰 파일을 관리하려면 로그인하세요.'),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.orange,
              ),
            );
            _isLoading = false;
            notifyListeners();
            return;
          }
          
          // ID 및 기본 파일 정보 생성
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          String? cloudUrl;
          String? firestoreId;
          
          // 유료 사용자인 경우 클라우드에도 저장
          if (isPaidUser && !isAnonymous) {
            // Firebase Storage에 업로드
            cloudUrl = await _storageService?.uploadPdf(fileName, bytes, userId: _currentUserId);
            firestoreId = await _getFirestoreId(cloudUrl);
            
            if (kDebugMode) {
              print('[PDFProvider] 클라우드 업로드 성공: $cloudUrl');
            }
          }
          
          // PDF 객체 생성
          final newPdf = PdfFileInfo(
            id: id,
            fileName: fileName,
            url: cloudUrl ?? (kIsWeb ? null : result.files.single.path),
            file: kIsWeb ? null : File(result.files.single.path ?? ''),
            createdAt: DateTime.now(),
            size: bytes.length,
            bytes: bytes,
            userId: _currentUserId,
            firestoreId: firestoreId,
          );
          
          _pdfFiles.add(newPdf);
          _currentPdf = newPdf;
          
          // 로컬에 PDF 정보 저장
          await _savePdfs();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF 파일 "$fileName"이(가) 추가되었습니다${isPaidUser && !isAnonymous ? ' (클라우드 동기화됨)' : ''}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF 파일 데이터를 읽을 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [PDFProvider] PDF 파일 선택 오류: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF 파일 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // URL로부터 Firestore ID 가져오기
  Future<String?> _getFirestoreId(String? url) async {
    if (url == null) return null;
    
    try {
      // URL과 일치하는 Firestore 문서 찾기
      final snapshot = await FirebaseFirestore.instance
          .collection('pdf_files')
          .where('url', isEqualTo: url)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('Firestore ID 가져오기 오류: $e');
    }
    
    return null;
  }

  void setCurrentPDF(PdfFileInfo file) {
    _currentPdf = file;
    notifyListeners();
  }

  // SharedPreferences를 사용하여 PDF 목록 저장
  Future<void> _savePdfs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pdfsJson = _pdfFiles.map((pdf) => json.encode(pdf.toJson())).toList();
      await prefs.setStringList('pdf_files', pdfsJson);
    } catch (e) {
      debugPrint('PDF 파일 저장 오류: $e');
    }
  }

  // 저장된 PDF 파일들 로드
  Future<void> loadSavedPDFs([BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 타임아웃 추가 (15초)
      await Future.any([
        _loadSavedPDFsInternal(context),
        Future.delayed(const Duration(seconds: 15), () => 
          throw TimeoutException('PDF 파일 로드 시간 초과 (15초)')
        ),
      ]);
    } on TimeoutException catch (e) {
      debugPrint('PDF 파일 로드 타임아웃: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 로드 시간이 초과되었습니다. 다시 시도해주세요.'))
        );
      }
    } catch (e) {
      debugPrint('PDF 파일 로드 오류: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 로드 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      // 무한 로딩 방지를 위해 강제로 로딩 상태 해제
      _isLoading = false;
      notifyListeners();
    }
  }

  // 내부 로드 로직을 별도 메서드로 분리
  Future<void> _loadSavedPDFsInternal([BuildContext? context]) async {
    // 현재 사용자 ID 가져오기
    final userId = _getCurrentUserId();
    
    if (kDebugMode) {
      print('[PDFProvider] PDF 로드 시작. 현재 사용자: $userId');
    }
    
    // 로컬 저장소에서 PDF 목록 불러오기
    final prefs = await SharedPreferences.getInstance();
    final pdfsJson = prefs.getStringList('pdf_files');
    
    if (pdfsJson != null && pdfsJson.isNotEmpty) {
      _pdfFiles = pdfsJson
          .map((item) => PdfFileInfo.fromJson(json.decode(item)))
          .toList();
          
      if (kDebugMode) {
        print('[PDFProvider] 로컬에서 ${_pdfFiles.length}개 PDF 파일 로드됨');
        // 사용자 ID별 파일 개수 출력
        final userCounts = <String, int>{};
        for (final pdf in _pdfFiles) {
          userCounts[pdf.userId] = (userCounts[pdf.userId] ?? 0) + 1;
        }
        print('[PDFProvider] 사용자별 PDF 개수: $userCounts');
      }
    }
    
    // 로그인 사용자인 경우 클라우드 PDF도 불러오기
    if (!userId.startsWith('anonymous_') && userId.isNotEmpty) {
      if (kDebugMode) {
        print('[PDFProvider] 로그인 사용자($userId)의 클라우드 PDF 로드 시도');
      }
      await _loadCloudPDFs();
    } else {
      if (kDebugMode) {
        print('[PDFProvider] 익명 사용자($userId)는 클라우드 PDF 로드를 건너뜁니다.');
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 300)); // 로딩 시뮬레이션
  }

  Future<void> deletePDF(PdfFileInfo pdfInfo, [BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 유료 사용자이고 클라우드에 저장된 파일인 경우 Cloud Storage에서도 삭제
      if (isPaidUser && pdfInfo.isCloudStored && pdfInfo.firestoreId != null) {
        await _storageService!.deletePdf(pdfInfo.url!, pdfInfo.firestoreId!);
      }
      
      // 로컬 목록에서 삭제
      _pdfFiles.removeWhere((pdf) => pdf.id == pdfInfo.id);
      
      // 삭제한 PDF가 현재 선택된 PDF라면 현재 PDF 초기화
      if (_currentPdf?.id == pdfInfo.id) {
        _currentPdf = pdfFiles.isNotEmpty ? pdfFiles.first : null;
      }
      
      // 로컬 저장소에 변경사항 저장
      await _savePdfs();
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 "${pdfInfo.fileName}"이(가) 삭제되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('PDF 파일 삭제 오류: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 현재 사용자 ID 가져오기
  String _getCurrentUserId() {
    if (_currentUserId.isNotEmpty) {
      return _currentUserId;
    }
    
    // 웹에서 사용자 ID 가져오기 시도
    if (kIsWeb) {
      try {
        if (kDebugMode) {
          print('[PDFProvider] 웹에서 사용자 정보 가져오기 시도');
        }
        
        // JS 함수 호출을 통한 사용자 정보 가져오기 (안전하게 null 체크 추가)
        dynamic userDetails;
        try {
          userDetails = js.context.callMethod('getUserDetails', []);
        } catch (e) {
          if (kDebugMode) {
            print('🔴 [PDFProvider] 사용자 정보 가져오기 JS 호출 오류: $e');
          }
          userDetails = null;
        }
        
        if (userDetails != null && 
            userDetails['uid'] != null && 
            userDetails['uid'].toString().isNotEmpty) {
          _currentUserId = userDetails['uid'].toString();
          
          if (kDebugMode) {
            print('[PDFProvider] 웹에서 사용자 ID 가져옴: $_currentUserId');
          }
          
          return _currentUserId;
        }
        
        if (kDebugMode) {
          print('[PDFProvider] 웹에서 사용자 정보를 가져올 수 없음');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PDFProvider] 웹에서 사용자 정보 가져오기 오류: $e');
        }
      }
    }
    
    // 저장된 사용자 ID 가져오기 시도
    try {
      SharedPreferences.getInstance().then((prefs) {
        final savedUserId = prefs.getString('user_id');
        if (savedUserId != null && savedUserId.isNotEmpty) {
          _currentUserId = savedUserId;
          
          if (kDebugMode) {
            print('[PDFProvider] 저장된 사용자 ID 사용: $_currentUserId');
          }
          
          // 클라우드 PDF 로드 시도
          if (!_currentUserId.startsWith('anonymous_')) {
            _loadCloudPDFs();
          }
        } else {
          // 저장된 ID가 없으면 익명 ID 생성
          _currentUserId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
          if (kDebugMode) {
            print('[PDFProvider] 익명 사용자 ID 생성: $_currentUserId');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[PDFProvider] 저장된 사용자 ID 가져오기 오류: $e');
      }
    }
    
    // 기본값으로 익명 ID 반환
    if (_currentUserId.isEmpty) {
      _currentUserId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      if (kDebugMode) {
        print('[PDFProvider] 기본 익명 사용자 ID 생성: $_currentUserId');
      }
    }
    
    return _currentUserId;
  }
} 