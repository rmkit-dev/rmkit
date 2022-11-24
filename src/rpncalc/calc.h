#ifndef __CALC_H__
#define __CALC_H__

enum keycodes {
    kzero, kone, ktwo, kthree, kfour, kfive, ksix, kseven, keight, knine, 
    kdot, kexp, kplus, kmod, ke, kpercent,
    kminus, kpi, kround, ksqrt, klog, kln,
    ktimes, ksquare, kreciprocal, kfact, kabs, kpower,
    kdiv, kpush, kswap, kcosh, ksinh, ktanh, 
    kacos, kasin, katan, kxsqrty, kex, kangmode, ktorad, ktodeg, ktenx,
    kexit, kdrop, kcos, ksin, ktan, kspare, keol, knop, kback, kneg
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
    void dropLastDigit();
    bool isBlank();

  private:
    std::string content;
    CalcDisplay* display;
};

class Calculator {
  public:
    void buttonPressed(Key key);
    void setOutputs(std::vector<StackElement*> outputs);
    int angmode;

  private:
    void append(const char digit);
    void shuffleDown();
    void shuffleUp();
    void maybePush();
    void didOp();
    void undidOp();

    void handleNumPad(int);
    void handleUnaryOp(int);
    void handleBinaryOp(int);
    void handleConstants(int);
    void handleStack(int);
    
    double torad(double);
    double todeg(double);

    bool prevWasOp;
    std::vector<StackElement*> stack;
};
#endif
