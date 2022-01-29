#include "../build/rmkit.h"
#include "../shared/string.h"
#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
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
  display->text = std::to_string(val);
  display->text.erase(display->text.find_last_not_of('0') + 1, std::string::npos);
  display->padText();
  display->undraw();
  display->mark_redraw();
}

bool StackElement::isBlank() {
  return str_utils::trim_copy(display->text) == "";
}

class CalcButton: public ui::Button {
  public:
    CalcButton(Calculator& c, Key key, int key_width)
      : calculator(c), key(key), Button(0, 0, key_width, 90, key.text) {
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
              {".", kdot}, {"0", kzero}, {"E", kexp}, {"+", kplus}, {"mod", kmod}, {"round", kround}, {"%", kpercent}, {"", kspare}, {"", kspare}, {EOL, keol},
              {"1", kone}, {"2", ktwo}, {"3", kthree}, {"-", kminus}, {"π", kpi}, {"e", ke}, {"√", ksqrt}, {"log", klog}, {"ln", kln}, {EOL, keol},
              {"4", kfour}, {"5", kfive}, {"6", ksix}, {"*", ktimes}, {"x²", ksquare}, {"1/x", kreciprocal}, {"x!", kfact}, {"|x|", kabs}, {"x^y", kpower}, {EOL, keol},
              {"7", kseven}, {"8", keight}, {"9", knine}, {"/", kdiv}, {"push", kpush}, {"swap", kswap}, {"cosh", kcosh}, {"sinh", ksinh}, {"tanh", ktanh}, {EOL, keol},
              {"exit", kexit}, {"", knop}, {"", knop}, {"", knop}, {"drop", kdrop}, {"back", kback}, {"cos", kcos}, {"sin", ksin}, {"tan", ktan}, {EOL, keol},
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
  cout << "Starting main loop" << endl;
  while (true) {
    ui::MainLoop::main();
    ui::MainLoop::redraw();
    ui::MainLoop::read_input();
  }
}
