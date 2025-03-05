#ifndef WIN32_WINDOW_H_
#define WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates and shows a win32 window with |title| and position and size using
  // |origin| and |size|. New windows are created on the default monitor. Window
  // sizes are specified to the OS in physical pixels, automatically scaled to the
  // default monitor's DPI.
  bool CreateAndShow(const std::wstring& title,
                    const Point& origin,
                    const Size& size);

  // Draw into the client area of the window.
  virtual void OnPaint() = 0;

  // Hide and close the window.
  void Destroy();

  // Registers a callback to be called when the window is closing.
  void SetQuitHandler(std::function<void()> quit_handler) {
    quit_handler_ = std::move(quit_handler);
  }

  // Return a HWND handle for this window.
  HWND GetHandle();

  // Sets |content| as a child window.
  void SetChildContent(HWND content);

  // Return true if the |window| is a Win32Window.
  static bool IsWindow(HWND const window) noexcept;

 protected:
  // Processes and route salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  virtual LRESULT MessageHandler(HWND window,
                               UINT const message,
                               WPARAM const wparam,
                               LPARAM const lparam) noexcept;

  // Called when CreateAndShow is called, allowing subclass window-related setup.
  virtual bool OnCreate();

  // Called when Destroy is called.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // Update the window frame's theme to match the system theme.
  static bool UpdateTheme(HWND const window);

  bool quit_on_close_ = false;
  static WNDCLASS RegisterWindowClass();

  HWND window_handle_ = nullptr;
  HWND child_content_ = nullptr;
  std::function<void()> quit_handler_ = nullptr;
};

#endif  // WIN32_WINDOW_H_ 