#ifndef __CALC_H__
#define __CALC_H__

enum keycodes {
    kzero, kone, ktwo, kthree, kfour, kfive, ksix, kseven, keight, knine, 
    kdot, kexp, kplus, kmod, ke, kpercent, kdeg, krad,
    kminus, kpi, kround, ksqrt, klog, kln,
    ktimes, ksquare, kreciprocal, kfact, kabs, kpower,
    kdiv, kpush, kswap, kcosh, ksinh, ktanh,
    kexit, kc, kcos, ksin, ktan, keol
};

typedef struct key {
  const char* text;
  keycodes id;
} Key;

class CalcDisplay;

class StackElement {
  public:
    StackElement(int width, int height);
    CalcDisplay* getLine() { return display; }
    const char* getText();
    void setText(const char* text);
    void append(const char digit);
    double getValue();
    void setValue(double val);
    bool isBlank();

  private:
    std::string content;
    CalcDisplay* display;
};

class Calculator {
  public:
    void buttonPressed(Key key);
    void setOutputs(std::vector<StackElement*> outputs);

  private:
    void append(const char digit);
    void shuffleDown();
    void shuffleUp();

    double history[5];
    std::vector<StackElement*> stack;
};
#endif