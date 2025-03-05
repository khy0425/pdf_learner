#ifndef RUN_LOOP_H_
#define RUN_LOOP_H_

#include <flutter/flutter_engine.h>

#include <chrono>
#include <functional>
#include <vector>

// A runloop that will service events for Flutter instances.
class RunLoop {
 public:
  RunLoop();
  ~RunLoop();

  // Prevent copying
  RunLoop(RunLoop const&) = delete;
  RunLoop& operator=(RunLoop const&) = delete;

  // Runs the run loop until the application quits.
  void Run();

  // Registers the given Flutter instance for event servicing.
  void RegisterFlutterInstance(flutter::FlutterEngine* flutter_instance);

  // Stops the loop.
  void Stop();

 private:
  using TimePoint = std::chrono::steady_clock::time_point;

  std::vector<std::function<void()>> task_runners_;
};

#endif  // RUN_LOOP_H_ 