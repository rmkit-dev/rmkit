#include <functional>

#define PLS_DEFINE_SIGNAL(S, D) \
class S : public PLS::PubSub<D> { \
    public:         \
    typedef D DATA; \
};

#define PLS_DELEGATE(FUNC, ...) [=](auto &d) { FUNC(d); }
#define PLS_LAMBDA(...) [=](__VA_ARGS__ )

namespace PLS:
  template<class T>
  class PubSub:
    public:
    vector<std::function<void(T&)>> cbs;

    PubSub():
      pass

    void operator+=(std::function<void (T&)> f):
      cbs.push_back(f)

    void operator()():
      T data
      for auto cb : cbs:
        cb(data)

    void operator()(T &data):
      for auto cb : cbs:
        cb(data)

    void operator()(T *data):
      for auto cb : cbs:
        cb(*data)

    void clear():
      cbs.clear()

    bool empty():
      return cbs.empty()

  template<typename T>
  class Observable:
    T value

    public:
    vector<std::function<void(T&)>> cbs;
    Observable():
      pass

    operator T():
      return value

    void operator+=(std::function<void (T&)> f):
      cbs.push_back(f)

    void operator()(std::function<void (T&)> f):
      cbs.push_back(f)

    def operator=(T *data):
      self.value = *data
      for auto cb : cbs:
        cb(data)

    def operator=(T data):
      self.value = data
      for auto cb : cbs:
        cb(data)
