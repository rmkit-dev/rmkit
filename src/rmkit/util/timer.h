#ifndef RMKIT_TIMER_H
#define RMKIT_TIMER_H

#include <cstdint>
#include <chrono>
#include <functional>
#include <memory>
#include <set>

class Timer {
public:
    typedef std::function<void()> CB;
    CB callback;
    std::chrono::high_resolution_clock::time_point end;

    template<typename T>
    Timer(CB callback, T timeout)
        : callback(callback),
        end(std::chrono::high_resolution_clock::now() + timeout)
    {}

    auto remaining()
    {
        return end - std::chrono::high_resolution_clock::now();
    }

    bool is_elapsed()
    {
        return end <= std::chrono::high_resolution_clock::now();
    }
};

class TimerList {
protected:
    typedef std::shared_ptr<Timer> TimerPtr;

    struct Cmp {
        bool operator()(const TimerPtr &lhs, const TimerPtr &rhs) const {
            // sort soonest to the front
            return lhs->end < rhs->end;
        }
    };

public:
    std::set<TimerPtr, Cmp> timers;

public:
    TimerPtr front() { return *timers.begin(); }
    bool empty() { return timers.empty(); }
    void cancel(TimerPtr timer) { timers.erase(timer); }
    void clear() { timers.clear(); }

    template<typename T>
    TimerPtr set_timeout(Timer::CB cb, T timeout)
    {
        auto timer = std::make_shared<Timer>(cb, timeout);
        timers.insert(timer);
        return timer;
    }

    TimerPtr set_timeout_ms(Timer::CB cb, long ms)
    {
        return set_timeout(cb, std::chrono::milliseconds(ms));
    }

    template<typename T>
    TimerPtr set_interval(Timer::CB cb, T timeout)
    {
        return set_timeout([=]() { cb(); set_interval(cb, timeout); }, timeout);
    }

    TimerPtr set_interval_ms(Timer::CB cb, long ms)
    {
        return set_interval(cb, std::chrono::milliseconds(ms));;
    }

    int64_t next_timeout_usec()
    {
        if (timers.empty())
            return 0;
        else
            // timeout of 0 means indefinite, so if we have a timer waiting,
            // this needs to be a minimum of 1
            return std::max(int64_t(1), std::chrono::duration_cast<std::chrono::microseconds>(front()->remaining()).count());
    }

    void trigger()
    {
        while (!empty()) {
            TimerPtr t = front();
            if (!t->is_elapsed()) break;
            timers.erase(t);
            t->callback();
        }
    }
};

#endif // RMKIT_TIMER_H
