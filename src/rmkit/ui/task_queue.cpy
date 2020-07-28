#include <functional>
#include <thread>
#include <mutex>

#include "../input/input.h"


namespace ui:
  class TaskQueue:
    public:
    static deque<std::function<void()>> tasks
    static std::mutex task_m

    static void wakeup():
      _ := write(input::ipc_fd[1], "WAKEUP", sizeof("WAKEUP"));

    static void add_task(std::function<void()> t):
      TaskQueue::tasks.push_back(t)
      TaskQueue::wakeup()

    static void run_task():
      if TaskQueue::tasks.size() == 0:
        return

      t := TaskQueue::tasks.front()
      TaskQueue::tasks.pop_front()
      try:
        thread *th = new thread([=]() {
          lock_guard<mutex> guard(task_m)
          t()
          TaskQueue::wakeup()
        })
        th->detach()
      catch (const std::exception& e):
        print "NEW THREAD EXC", e.what()
        TaskQueue::wakeup()


