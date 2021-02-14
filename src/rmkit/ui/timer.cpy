#include <cstdint>
#include <chrono>
#include <functional>
#include <memory>
#include <set>

namespace ui:
  class Timer:
    public:
    typedef std::function<void()> CB
    CB callback
    std::chrono::high_resolution_clock::time_point end
    std::chrono::milliseconds timeout

    Timer(CB callback, std::chrono::milliseconds timeout, bool interval=false): \
        callback(callback), \
        end(std::chrono::high_resolution_clock::now() + timeout), \
        timeout(interval ? timeout : std::chrono::milliseconds(0)):
      pass

    bool is_interval():
      return timeout > std::chrono::milliseconds(0)

    void restart():
      end = std::chrono::high_resolution_clock::now() + timeout

    long remaining_ms():
      auto remaining = end - std::chrono::high_resolution_clock::now()
      return std::chrono::duration_cast<std::chrono::milliseconds>(remaining).count()

    bool is_elapsed():
      return end <= std::chrono::high_resolution_clock::now()

  typedef std::shared_ptr<Timer> TimerPtr

  class TimerList:
    protected:
    struct Cmp:
      bool operator()(const TimerPtr &lhs, const TimerPtr &rhs) const:
        return lhs->end < rhs->end // sort soonest to the front
    ;

    std::set<TimerPtr, Cmp> timers

    public:
    TimerPtr front():
      return *timers.begin()

    bool empty():
      return timers.empty()

    void cancel(TimerPtr timer):
      timers.erase(timer);

    void clear():
      timers.clear()

    TimerPtr set_timeout(Timer::CB cb, long ms):
      auto timer = std::make_shared<Timer>(cb, std::chrono::milliseconds(ms))
      timers.insert(timer)
      return timer

    TimerPtr set_interval(Timer::CB cb, long ms)
      auto timer = std::make_shared<Timer>(cb, std::chrono::milliseconds(ms), true)
      timers.insert(timer)
      return timer

    long next_timeout_ms():
      if (timers.empty()):
        return 0
      else:
        // timeout of 0 means indefinite, so if we have a timer waiting,
        // this needs to be a minimum of 1
        return std::max(1L, front()->remaining_ms())

    void trigger():
      while (!empty()):
        TimerPtr t = front()
        if (!t->is_elapsed()):
          break
        timers.erase(t)
        if (t->is_interval()):
          t->restart()
          timers.insert(t)
        t->callback()

    static TimerList * get():
      static TimerList singleton
      return &singleton

  // function: set_timeout
  //   calls `callback` after the given timeout (in milliseconds)
  //   the returned shared_ptr can be used to cancel the timer
  inline TimerPtr set_timeout(Timer::CB cb, long ms):
    return TimerList::get()->set_timeout(cb, ms)

  // function: set_interval
  //   calls `callback` repeatedly at the given interval (in milliseconds)
  //   the returned shared_ptr can be used to cancel the timer
  inline TimerPtr set_interval(Timer::CB cb, long ms):
    return TimerList::get()->set_interval(cb, ms)

  // function: cancel_timer
  //   cancels a timer started by either set_timeout or set_interval
  inline void cancel_timer(TimerPtr timer)
    TimerList::get()->cancel(timer)
