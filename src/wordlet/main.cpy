#include <algorithm>
#include <stdlib.h>
#include "../build/rmkit.h"

#include "app/keyboard.h"
#include "words/legal.h"
#include "words/candidates.h"

using namespace std

#ifdef DEV
#define SAVE_FILE "wordlet.txt"
#else
#define SAVE_FILE "/opt/etc/wordlet.txt"
#endif

ui::Stylesheet TEXT_STYLE = ui::Stylesheet().justify_center().valign_middle().font_size(90)
ui::Stylesheet LETTER_STYLE = ui::Stylesheet().border_all().justify_center().valign_middle().font_size(90)
ui::Stylesheet BTN_STYLE = ui::Button::DEFAULT_STYLE.valign_middle().border_all().font_size(64)

static void downcase(std::string &s):
  for (int i = 0; i < s.length(); i++):
    s[i] = std::tolower(s[i]);

static void upcase(std::string &s):
  for (int i = 0; i < s.length(); i++):
    s[i] = std::toupper(s[i]);

vector<string> read_words(string words):
  ret := split(words, ' ')
  for auto &w : ret:
    upcase(w)

  return ret

vector<string> LEGAL = read_words(LEGAL_WORDS)
vector<string> CANDIDATES = read_words(CANDIDATE_WORDS)

void prepare_words():
  for string w : CANDIDATES:
    LEGAL.push_back(w)

  std::sort(LEGAL.begin(), LEGAL.end())

bool is_legal(string word):
  upcase(word)
  return std::binary_search(LEGAL.begin(), LEGAL.end(), word)

class Letter: public ui::Widget
  public:
  ui::Text *text
  remarkable_color color = BLANK
  Letter(int x, y, w, h): ui::Widget(x, y, w, h)
    self.text = new Text(x, y, w, h, "")
    self.text->set_style(LETTER_STYLE)
    self.text->set_text("")

  void render():
    self.undraw()
    fb->draw_rect(x, y, w, h, self.color, true)
    if self.color == WRONG_LETTER:
      fb->draw_line(self.x, self.y, self.x+self.w, self.y+self.h, 2, BLACK)
      fb->draw_line(self.x+self.w, self.y, self.x, self.y+self.h, 2, BLACK)

    fb->draw_rect(x, y, w, h, BLACK, false)
    self.text->render()

  void set_text(string v):
    self.text->set_text(v)


class Line: public ui::Widget
  public:
  vector<Letter*> letters
  Line(int x, y, w, h): ui::Widget(x, y, w, h):
    int ox = x
    for i := 0; i < 5; i++:
      letters.push_back(new Letter(ox, y, w/5, h))
      ox += w/5 + 10

  void render():
    for auto l : letters:
      l->render()

  void clear():
    for auto l : letters:
      l->text->set_text("")
      l->color = BLANK


vector<int> mark_correct(string word, string guess):
  vector<int> ans(5, WRONG_LETTER)
  string marked = word
  for i := 0; i < word.length(); i++:
    if toupper(word[i]) == toupper(guess[i]):
      ans[i] = RIGHT_PLACE
      marked[i] = '_'

  for i := 0; i < word.length(); i++:
    idx := marked.find(toupper(guess[i]))
    if idx != -1 and ans[i] == WRONG_LETTER:
      ans[i] = WRONG_PLACE
      marked[idx] = '_'

  return ans



class App:
  public:
  wordle::keyboard::Keyboard *kbd
  ui::Text *feedback_text, *streak_text

  struct %{
    int wins = 0;
    int loss = 0;
    int streak = 0;
  } stats

  vector<Line*> lines
  int line_no = 0
  bool game_over = false
  string to_guess = "WORDS"
  ui::Scene menu_scene, game_scene
  ui::Button *new_game_btn, *infinite_btn
  App():
    srand(time(NULL))
    prepare_words()
    read_stats()

    self.build_scene()

  void build_scene():
    fb := framebuffer::get()
    fb->clear_screen()
    fb->dither = framebuffer::DITHER::BLUE_NOISE_2
    self.build_menu_scene()
    self.build_game_scene()
    ui::MainLoop::set_scene(menu_scene)

  void build_menu_scene():
    fb := framebuffer::get()
    menu_scene = ui::make_scene()
    w, h := fb->get_display_size()

    text := new ui::Text(0, 50, w, 50, "Wordlet")
    text->set_style(ui::Stylesheet().font_size(96))

    h_layout := ui::HorizontalLayout(0, 0, w, h, menu_scene)
    h_layout.pack_center(text)

    menu_container := ui::VerticalLayout(0, 0, 800, 200*5, menu_scene)
    button_height := 200

    random_btn := new ui::Button(w/2-400, 400, 800, button_height, "Random Word")
    *random_btn += BTN_STYLE
    menu_container.pack_start(random_btn)
    random_btn->mouse.click += PLS_LAMBDA(auto ev)
      self.start_new_game()
    ;


    today_btn := new ui::Button(w/2-400, 400, 800, button_height, "Today's Word")
    *today_btn += BTN_STYLE
    menu_container.pack_start(today_btn)
    today_btn->mouse.click += PLS_LAMBDA(auto ev)
      self.start_today_game(0)
    ;
    yesterday_btn := new ui::Button(w/2-400, 400, 800, button_height, "Yesterday's Word")
    *yesterday_btn += BTN_STYLE
    menu_container.pack_start(yesterday_btn)
    yesterday_btn->mouse.click += PLS_LAMBDA(auto ev)
      self.start_today_game(-1)
    ;

    reset_btn := new ui::Button(w/2-400, 400, 800, button_height, "Reset Stats")
    *reset_btn += BTN_STYLE
    menu_container.pack_start(reset_btn)
    reset_btn->mouse.click += PLS_LAMBDA(auto ev)
      self.reset_stats()
    ;

    exit_game_btn := new ui::Button(w/2-400, 400, 800, button_height, "Exit")
    *exit_game_btn += BTN_STYLE
    menu_container.pack_start(exit_game_btn)
    exit_game_btn->mouse.click += PLS_LAMBDA(auto ev)
      exit(0)
    ;


  void build_game_scene():
    fb := framebuffer::get()
    game_scene = ui::make_scene()

    kbd = new wordle::keyboard::Keyboard(game_scene)
    kbd->clear_colors(BLANK)
    kbd->events.done += PLS_LAMBDA(auto kev) {
      self.guess_word(kev.text)


    };

    kbd->events.changed += PLS_LAMBDA(auto kev) {
      if self.game_over:
        return

      self.enter_word(kev.text)

    }
    game_scene->add(kbd)

    w := 600
    h := 100
    oy := 200

    key_group := ui::HorizontalLayout((fb->display_width - w)/2, 50, w, h, game_scene)
    correct_key := new Letter(0, 0, 100, h)
    correct_key->color = RIGHT_PLACE
    incorrect_key := new Letter(0, 0, 100, h)
    incorrect_key->color = WRONG_PLACE
    wrong_key := new Letter(0, 0, 100, h)
    wrong_key->color = WRONG_LETTER
    key_group.pack_start(correct_key)
    key_group.pack_center(incorrect_key)
    key_group.pack_end(wrong_key)

    back_btn := new Button(0, 0, 200, 100, "Menu")
    *back_btn += ui::Stylesheet().justify_center().valign_middle().font_size(64)
    back_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      ui::MainLoop::set_scene(menu_scene)
      ui::MainLoop::refresh()
    ;
    game_scene->add(back_btn)


    w = 800

    for i := 0; i < 6; i++:
      line := new Line((fb->display_width - w - 50)/2, oy, w, h)
      game_scene->add(line)
      lines.push_back(line)
      oy += h + 20


    self.feedback_text = new ui::Text(0, oy+50, fb->display_width, h, "Good Luck!")
    self.feedback_text->set_style(TEXT_STYLE)
    game_scene->add(self.feedback_text)

    oy += h + 100

    streak_text = new ui::MultiText(fb->display_width-200, 25, 200, 150, get_stats())
    streak_text->set_style(TEXT_STYLE.font_size(32))
    game_scene->add(streak_text)

    btn_area := ui::HorizontalLayout((fb->display_width - 900)/2, oy, 900, h, game_scene)

    new_game_btn = new ui::Button(0, 0, 400, h, "New Game")
    *new_game_btn += BTN_STYLE
    new_game_btn->mouse.click += PLS_LAMBDA(auto)
      self.start_new_game()
    ;
    btn_area.pack_start(new_game_btn)

    infinite_btn = new ui::Button(0, 0, 400, h, "Infinite")
    *infinite_btn += BTN_STYLE
    infinite_btn->mouse.click += PLS_LAMBDA(auto)
      self.start_infinite()
    ;
    btn_area.pack_end(infinite_btn)

    self.hide_buttons()

  string get_stats():
    return "Won: " + to_string(stats.wins)  \
      + "\nLost: " + to_string(stats.loss) \
      + "\nStreak: " + to_string(stats.streak);

  void read_stats():
    ifstream f(SAVE_FILE)
    string token
    int value
    while (f >> token)
      if token == "wins":
        f >> value
        stats.wins = value
      if token == "loss":
        f >> value
        stats.loss = value
      if token == "streak":
        f >> value
        stats.streak = value

  void save_stats():
    ofstream f(SAVE_FILE)
    f << "wins " << stats.wins << endl
    f << "loss " << stats.loss << endl
    f << "streak " << stats.streak << endl
    f.close()

  void reset_stats():
    ofstream f(SAVE_FILE)
    f << "wins 0" << endl
    f << "loss 0" << endl
    f << "streak 0" << endl
    f.close()

    read_stats()

  void set_feedback(string text):
    self.feedback_text->undraw()
    self.feedback_text->set_text(text)

  void set_streak(string text):
    self.streak_text->undraw()
    self.streak_text->set_text(text)

  void enter_word(string text):
    line := lines[line_no]
    for i := 0; i < line->letters.size(); i++:
      line->letters[i]->undraw()
      line->letters[i]->set_text("")

    for i := 0; i < text.length(); i++:
      line->letters[i]->set_text(string(1, text[i]))

    set_feedback("")
    line->dirty = 1

  void guess_word(string text):
    if !is_legal(text):
      set_feedback("Unrecognized Word!")
      return

    if text.length() == 5:
      colors := mark_correct(self.to_guess, text)
      line := lines[line_no]

      for i := 0; i < text.length(); i++:
        kbd->mark_color(text[i], colors[i])
        line->letters[i]->color = colors[i]

      line->dirty = 1

      line_no++
      kbd->text = ""
    else:
      set_feedback("Word must be 5 letters")

    if self.to_guess == text:
      self.game_won()
    else if line_no > 5:
      self.game_lost()


  void start_new_game():
    for auto line : lines:
      line->clear()
    line_no = 0
    kbd->clear_colors(BLANK)
    kbd->text = ""

    fb := framebuffer::get()
    fb->clear_screen()
    self.game_over = false

    int idx = rand() % CANDIDATES.size()
    self.to_guess = CANDIDATES[idx]
    set_feedback("Good Luck!")
    upcase(self.to_guess)
    self.hide_buttons()
    set_streak(get_stats())
    save_stats()
    ui::MainLoop::set_scene(game_scene)
    ui::MainLoop::refresh()

  void start_infinite():
    last_word := self.to_guess
    self.start_new_game()
    self.enter_word(last_word)
    self.guess_word(last_word)

  void start_today_game(int offset):
    self.start_new_game()
    day_one := 1624086000
    now := time(NULL)
    secs_in_day := 60 * 60 * 24

    diff := (now - day_one) / secs_in_day + offset
    self.to_guess = CANDIDATES[diff % CANDIDATES.size()]

  void hide_buttons():
    self.new_game_btn->hide()
    self.infinite_btn->hide()

  void show_buttons():
    self.new_game_btn->show()
    self.infinite_btn->show()

  void game_lost():
    self.game_over = true
    stats.streak = 0
    stats.loss++
    set_feedback("You Lost :-[ Word was '" + self.to_guess + "'")
    set_streak(get_stats())
    save_stats()
    self.show_buttons()

  void game_won():
    self.game_over = true
    stats.streak++
    stats.wins++
    set_feedback("You Win!")
    set_streak(get_stats())
    save_stats()
    self.show_buttons()

  def run():
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


def main():
  App app
  app.run()
