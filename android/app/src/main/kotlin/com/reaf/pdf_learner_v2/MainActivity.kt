package com.reaf.pdf_learner_v2

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.content.Context
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.pdf_learner_v2/platform"
    private lateinit var methodChannel: MethodChannel
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFile" -> {
                    handlePickFile(call.arguments as Map<String, Any>, result)
                }
                "saveFile" -> {
                    handleSaveFile(call.arguments as Map<String, Any>, result)
                }
                "shareContent" -> {
                    handleShareContent(call.arguments as Map<String, Any>, result)
                }
                "openAppRating" -> {
                    handleOpenAppRating(call.arguments as Map<String, Any>, result)
                }
                "vibrate" -> {
                    handleVibrate(call.arguments as Map<String, Any>, result)
                }
                "showNotification" -> {
                    handleShowNotification(call.arguments as Map<String, Any>, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun handlePickFile(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val allowedExtensions = arguments["allowedExtensions"] as? List<String> ?: listOf("pdf")
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, allowedExtensions.map { "application/$it" }.toTypedArray())
            }
            
            // TODO: 결과를 처리하기 위한 ActivityResultLauncher 구현 필요
            // 현재 샘플 코드에서는 바로 null 반환
            result.success(null)
        } catch (e: Exception) {
            result.error("PICK_FILE_ERROR", "파일 선택 중 오류 발생", e.message)
        }
    }
    
    private fun handleSaveFile(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val fileName = arguments["fileName"] as String
            val content = arguments["content"] as? String
            
            // 임시 파일 생성
            val file = File(context.cacheDir, fileName)
            
            if (content != null) {
                FileOutputStream(file).use { outputStream ->
                    outputStream.write(content.toByteArray())
                }
            }
            
            // 파일 저장 인텐트 생성
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/octet-stream"
                putExtra(Intent.EXTRA_TITLE, fileName)
            }
            
            // TODO: 결과를 처리하기 위한 ActivityResultLauncher 구현 필요
            // 현재 샘플 코드에서는 바로 null 반환
            result.success(null)
        } catch (e: Exception) {
            result.error("SAVE_FILE_ERROR", "파일 저장 중 오류 발생", e.message)
        }
    }
    
    private fun handleShareContent(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val title = arguments["title"] as String
            val text = arguments["text"] as String
            val filePath = arguments["filePath"] as? String
            
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TEXT, text)
                
                if (filePath != null) {
                    val file = File(filePath)
                    val uri = FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.fileprovider",
                        file
                    )
                    putExtra(Intent.EXTRA_STREAM, uri)
                    type = "application/pdf"
                } else {
                    type = "text/plain"
                }
            }
            
            val chooser = Intent.createChooser(shareIntent, title)
            startActivity(chooser)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SHARE_ERROR", "공유 중 오류 발생", e.message)
            result.success(false)
        }
    }
    
    private fun handleOpenAppRating(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val packageName = arguments["packageName"] as String
            
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY or Intent.FLAG_ACTIVITY_NEW_DOCUMENT or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
            
            try {
                startActivity(intent)
                result.success(true)
            } catch (e: android.content.ActivityNotFoundException) {
                // 구글 플레이 스토어가 없는 경우 웹 URL로 시도
                startActivity(Intent(Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$packageName")))
                result.success(true)
            }
        } catch (e: Exception) {
            result.error("RATING_ERROR", "평점 페이지 열기 중 오류 발생", e.message)
            result.success(false)
        }
    }
    
    private fun handleVibrate(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val pattern = (arguments["pattern"] as Number).toInt()
            
            // 패턴에 따른 진동 효과 결정
            val vibrationEffect = when (pattern) {
                0 -> VibrationEffect.createOneShot(20, VibrationEffect.DEFAULT_AMPLITUDE) // light
                1 -> VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE) // medium
                2 -> VibrationEffect.createOneShot(80, VibrationEffect.DEFAULT_AMPLITUDE) // heavy
                3 -> VibrationEffect.createWaveform(longArrayOf(0, 60, 50, 60), -1) // success
                4 -> VibrationEffect.createWaveform(longArrayOf(0, 80, 100, 80), -1) // warning
                5 -> VibrationEffect.createWaveform(longArrayOf(0, 80, 50, 80, 50, 120), -1) // error
                else -> VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE)
            }
            
            // 버전에 따른 Vibrator 획득
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val vibrator = vibratorManager.defaultVibrator
                vibrator.vibrate(vibrationEffect)
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(vibrationEffect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(40)
                }
            }
            
            result.success(null)
        } catch (e: Exception) {
            result.error("VIBRATION_ERROR", "진동 실행 중 오류 발생", e.message)
        }
    }
    
    private fun handleShowNotification(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val title = arguments["title"] as String
            val body = arguments["body"] as String
            val payload = arguments["payload"] as? String
            
            val channelId = "pdf_learner_v2_notifications"
            val notificationId = UUID.randomUUID().hashCode()
            
            // Android 8.0 이상에서 필요한 알림 채널 생성
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "PDF Learner 알림",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "PDF Learner 앱 알림"
                }
                
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
            
            // 알림 클릭 시 실행될 인텐트 (앱 열기)
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            )
            
            // 알림 생성
            val notification = NotificationCompat.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(R.drawable.notification_icon)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .build()
            
            // 알림 표시
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, notification)
            
            result.success(null)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "알림 표시 중 오류 발생", e.message)
        }
    }
}
