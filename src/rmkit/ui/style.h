#ifndef STYLE_H
#define STYLE_H

#include <functional>
#include <vector>

namespace ui {

struct Style {
    enum JUSTIFY { LEFT, CENTER, RIGHT };
    enum VALIGN { TOP, MIDDLE, BOTTOM };

    // When adding a new style, make sure to also add builders in Stylesheet
    // and Stylesheet::Inherited.
    short font_size = DEFAULT.font_size;
    bool underline = DEFAULT.underline;
    JUSTIFY justify = DEFAULT.justify;
    VALIGN valign = DEFAULT.valign;
    // TODO: border, background, padding

    static Style DEFAULT;
};

// Style builder / updater
// e.g. update myStyle by setting font_size and underline:
// Stylesheet().font_size(50).underline(true).apply(myStyle);
class Stylesheet {
protected:
    typedef std::function<void(Style*)> stylefn;
    std::vector<stylefn> styles;

public:
    // Empty stylesheet
    Stylesheet() { }
    static const Stylesheet DEFAULT;

    // Style updating
    void apply(Style *s) const { for (auto f : styles) f(s); }
    void apply(Style &s) const { apply(&s); }

    // Conversion from Style
    Stylesheet(const Style & style)
    {
        styles.push_back([=](Style *dest) { *dest = style; });
    }

    // Conversion to Style
    Style from(const Style & base) const { Style s = base; apply(&s); return s; }
    Style build() const { return from(Style()); }

    // Merging
    Stylesheet & merge(const Stylesheet & other)
    {
        styles.insert(styles.end(), other.styles.begin(), other.styles.end());
        return *this;
    }
    Stylesheet & operator+=(const Stylesheet & other)
    {
        return merge(other);
    }
    Stylesheet operator+(const Stylesheet & other) { return Stylesheet(*this).merge(other);
    }

    // Style inheritance
    class Inherited;

    // Generic builders
    template<typename T>
    inline Stylesheet & set(T Style::*field, T val)
    {
        styles.push_back([=](Style *s) { s->*field = val; });
        return *this;
    }

    template<typename T, typename V>
    inline Stylesheet & copy(V T::*field, const T & src)
    {
        return set(field, src.*field);
    }

    // Specific builders
    Stylesheet & font_size(short val) { return set(&Style::font_size, val); }
    Stylesheet & font_size(const Style & src) { return copy(&Style::font_size, src); }

    Stylesheet & underline(bool val) { return set(&Style::underline, val); }
    Stylesheet & underline(const Style & src) { return copy(&Style::underline, src); }

    Stylesheet & justify(Style::JUSTIFY val) { return set(&Style::justify, val); }
    Stylesheet & justify(const Style & src) { return copy(&Style::justify, src); }
    Stylesheet & justify_left()   { return justify(Style::JUSTIFY::LEFT); }
    Stylesheet & justify_center() { return justify(Style::JUSTIFY::CENTER); }
    Stylesheet & justify_right()  { return justify(Style::JUSTIFY::RIGHT); }

    Stylesheet & valign(Style::VALIGN val) { return set(&Style::valign, val); }
    Stylesheet & valign(const Style & src) { return copy(&Style::valign, src); }
    Stylesheet & valign_top()    { return valign(Style::VALIGN::TOP); }
    Stylesheet & valign_middle() { return valign(Style::VALIGN::MIDDLE); }
    Stylesheet & valign_bottom() { return valign(Style::VALIGN::BOTTOM); }

    // Shortcuts
    Stylesheet & text_style(const Style & src)
    {
        return font_size(src).justify(src).underline(src);
    }
    Stylesheet & alignment(const Style & src)
    {
        return justify(src).valign(src);
    }
};

// Stylesheet for Styles that should be inherited from another Style
// e.g. copy font_size and underline from one style to another:
// Stylesheet::Inherit(otherStyle).font_size().underline().apply(myStyle)
class Stylesheet::Inherited {
private:
    const Style src;
    Stylesheet sheet;
public:
    Inherited(const Style & src) : src(src) {}
    // Conversion back to Stylesheet
    inline Stylesheet stylesheet() { return sheet; }
    inline const Stylesheet stylesheet() const { return sheet; }
    operator Stylesheet() const { return sheet; }
    operator Stylesheet() { return sheet; }

    inline void apply(Style *s) const { sheet.apply(s); }
    inline void apply(Style &s) const { sheet.apply(&s); }

    // Builders
    Inherited & font_size() { sheet.font_size(src); return *this; }
    Inherited & underline() { sheet.underline(src); return *this; }
    Inherited & justify() { sheet.justify(src); return *this; }
    Inherited & valign() { sheet.justify(src); return *this; }
    Inherited & text_style() { sheet.text_style(src); return *this; }
    Inherited & alignment() { sheet.alignment(src); return *this; }
};

Style Style::DEFAULT = Stylesheet()
    .font_size(24)
    .underline(false)
    .justify_center()
    .valign_top()
    .build();

}

#endif
