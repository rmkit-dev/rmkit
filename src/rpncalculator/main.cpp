#include "../build/rmkit.h"
#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include "calc.h"

class CalcDisplay: public ui::Text {
  public:
   CalcDisplay(int width, int height)
    : Text(0, 0, width, height, "") {}
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
        .border_all());
}

void StackElement::setText(const char* text) {
  display->text = text;
  display->undraw();
  display->mark_redraw();
}

const char* StackElement::getText() {
  return display->text.c_str();
}

void StackElement::append(const char digit) {
  if (digit == '.' || digit == 'E') {
    auto pos = display->text.find(digit);
    if (pos != std::string::npos) {
      return;
    }
  }
  display->text += digit;
  display->undraw();
  display->mark_redraw();
}

double StackElement::getValue() {
  return atof(display->text.c_str());
}

void StackElement::setValue(double val) {
  display->text = std::to_string(val);
  display->text.erase(display->text.find_last_not_of('0') + 1, std::string::npos);
  display->undraw();
  display->mark_redraw();
}

bool StackElement::isBlank() {
  return display->text == "";
}

class CalcButton: public ui::Button {
  public:
    CalcButton(Calculator& c, Key key)
      : calculator(c), key(key), Button(0, 0, 150, 90, key.text) {
      this->set_style(ui::Stylesheet()
          .font_size(58)
          .line_height(1.2)
          .underline(false)
          .justify_center()
          .valign_top()
          .border_all());
    }

    virtual void on_mouse_click(input::SynMotionEvent &ev) {
      dirty = 1;
      this->calculator.buttonPressed(this->key);
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
              {".", kdot}, {"0", kzero}, {"E", kexp}, {"+", kplus}, {"mod", kmod}, {"round", kround}, {"%", kpercent}, {"", kspare}, {"", kspare}, {EOL, keol},
              {"1", kone}, {"2", ktwo}, {"3", kthree}, {"-", kminus}, {"π", kpi}, {"e", ke}, {"√", ksqrt}, {"log", klog}, {"ln", kln}, {EOL, keol},
              {"4", kfour}, {"5", kfive}, {"6", ksix}, {"*", ktimes}, {"x²", ksquare}, {"1/x", kreciprocal}, {"x!", kfact}, {"|x|", kabs}, {"x^y", kpower}, {EOL, keol},
              {"7", kseven}, {"8", keight}, {"9", knine}, {"/", kdiv}, {"push", kpush}, {"swap", kswap}, {"cosh", kcosh}, {"sinh", ksinh}, {"tanh", ktanh}, {EOL, keol},
              {"exit", kexit}, {"drop", kdrop}, {"cos", kcos}, {"sin", ksin}, {"tan", ktan}, {EOL, keol}, 
      };

  size_t numberOfElements = sizeof(keyboard)/sizeof(keyboard[0]);
  auto kbd = new ui::HorizontalLayout(0, 0, width, lineHeight, scene);
  v->pack_end(kbd);
  for (int i = 0; i < numberOfElements; i++) {
    auto key = keyboard[i];
    cout << "creating " << key.text << endl;
    if (EOL == key.text) {
      kbd = new ui::HorizontalLayout(0, 0, width, lineHeight, scene);
      v->pack_end(kbd);
    } else {
      kbd->pack_start(new CalcButton(calculator, key), 1);
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
  cout << "Starting main loop" << endl;
  while (true) {
    ui::MainLoop::main();
    ui::MainLoop::redraw();
    ui::MainLoop::read_input();
  }
}