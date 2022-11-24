#include <math.h>
#include <string>
#include <vector>
#include <fstream>
#include "calc.h"

// arm-linux-gnueabihf-g++ (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0
// links against 2.29 instead of 2.4, but the rM1 may not have 2.29 symbols
// NOTE: use `objdump -T src/build/<binary> | grep GLIBC_` to check symbols
//
#ifdef REMARKABLE
__asm__(".symver log,log@GLIBC_2.4"); // was 2.29
__asm__(".symver pow,pow@GLIBC_2.4"); // was 2.29
#endif

void Calculator::handleNumPad(int keyid) {
  switch (keyid) {
    case keycodes::kexit:
        exit(0);
    case keycodes::kzero:
        maybePush();
        append('0');
        break;
    case keycodes::kone:
        maybePush();
        append('1');
        break;
    case keycodes::ktwo:
        maybePush();
        append('2');
        break;
    case keycodes::kthree:
        maybePush();
        append('3');
        break;
    case keycodes::kfour:
        maybePush();
        append('4');
        break;
    case keycodes::kfive:
        maybePush();
        append('5');
        break;
    case keycodes::ksix:
        maybePush();
        append('6');
        break;
    case keycodes::kseven:
        maybePush();
        append('7');
        break;
    case keycodes::keight:
        maybePush();
        append('8');
        break;
    case keycodes::knine:
        maybePush();
        append('9');
        break;
    case keycodes::kdot:
        maybePush();
        append('.');
        break;
    case keycodes::kexp:
        append('E');
        break;
  }
}

void Calculator::handleUnaryOp(int keyid) {
  double res;
  switch (keyid) {
      case keycodes::kdrop:
          shuffleDown();
          didOp();
          break;
      case keycodes::kback:
          if (!stack[0]->isBlank()) {
            stack[0]->dropLastDigit();
          }
          undidOp();
          break;
      case keycodes::kpercent:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(stack[0]->getValue()/100.0);
          didOp();
          break;
      case keycodes::kround:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(std::floor(stack[0]->getValue() + 0.5));
          didOp();
          break;
      case keycodes::ksqrt:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(std::sqrt(stack[0]->getValue()));
          didOp();
          break;
      case keycodes::klog:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(std::log10(stack[0]->getValue()));
          didOp();
          break;
      case keycodes::kln:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(std::log(stack[0]->getValue()));
          didOp();
          break;
      case keycodes::kneg:
          if (stack[0]->isBlank()) {
              return;
          }
          res = stack[0]->getValue();
          stack[0]->setValue(-res);
          didOp();
          break;
      case keycodes::ktorad:
          if (stack[0]->isBlank()) {
              return;
          }
          res = stack[0]->getValue();
          stack[0]->setValue(torad(res));
          didOp();
          break;
      case keycodes::ktodeg:
          if (stack[0]->isBlank()) {
              return;
          }
          res = stack[0]->getValue();
          stack[0]->setValue(todeg(res));
          didOp();
          break;
      case keycodes::ksquare:
          if (stack[0]->isBlank()) {
              return;
          }
          res = stack[0]->getValue();
          stack[0]->setValue(res * res);
          didOp();
          break;
      case keycodes::kreciprocal:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(1.0 / stack[0]->getValue());
          didOp();
          break;
      case keycodes::kfact:
          if ((stack[0]->isBlank())||(stack[0]->getValue()<1.0)) {
              return;
          }
          res=1.0;
          for(double i = 1.0; i <= stack[0]->getValue(); i++) {
              res *= i;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kabs:
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(std::abs(stack[0]->getValue()));
          break;
      case keycodes::kpower:
          res = std::pow(stack[1]->getValue(), stack[0]->getValue());
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kxsqrty:
          res = std::pow(stack[1]->getValue(), 1.0/stack[0]->getValue());
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::ktenx:
          res = std::pow(10.0, stack[0]->getValue());
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kex:
          res = std::pow(2.718281828459045, stack[0]->getValue());
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kcosh:
          res = std::cosh(stack[0]->getValue());
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::ksinh:
          res = std::sinh(stack[0]->getValue());
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::ktanh:
          res = std::tanh(stack[0]->getValue());
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kcos:
          res = stack[0]->getValue();
          if(angmode==1) {
             res=torad(res);
          }
          res = std::cos(res);
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::ksin:
          res = stack[0]->getValue();
          if(angmode==1) {
             res=torad(res);
          }
          res = std::sin(res);
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::ktan:
          res = stack[0]->getValue();
          if(angmode==1) {
             res=torad(res);
          }
          res = std::tan(res);
          if (stack[0]->isBlank()) {
              return;
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kacos:
          if (stack[0]->isBlank()) {
              return;
          }
          res = std::acos(stack[0]->getValue());
          if(angmode==1) {
             res=todeg(res);
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kasin:
          if (stack[0]->isBlank()) {
              return;
          }
          res = std::asin(stack[0]->getValue());
          if(angmode==1) {
             res=todeg(res);
          }
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::katan:
          if (stack[0]->isBlank()) {
              return;
          }
          res = std::atan(stack[0]->getValue());
          if(angmode==1) {
             res=todeg(res);
          }
          stack[0]->setValue(res);
          didOp();
          break;
  }
}

void Calculator::handleBinaryOp(int keyid) {
  double res;
  switch (keyid) {
      case keycodes::kplus:
          res = stack[0]->getValue() + stack[1]->getValue();
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kminus:
          res = stack[1]->getValue() - stack[0]->getValue();
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::ktimes:
          res = stack[1]->getValue() * stack[0]->getValue();
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kdiv:
          res = stack[1]->getValue() / stack[0]->getValue();
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
      case keycodes::kmod:
          res = std::fmod(stack[1]->getValue(), stack[0]->getValue());
          shuffleDown();
          stack[0]->setValue(res);
          didOp();
          break;
  }
}

void Calculator::handleConstants(int keyid) {
  switch(keyid) {
      case keycodes::ke:
          shuffleUp();
          stack[0]->setValue(2.718281828459045);
          break;
      case keycodes::kpi:
          shuffleUp();
          stack[0]->setValue(3.141592653589793);
          break;
      case keycodes::kangmode:
          break;
  }

}

void Calculator::handleStack(int keyid) {
  double res;
  switch(keyid) {
      case keycodes::kpush:
          if (stack[0]->isBlank()) {
              stack[0]->setText(stack[1]->getText());
          }
          shuffleUp();
          break;
      case keycodes::kswap:
          if (stack[0]->isBlank()) {
              break;
          }
          res = stack[0]->getValue();
          stack[0]->setValue(stack[1]->getValue());
          stack[1]->setValue(res);
          didOp();
          break;
  }
}

void Calculator::buttonPressed(Key key) {
    try {
        handleNumPad(key.id);
        handleUnaryOp(key.id);
        handleBinaryOp(key.id);
        handleConstants(key.id);
        handleStack(key.id);
    } catch(std::exception& e) {
        std::ofstream file;
        file.open("/tmp/rpnerr.txt");
        file<< "Exception" << e.what() << std::endl;
        file.close();
    }
}


double Calculator::torad(double v) {
    return v*M_PI/180.0;
}


double Calculator::todeg(double v) {
    return v*180.0/M_PI;
}


void Calculator::didOp()
{
  prevWasOp = true;
}

void Calculator::undidOp()
{
  prevWasOp = false;
}

void Calculator::maybePush()
{
  if (prevWasOp) {
    shuffleUp();
  }

  prevWasOp = false;
}

void Calculator::setOutputs(std::vector<StackElement*> stack)
{
    this->stack = stack;
    for (auto elem : stack) {
        elem->setText("");
    }
}

void Calculator::append(const char digit) {
    stack[0]->append(digit);
}

void Calculator::shuffleDown() {
    for (auto i = 1; i < stack.size(); i++) {
        stack[i-1]->setText(stack[i]->getText());
    }
    stack[stack.size()-1]->setText("");
}

void Calculator::shuffleUp() {
    if (stack[0]->isBlank()) {
        return;
    }
    for (auto i = stack.size()-1; i > 0; i--) {
        stack[i]->setText(stack[i-1]->getText());
    }
    stack[0]->setText("");
}
