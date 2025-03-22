import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.example.pdf_learner_v2/platform"
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 플러터 엔진 설정
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
    
    // 메소드 콜 핸들러 등록
    setupMethodChannel()
    
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
}
