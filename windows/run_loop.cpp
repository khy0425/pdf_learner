#include "run_loop.h"

#include <windows.h>

#include <algorithm>

RunLoop::RunLoop() {}

RunLoop::~RunLoop() {}

void RunLoop::Run() {
  bool keep_running = true;
  TimePoint next_flutter_event_time = TimePoint::clock::now();
  while (keep_running) {
    std::chrono::nanoseconds wait_duration =
        std::max(std::chrono::nanoseconds(0),
                next_flutter_event_time - TimePoint::clock::now());
    ::MsgWaitForMultipleObjects(
        0, nullptr, FALSE, static_cast<DWORD>(wait_duration.count() / 1000000),
        QS_ALLINPUT);
    bool has_messages = false;
    MSG message;
    // Get all messages
    while (::PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
      has_messages = true;
      if (message.message == WM_QUIT) {
        keep_running = false;
        break;
      }
      ::TranslateMessage(&message);
      ::DispatchMessage(&message);
    }
    // Flutter tasks are performed after the Windows message loop's work.
    for (const auto& task : task_runners_) {
      task();
    }
  }
}

void RunLoop::RegisterFlutterInstance(
    flutter::FlutterEngine* flutter_instance) {
  task_runners_.push_back([flutter_instance]() {
    if (flutter_instance) {
      flutter_instance->ProcessMessages();
    }
  });
}

void RunLoop::Stop() {
  PostQuitMessage(0);
} 