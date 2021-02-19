#include <stdlib.h>
#include <math.h>
#include <string>
#include <vector>
#include <fstream>
#include "calc.h"

void Calculator::buttonPressed(Key key) {
    double res;
    try {
        switch (key.id) {
            case keycodes::kexit:
                exit(0);
            case keycodes::kzero:
                append('0');
                break;
            case keycodes::kone:
                append('1');
                break;
            case keycodes::ktwo:
                append('2');
                break;
            case keycodes::kthree:
                append('3');
                break;
            case keycodes::kfour:
                append('4');
                break;
            case keycodes::kfive:
                append('5');
                break;
            case keycodes::ksix:
                append('6');
                break;
            case keycodes::kseven:
                append('7');
                break;
            case keycodes::keight:
                append('8');
                break;
            case keycodes::knine:
                append('9');
                break;
            case keycodes::kdot:
                append('.');
                break;
            case keycodes::kexp:
                append('E');
                break;
            case keycodes::kpush:
                if (stack[0]->isBlank()) {
                    break;
                }
                shuffleUp();
                stack[0]->setText("");
                break;
            case keycodes::kswap:
                if (stack[0]->isBlank()) {
                    break;
                }
                res = stack[0]->getValue();
                stack[0]->setValue(stack[1]->getValue());
                stack[1]->setValue(res);
                break;
            case keycodes::kplus:
                res = stack[0]->getValue() + stack[1]->getValue();
                shuffleDown();
                stack[0]->setValue(res);
                break;
            case keycodes::kminus:
                res = stack[1]->getValue() - stack[0]->getValue();
                shuffleDown();
                stack[0]->setValue(res);
                break;
            case keycodes::ktimes:
                res = stack[1]->getValue() * stack[0]->getValue();
                shuffleDown();
                stack[0]->setValue(res);
                break;
            case keycodes::kdiv:
                res = stack[1]->getValue() / stack[0]->getValue();
                shuffleDown();
                stack[0]->setValue(res);
                break;
            case keycodes::kmod:
                res = std::fmod(stack[1]->getValue(), stack[0]->getValue());
                shuffleDown();
                stack[0]->setValue(res);
                break;
            case keycodes::kc:
                if (!stack[0]->isBlank()) {
                    stack[0]->setText("");
                    break;
                }
                shuffleDown();
                break;
            case keycodes::ke:
                shuffleUp();
                stack[0]->setValue(2.718281828459045);
                break;
            case keycodes::kpi:
                shuffleUp();
                stack[0]->setValue(3.141592653589793);
                break;
            case keycodes::kpercent:
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(stack[0]->getValue()/100.0);
                break;
            case keycodes::kround:
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(std::floor(stack[0]->getValue() + 0.5));
                break;
            case keycodes::ksqrt:
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(std::sqrt(stack[0]->getValue()));
                break;
            case keycodes::klog:
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(std::log10(stack[0]->getValue()));
                break;
            case keycodes::kln:
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(std::log(stack[0]->getValue()));
                break;
            case keycodes::ksquare:
                if (stack[0]->isBlank()) {
                    return;
                }
                res = stack[0]->getValue();
                stack[0]->setValue(res * res);
                break;
            case keycodes::kreciprocal:
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(1.0 / stack[0]->getValue());
                break;
            case keycodes::kfact:
                if (stack[0]->isBlank()) {
                    return;
                }
                res = 1.0;
                for(auto i = 1.0; i <= stack[0]->getValue(); ++i) {
                    res *= i;
                }
                stack[0]->setValue(res);
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
                break;
            case keycodes::kcosh:
                res = std::cosh(stack[0]->getValue());
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(res);
                break;
            case keycodes::ksinh:
                res = std::sinh(stack[0]->getValue());
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(res);
                break;
            case keycodes::ktanh:
                res = std::tanh(stack[0]->getValue());
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(res);
                break;
            case keycodes::kcos:
                res = std::cos(stack[0]->getValue());
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(res);
                break;
            case keycodes::ksin:
                res = std::sin(stack[0]->getValue());
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(res);
                break;
            case keycodes::ktan:
                res = std::tan(stack[0]->getValue());
                if (stack[0]->isBlank()) {
                    return;
                }
                stack[0]->setValue(res);
                break;
        }
    } catch(std::exception& e) {
        std::ofstream file;
        file.open("/tmp/err.txt");
        file<< "Exception" << e.what() << std::endl;
        file.close();
    }
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
    stack[0]->setText("");
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