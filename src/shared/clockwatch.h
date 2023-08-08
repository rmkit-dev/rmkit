#ifndef UI______UI______INPUT__________SHARED__CLOCKWATCH_CPY_H
#define UI______UI______INPUT__________SHARED__CLOCKWATCH_CPY_H
#pragma once
#include <time.h>
#include <chrono>

class ClockWatch {
  public:
  chrono::high_resolution_clock::time_point t1;

  ClockWatch() {
    t1 = chrono::high_resolution_clock::now(); }

  auto elapsed() {
    auto t2 = chrono::high_resolution_clock::now();
    chrono::duration<double> time_span = chrono::duration_cast<chrono::duration<double>>(t2 - t1);
    return time_span.count(); }; };


#endif