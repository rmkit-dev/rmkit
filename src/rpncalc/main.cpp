#include "../build/rmkit.h"
#include "../shared/string.h"
#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <float.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "calc.h"

class CalcDisplay: public ui::Text {
  public:
   CalcDisplay(int width, int height)
    : Text(0, 0, width, height, "") {}
   void padText() {
    str_utils::trim(this->text);
    this->text += " ";
   }
};

StackElement::StackElement(int width, int height) {
    content = "";
    display = new CalcDisplay(width, height);
    display->set_style(ui::Stylesheet()
        .font_size(64)
        .line_height(1.2)
        .underline(false)
        .justify_right()
        .valign_middle()
        .border_bottom());
}

void StackElement::setText(const char* text) {
  display->text = text;
  display->padText();
  display->undraw();
  display->mark_redraw();
}

const char* StackElement::getText() {
  return display->text.c_str();
}

void StackElement::dropLastDigit() {
  std::string sval = this->display->text;
  int length = sval.length() - 1;

  while (length && sval[length] == ' ') { length--; }

  sval = sval.substr(0, length);
  this->display->text = sval;
  display->padText();
  display->undraw();
  display->mark_redraw();
}

void StackElement::append(const char digit) {
  if (digit == '.' || digit == 'E') {
    auto pos = display->text.find(digit);
    if (pos != std::string::npos) {
      return;
    }
  }
  str_utils::trim(display->text);
  display->text += digit;
  display->padText();
  display->undraw();
  display->mark_redraw();
}

double StackElement::getValue() {
  return atof(display->text.c_str());
}

void StackElement::setValue(double val) {
  char *str;
  asprintf(&str, "%.*G", DBL_DIG, val);
  display->text = str;
  free(str);
  display->padText();
  display->undraw();
  display->mark_redraw();
}

bool StackElement::isBlank() {
  return str_utils::trim_copy(display->text) == "";
}


class CalcButton: public ui::Button {
  public:
    int angmodebtn;
    CalcButton(Calculator& c, Key key, int key_width)
      : calculator(c), key(key), Button(0, 0, key_width, 90, key.text) {
      this->set_style(ui::Stylesheet()
          .font_size(58)
          .line_height(1.2)
          .underline(false)
          .justify_center()
          .valign_top()
          .border_all());
      
      if(strcmp(key.text,"RAD")==0) {
         angmodebtn=1;
      }else{
         angmodebtn=0;
      }
    }

    virtual void on_mouse_click(input::SynMotionEvent &ev) {
      dirty = 1;
      if(!angmodebtn) {
         this->calculator.buttonPressed(this->key);
      }else{
         if(this->calculator.angmode==0) {
            this->calculator.angmode=1;
            text="DEG";
        }else{
            this->calculator.angmode=0;
            text="RAD";
        }
      }
    }

    void render_border() {
      if (key.text != "") {
        ui::Button::render_border();
      }
    }

    void render() {
      if (key.text != "") {
        ui::Button::render();
      }
    }

    private:
      Calculator& calculator;
      Key key;
};

const char* EOL = "EOL";
// Returns a list of calculation lines
std::vector<StackElement*> buildCalculatorLayout(ui::Scene scene, Calculator &calculator, int width, int height) {
  // Consists of a set of rows:
  // +-----------------------------------------+
  // | Calculations                            |  9 rows
  // +-----------------------------------------+
  // | Keyboard                                |  5 rows
  // +-----------------------------------------+
  //
  std::vector<StackElement*> stack;
  double lineHeight = height / 14.0;

  auto v = new ui::VerticalLayout(0, 0, width, height, scene);
  auto calcs = new ui::VerticalLayout(0, 0, width, 2*lineHeight, scene);
  v->pack_start(calcs);
  for (int i = 0; i < 9; i++) {
    stack.push_back(new StackElement(width, lineHeight));
    calcs->pack_start(stack[i]->getLine());
  }
  std::reverse(stack.begin(), stack.end());
  cout << "Stack created" << endl;
  // Keyboard - upsidedown so pack_end works properly
  Key keyboard[] = {
              {"0", kzero}, {".", kdot}, {"π", kpi}, {"+", kplus}, {"", kspare}, {"toDEG", ktodeg}, {"toRAD", ktorad}, {"x!", kfact}, {"RAD", kangmode}, {EOL, keol},
              {"1", kone}, {"2", ktwo}, {"3", kthree}, {"-", kminus}, {"", knop}, {"√x", ksqrt}, {"x√y", kxsqrty}, {"LOG", klog}, {"LN", kln}, {EOL, keol},
              {"4", kfour}, {"5", kfive}, {"6", ksix}, {"×", ktimes}, {"", knop}, {"x²", ksquare}, {"y^x", kpower}, {"10^x", ktenx}, {"e^x", kex}, {EOL, keol},
              {"7", kseven}, {"8", keight}, {"9", knine}, {"÷", kdiv}, {"", knop}, {"1/x", kreciprocal}, {"SIN", ksin}, {"COS", kcos}, {"TAN", ktan}, {EOL, keol},
              {"ENTER", kpush}, {"+/-", kneg}, {"EEX", kexp}, {"<=", kback}, {"DROP", kdrop}, {"SWAP", kswap}, {"ASIN", kasin}, {"ACOS", kacos}, {"ATAN", katan}, {EOL, keol},
      };

  size_t numberOfElements = sizeof(keyboard)/sizeof(keyboard[0]);
  auto kbd = new ui::HorizontalLayout(20, 0, width, lineHeight, scene);
  v->pack_end(kbd);
  int key_width = width / 9.5;
  for (int i = 0; i < numberOfElements; i++) {
    auto key = keyboard[i];
    cout << "creating " << key.text << endl;
    if (EOL == key.text) {
      kbd = new ui::HorizontalLayout(20, 0, width, lineHeight, scene);
      v->pack_end(kbd, -5);
    } else {
      kbd->pack_start(new CalcButton(calculator, key, key_width), 1);
    }
  }
  return stack;
}

int main() {
  // get the framebuffer
  cout << "Starting" << endl;
  auto fb = framebuffer::get();
  auto dims = fb->get_display_size();
  auto width = std::get<0>(dims);
  auto height = std::get<1>(dims);

  // clear the framebuffer using a white rect
  fb->clear_screen();

  // Logic in this class
  Calculator calculator;

  auto scene = ui::make_scene();
  ui::MainLoop::set_scene(scene);
  cout << "Building Layout" << endl;
  auto stack = buildCalculatorLayout(scene, calculator, width, height);
  calculator.setOutputs(stack);
  calculator.angmode=0;
  cout << "Starting main loop" << endl;
  while (true) {
    ui::MainLoop::main();
    ui::MainLoop::redraw();
    ui::MainLoop::read_input();
  }
}
