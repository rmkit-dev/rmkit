#ifndef STYLE_H
#define STYLE_H

#include <functional>
#include <vector>

namespace ui {

class InheritedStylesheet;

struct Style {
    enum JUSTIFY { LEFT, CENTER, RIGHT };
    enum VALIGN { TOP, MIDDLE, BOTTOM };

    // When adding a new style, make sure to also add builders in Stylesheet
    // and InheritedStylesheet.
    short font_size = DEFAULT.font_size;
    bool underline = DEFAULT.underline;
    JUSTIFY justify = DEFAULT.justify;
    VALIGN valign = DEFAULT.valign;
    bool border_top = DEFAULT.border_top;
    bool border_left = DEFAULT.border_left;
    bool border_bottom = DEFAULT.border_bottom;
    bool border_right = DEFAULT.border_right;
    // TODO: background, padding

    static Style DEFAULT;

    InheritedStylesheet inherit() const;
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

    Stylesheet & underline(bool val=true) { return set(&Style::underline, val); }
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

    Stylesheet & border_top(bool val=true) { return set(&Style::border_top, val); }
    Stylesheet & border_left(bool val=true) { return set(&Style::border_left, val); }
    Stylesheet & border_bottom(bool val=true) { return set(&Style::border_bottom, val); }
    Stylesheet & border_right(bool val=true) { return set(&Style::border_right, val); }
    Stylesheet & border_top(const Style & src) { return copy(&Style::border_top, src); }
    Stylesheet & border_left(const Style & src) { return copy(&Style::border_left, src); }
    Stylesheet & border_bottom(const Style & src) { return copy(&Style::border_bottom, src); }
    Stylesheet & border_right(const Style & src) { return copy(&Style::border_right, src); }

    Stylesheet & border_all(bool val=true) { return border_top(val).border_left(val).border_bottom(val).border_right(val); }
    Stylesheet & border_none() { return border_all(false); }
    Stylesheet & border(const Style & src) { return border_top(src).border_left(src).border_bottom(src).border_right(src); }

    // Shortcuts
    Stylesheet & text_style(const Style & src)
    {
        return font_size(src).underline(src);
    }
    Stylesheet & alignment(const Style & src)
    {
        return justify(src).valign(src);
    }
};

// Stylesheet for Styles that should be inherited from another Style
// e.g. copy font_size and underline from one style to another:
// Stylesheet::Inherit(otherStyle).font_size().underline().apply(myStyle)
class InheritedStylesheet {
private:
    const Style src;
    Stylesheet sheet;
public:
    InheritedStylesheet(const Style & src) : src(src) {}
    // Conversion back to Stylesheet
    inline Stylesheet stylesheet() { return sheet; }
    inline const Stylesheet stylesheet() const { return sheet; }
    operator Stylesheet() const { return sheet; }
    operator Stylesheet() { return sheet; }

    inline void apply(Style *s) const { sheet.apply(s); }
    inline void apply(Style &s) const { sheet.apply(&s); }

    // Builders
    InheritedStylesheet & font_size() { sheet.font_size(src); return *this; }
    InheritedStylesheet & underline() { sheet.underline(src); return *this; }
    InheritedStylesheet & justify() { sheet.justify(src); return *this; }
    InheritedStylesheet & valign() { sheet.justify(src); return *this; }
    InheritedStylesheet & border() { sheet.border(src); return *this; }
    InheritedStylesheet & border_top() { sheet.border_top(src); return *this; }
    InheritedStylesheet & border_left() { sheet.border_left(src); return *this; }
    InheritedStylesheet & border_bottom() { sheet.border_bottom(src); return *this; }
    InheritedStylesheet & border_right() { sheet.border_right(src); return *this; }
    InheritedStylesheet & text_style() { sheet.text_style(src); return *this; }
    InheritedStylesheet & alignment() { sheet.alignment(src); return *this; }
};

InheritedStylesheet Style::inherit() const
{
    return InheritedStylesheet(*this);
}

Style Style::DEFAULT = Stylesheet()
    .font_size(24)
    .underline(false)
    .justify_center()
    .valign_top()
    .border_none()
    .build();

}

#endif
