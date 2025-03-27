import Flutter
import UIKit
import UserNotifications
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.example.pdf_learner_v2/platform"
  private let FILE_PICKER_CHANNEL = "com.example.pdf_learner_v2/file_picker"
  private var methodChannel: FlutterMethodChannel?
  private var filePickerChannel: FlutterMethodChannel?
  private var filePickerResult: FlutterResult?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    
    // 메인 채널 설정
    methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
    setupMethodChannel()
    
    // 파일 선택 채널 설정
    filePickerChannel = FlutterMethodChannel(name: FILE_PICKER_CHANNEL, binaryMessenger: controller.binaryMessenger)
    setupFilePickerChannel()
    
    // 알림 권한 요청
    requestNotificationPermission()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannel() {
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      switch call.method {
      case "pickFile":
        self.handlePickFile(arguments: call.arguments as? [String: Any], result: result)
      case "saveFile":
        self.handleSaveFile(arguments: call.arguments as? [String: Any], result: result)
      case "shareContent":
        self.handleShareContent(arguments: call.arguments as? [String: Any], result: result)
      case "openAppRating":
        self.handleOpenAppRating(arguments: call.arguments as? [String: Any], result: result)
      case "vibrate":
        self.handleVibrate(arguments: call.arguments as? [String: Any], result: result)
      case "showNotification":
        self.handleShowNotification(arguments: call.arguments as? [String: Any], result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func setupFilePickerChannel() {
    filePickerChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "pickFiles":
        self?.handlePickFiles(call: call, result: result)
      case "getDirectoryPath":
        self?.handleGetDirectoryPath(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  // MARK: - 파일 선택 처리
  private func handlePickFile(arguments: [String: Any]?, result: @escaping FlutterResult) {
    // 실제 구현은 UIDocumentPickerViewController 활용 필요
    // 현재는 샘플 코드로 nil 반환
    result(nil)
  }
  
  // MARK: - 파일 저장 처리
  private func handleSaveFile(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard let fileName = arguments?["fileName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "파일명이 필요합니다", details: nil))
      return
    }
    
    // 실제 구현은 UIDocumentInteractionController 활용 필요
    // 현재는 샘플 코드로 nil 반환
    result(nil)
  }
  
  // MARK: - 콘텐츠 공유 처리
  private func handleShareContent(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard let title = arguments?["title"] as? String,
          let text = arguments?["text"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "제목과 내용이 필요합니다", details: nil))
      return
    }
    
    let filePath = arguments?["filePath"] as? String
    var items: [Any] = [text]
    
    if let filePath = filePath, let fileURL = URL(string: filePath) {
      items.append(fileURL)
    }
    
    // 메인 스레드에서 UI 작업 실행
    DispatchQueue.main.async {
      let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
      
      if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
        activityViewController.popoverPresentationController?.sourceView = rootViewController.view
        rootViewController.present(activityViewController, animated: true, completion: nil)
      }
    }
    
    result(true)
  }
  
  // MARK: - 앱 평가 페이지 열기
  private func handleOpenAppRating(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard let appId = arguments?["appId"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "앱 ID가 필요합니다", details: nil))
      return
    }
    
    // App Store에서 앱 리뷰 페이지 열기
    let urlString = "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review"
    
    if let url = URL(string: urlString) {
      DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
      result(true)
    } else {
      result(false)
    }
  }
  
  // MARK: - 진동 처리
  private func handleVibrate(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard let pattern = arguments?["pattern"] as? Int else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "진동 패턴이 필요합니다", details: nil))
      return
    }
    
    // 진동 패턴에 따라 다른 피드백 스타일 사용
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    switch pattern {
    case 0: // light
      feedbackStyle = .light
    case 1: // medium
      feedbackStyle = .medium
    case 2: // heavy
      feedbackStyle = .heavy
    case 3: // success
      let notificationFeedback = UINotificationFeedbackGenerator()
      notificationFeedback.notificationOccurred(.success)
      result(nil)
      return
    case 4: // warning
      let notificationFeedback = UINotificationFeedbackGenerator()
      notificationFeedback.notificationOccurred(.warning)
      result(nil)
      return
    case 5: // error
      let notificationFeedback = UINotificationFeedbackGenerator()
      notificationFeedback.notificationOccurred(.error)
      result(nil)
      return
    default:
      feedbackStyle = .medium
    }
    
    let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
    generator.prepare()
    generator.impactOccurred()
    
    result(nil)
  }
  
  // MARK: - 알림 권한 요청
  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("알림 권한 요청 오류: \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - 알림 표시
  private func handleShowNotification(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard let title = arguments?["title"] as? String,
          let body = arguments?["body"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "제목과 내용이 필요합니다", details: nil))
      return
    }
    
    let payload = arguments?["payload"] as? String
    
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    
    if let payload = payload {
      content.userInfo = ["payload": payload]
    }
    
    // 즉시 알림 표시
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        result(FlutterError(code: "NOTIFICATION_ERROR", message: "알림 표시 중 오류 발생", details: error.localizedDescription))
      } else {
        result(nil)
      }
    }
  }
  
  private func handlePickFiles(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let allowedExtensions = args["allowedExtensions"] as? [String],
          let allowMultiple = args["allowMultiple"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments",
                        details: nil))
      return
    }
    
    filePickerResult = result
    
    // 허용된 파일 타입 설정
    var contentTypes: [UTType] = []
    for ext in allowedExtensions {
      if let utType = UTType(tag: ext, tagClass: .filenameExtension, conformingTo: nil) {
        contentTypes.append(utType)
      }
    }
    
    // 기본 PDF 타입 추가
    if contentTypes.isEmpty {
      contentTypes = [.pdf]
    }
    
    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
    documentPicker.delegate = self
    documentPicker.allowsMultipleSelection = allowMultiple
    
    if let viewController = window?.rootViewController {
      viewController.present(documentPicker, animated: true)
    }
  }
  
  private func handleGetDirectoryPath(result: @escaping FlutterResult) {
    if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      result(documentsPath.path)
    } else {
      result(nil)
    }
  }
}

extension AppDelegate: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    var fileDataList: [[String: Any]] = []
    
    for url in urls {
      do {
        // 파일 접근 권한 유지
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
          if shouldStopAccessing {
            url.stopAccessingSecurityScopedResource()
          }
        }
        
        let resourceValues = try url.resourceValues(forKeys: [.nameKey, .fileSizeKey])
        let name = resourceValues.name ?? url.lastPathComponent
        let size = resourceValues.fileSize ?? 0
        let extension = url.pathExtension
        
        let fileData: [String: Any] = [
          "name": name,
          "path": url.path,
          "size": size,
          "extension": extension,
          "uri": url.absoluteString
        ]
        
        fileDataList.append(fileData)
      } catch {
        print("Error getting file info: \(error)")
      }
    }
    
    filePickerResult?(fileDataList)
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    filePickerResult?(nil)
  }
}
