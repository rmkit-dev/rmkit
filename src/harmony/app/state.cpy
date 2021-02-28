// This class holds app state used across components
// if planned right, we can serialize it down the line

#include "brush.h"

namespace app_ui:
  using PLS::Observable

  class AppState:
    public:
    static AppState instance

    Observable<bool> reject_touch
    Observable<bool> disable_history

    Observable<remarkable_color> color
    Observable<app_ui::Brush*> brush
    Observable<app_ui::BrushSize> stroke_width

    AppState():
      pass

    static AppState* get():
      return &instance

  AppState AppState::instance = AppState()
  auto &STATE = AppState::instance
