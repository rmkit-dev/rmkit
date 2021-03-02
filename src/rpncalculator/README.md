# RPN Calculator

This is a calculator app for the Remarkable tablet. It uses a Reverse Polish Notation style rather than the more conventional infix notation. This document will explain how to use RPN with this app.

In the examples below, the key to press is shown with square brackets around it, e.g. to enter a 1 into the calculator, the example would show [1].

## Using the calculator

Numbers are entered in the usual way with the numeric keypad. The 'E' key is used to enter numbers in scientific notation. E.g. 2E6 is an alternative representaion for 2,000,000.

The calculator uses a stack to hold operands and arithmetic operations work on the top two elements of the stack.  For example a simple addition '1 + 2' is performed on the calculator using these keys:

```
[1] [push] [2] [+]
```

Examples of more complex calculations:

```
120/(4 + 9)  -> [1][2][0] [push] [4] [push] [9] [+] [/]

2πr²         -> [2] [push] [π] [push] (numerical value of r) [x²] [*] [*]
```

The last example uses two of the function buttons, these replace the top of the stack with the result of applying the function.

## RPN Specific Buttons

[push] - moves the stack up one and leaves the top blank for another number to be entered. If a number scrolls off the screen, it is removed from the stack.

[swap] - exchange the top two elements on the stack

[drop] - remove the top element from the stack

## Functions

[%] - Divides the top of stack by 100

[mod] - Calculates the modulus

[e] - pushes Euler's constant onto the stack (2.71828)

[π] - pushes pi onto the stack (3.14159)

[round] - Rounds the top of stack to the nearest integer

[√] - Square root of the top of stack

[log] - Calculates the log base 10

[ln] - Calculates the natural log

[x²] - Calculates the square

[1/x] - Calculates the reciprocal

[x!] - Calculates the factorial

[|x|] - Calculates the absolute value

[x^y] - Calcualtes second on stack to the power of top of stack

[cos(h)] - Calculates the (hyperbolc) cosine

[sin(h)] - Calculates the (hyperbolc) sine

[tan(h)] - Calculates the (hyperbolc) tangent

## TODO

1. Add a 'pick' function so tapping a number on the stack moves it to the top
2. Use the two blank buttons to add mor functionality. Suggestions welcome
3. Tidy up the interface a bit - it sometimes leaves dark areas on the screen after a button has been pressed.
4. More testing to heck robustness.