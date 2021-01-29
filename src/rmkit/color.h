#ifndef RMKIT_COLOR_H
#define RMKIT_COLOR_H

#include <cstdint>
#include <cmath>

// Color defines

#ifdef REMARKABLE
// remarkable uses rgb565_le but is grayscale
  #ifdef USE_GRAYSCALE_8BIT
    #define remarkable_color std::uint8_t
  #else
    #define remarkable_color std::uint16_t
  #endif
#else
  // on linux framebuffer we have 32bit colors
  #define remarkable_color std::uint32_t
#endif

#define WHITE remarkable_color(0x000FFFFF)
#define GRAY remarkable_color(0x4444)
#define BLACK remarkable_color(0)

namespace color {

// -- Color scale and conversions --

// 0(black) - 31(white)
constexpr remarkable_color gray32(int n)
{
    return (n << 11) | (2*n << 5) | n;
}

// 0.0(black) - 1.0(white)
constexpr remarkable_color from_float(float n)
{
    return gray32(31.0 * n);
}

constexpr float to_float(remarkable_color c)
{
    // 0.21 R + 0.72 G + 0.07 B
    return ((c >> 11) & 31) * (0.21 / 31)  // red
         + ((c >> 5)  & 63) * (0.72 / 63)  // green
         + (c         & 31) * (0.07 / 31); // blue
}

// 16-gray palette (BLACK, WHITE, and 14 shades of gray)
// 50% is between GRAY_7 and GRAY_8
static const remarkable_color GRAY_1  = gray32(2);
static const remarkable_color GRAY_2 = gray32(4);
static const remarkable_color GRAY_3 = gray32(6);
static const remarkable_color GRAY_4 = gray32(8);
static const remarkable_color GRAY_5 = gray32(10);
static const remarkable_color GRAY_6 = gray32(12);
static const remarkable_color GRAY_7 = gray32(14);
static const remarkable_color GRAY_8 = gray32(16);
static const remarkable_color GRAY_9 = gray32(18);
static const remarkable_color GRAY_10 = gray32(20);
static const remarkable_color GRAY_11 = gray32(22);
static const remarkable_color GRAY_12 = gray32(24);
static const remarkable_color GRAY_13 = gray32(26);
static const remarkable_color GRAY_14 = gray32(28);

static const remarkable_color SCALE_16[16] = {
    BLACK,   GRAY_1,  GRAY_2, GRAY_3, GRAY_4, GRAY_5, GRAY_6, GRAY_7,
    GRAY_8, GRAY_9, GRAY_10, GRAY_11, GRAY_12, GRAY_13, GRAY_14, WHITE
};

// -- Quantization --

template<int NCOLORS>
remarkable_color quantize(float c) = delete;

template<>
remarkable_color quantize<2>(float c)
{
    return c >= 0.5 ? WHITE : BLACK;
}

template<>
remarkable_color quantize<4>(float c)
{
    return c <  0.25 ? BLACK
         : c >= 0.75 ? WHITE
         : c >= 0.5  ? GRAY_10 : GRAY_5;
}

template<>
remarkable_color quantize<16>(float c)
{
    // Optimize BLACK and WHITE
    return c <   (1/16.0) ? BLACK
         : c >= (15/16.0) ? WHITE
         : SCALE_16[short(std::trunc(c * 15 + 0.5))];
}

} // namespace color

#endif // RMKIT_COLOR_H
