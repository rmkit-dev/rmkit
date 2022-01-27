#include <algorithm>
#include <deque>
#include "../build/rmkit.h"
#include "help.h"
#include "assets.h"

using namespace std

// TODO:
// test on devices
int FS = 64
ui::Stylesheet BTN_STYLE = ui::Button::DEFAULT_STYLE.valign_middle().border_all().font_size(FS)
ui::Stylesheet TEXT_STYLE = ui::Stylesheet().justify_center().valign_middle().font_size(FS)

int MAX_HP = 21

MODE_SCOUNDREL := false
MODE_DONSOL := true

enum GAME_MODE { DONSOL, SCOUNDREL }

static string downcase(std::string &s):
  for (int i = 0; i < s.length(); i++):
    s[i] = std::tolower(s[i]);

  return s


class Card: public ui::Widget:
  public:
  bool active = true
  int value = 0
  int game_mode
  ui::Text *upper_left, *bottom_right
  ui::Text *action

  Card(int x, y, w, h): ui::Widget(x, y, w, h)
    debug "NEW CARD", x, y, w, h
    upper_left = new ui::Text(x, y, w, h, "")
    *upper_left += ui::Stylesheet().justify_left().font_size(FS).valign_top()
    bottom_right = new ui::Text(x, y, w, h, "")
    *bottom_right += ui::Stylesheet().justify_right().font_size(FS).valign_bottom()

    action = new ui::Text(x, y, w, h, "Act")
    *action += ui::Stylesheet().justify_center().font_size(FS).valign_middle()
    self.mouse.down += PLS_LAMBDA(auto):
      debug "ACT DOWN"
    ;
    self.mouse.up += PLS_LAMBDA(auto):
      debug "ACT UP"
    ;

  char get_suit():
    suit := "CDHSS"[value / 13]
    return suit

  int get_value():
    if value >= 52:
      return 14

    return value % 13 + 1

  int get_damage():
    val := get_value()
    switch val:
      case 12:
        return 13
      case 13:
        return 15
      case 1:
        return 17
      case 14:
        return 21
      default:
        return val

  int get_health():
    val := get_value()
    if val > 11 or val == 1:
      return 11

    return val

  int get_shield():
    val := get_value()
    if val > 11 or val == 1:
      return 11

    return val

  string get_monster():
    vector<string> monsters = %{
      "Elemental",
      "Goblin",
      "Kobold",
      "Hound",
      "Gnoll",
      "Warg",
      "Orc",
      "Centaur",
      "Golem",
      "Ogre",
      "Troll",
      "Cyclops",
      "Deep Elf",
      "Dragon"
    }

    return monsters[get_value() - 1]



  void before_render():
    upper_left->x = x+20
    upper_left->y = y
    upper_left->w = w
    upper_left->h = h

    bottom_right->x = x
    bottom_right->y = y
    bottom_right->w = w-20
    bottom_right->h = h

    action->x = x
    action->y = y+100
    action->w = w
    action->h = h


  void render():
    self.undraw()
    if active:
      render_active()
    else:
      render_used()

  void render_used():
    fb->draw_line(x, y, x+w, y+h, 1, BLACK)
    fb->draw_line(x+w, y, x, y+h, 1, BLACK)
    fb->draw_rect(x, y, w, h, BLACK, false)

  void render_pixmap(icons::Icon icon):
    ui::Pixmap pixmap(self.x+(self.w-128)/2, self.y+self.h/2-128, 128, 128, icon)
    pixmap.render()

  void render_active():
    string text
    suit := get_suit()
    switch suit:
      case 'H':
        action->set_text("Drink Potion")
        text = to_string(get_health())
        render_pixmap(ICON(assets::fa_flask_solid_png))
        break
      case 'D':
        if game_mode == GAME_MODE::DONSOL:
          action->set_text("Equip Shield")
          text = to_string(get_shield())
          render_pixmap(ICON(assets::fa_shield_alt_solid_png))
        if game_mode == GAME_MODE::SCOUNDREL::
          action->set_text("Equip Sword")
          text = to_string(get_shield())
          render_pixmap(ICON(assets::fa_sword_png))
        break
      case 'C':
      case 'S':
        action->set_text("Fight " + get_monster())
        text = to_string(get_damage())
        if get_monster() == "Dragon":
          render_pixmap(ICON(assets::fa_d_and_d_brands_png))
        else:
          render_pixmap(ICON(assets::fa_skull_solid_png))
        break


    fb->draw_rect(x, y, w, h, BLACK, false)
    upper_left->set_text(text)
    bottom_right->set_text(text)

    upper_left->render()
    bottom_right->render()
    action->render()

class App:
  public:
  ui::Scene menu_scene, game_scene, help_scene, win_scene, prev_scene
  ui::MultiText *feedback_text
  deque<int> deck
  vector<Card*> cards

  ui::Text *hp_box, *xp_box, *sp_box, *diff_box
  ui::MultiText *help_text
  ui::Text *score_text
  ui::Button *run_box, *replay_box

  string get_game_mode(int d):
    switch d:
      case GAME_MODE::DONSOL:
        return "Donsol"
      case GAME_MODE::SCOUNDREL:
        return "Scoundrel"
      default:
        return "???"


  struct %{
    int health = 11; /* health remaining */
    int last_potion = 0; /* last drank potion */
    int experience = 0; /* number of cards used */
    int shield = 0; /* value of shield */
    int shield_monster = 0; /* last monster fought with shield */
    int drank_potion = false; /* drank a potion */
    int escaped = false; /* escaped last room */
    int game_over = 0; /* game ended */
    int game_mode = GAME_MODE::DONSOL; /* sconsol */
  } state;

  App():
    srand(time(NULL))
    self.build_scene()

  void build_scene():
    fb := framebuffer::get()
    fb->clear_screen()
    fb->dither = framebuffer::DITHER::BLUE_NOISE_2
    self.build_menu_scene()
    self.build_game_scene()
    self.build_help_scene()
    self.build_win_scene()
    ui::MainLoop::set_scene(menu_scene)

  void build_menu_scene():
    fb := framebuffer::get()
    menu_scene = ui::make_scene()
    w, h := fb->get_display_size()

    text := new ui::Text(0, 50, w, 50, "Dumbskull")
    text->set_style(ui::Stylesheet().font_size(96))

    h_layout := ui::HorizontalLayout(0, 0, w, h, menu_scene)
    h_layout.pack_center(text)

    menu_container := ui::VerticalLayout(0, 0, 800, 200*5, menu_scene)
    button_height := 200

    for int game_mode : vector<int>{GAME_MODE::DONSOL, GAME_MODE::SCOUNDREL}:
      game_btn := new ui::Button(w/2-400, 400, 800, button_height, get_game_mode(game_mode))
      *game_btn += BTN_STYLE
      menu_container.pack_start(game_btn)
      int d = game_mode
      game_btn->mouse.click += PLS_LAMBDA(auto ev)
        self.start_new_game(d)
      ;

    help_btn := new ui::Button(w/2-400, 400, 800, button_height, "Help")
    *help_btn += BTN_STYLE
    menu_container.pack_start(help_btn)
    help_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      prev_scene = menu_scene
      ui::MainLoop::set_scene(help_scene)
      ui::MainLoop::refresh()
    ;
    exit_game_btn := new ui::Button(w/2-400, 400, 800, button_height, "Exit")
    *exit_game_btn += BTN_STYLE
    menu_container.pack_start(exit_game_btn)
    exit_game_btn->mouse.click += PLS_LAMBDA(auto ev)
      exit(0)
    ;

  void build_win_scene():
    fb := framebuffer::get()
    w, h := fb->get_display_size()
    win_scene = ui::make_scene()
    win_text := new ui::Text(0, 550, w, h, "You escape the dungeon!")
    fs := 64
    *win_text += ui::Stylesheet().font_size(fs).justify_center()
    win_scene->add(win_text)

    trophy := new ui::Pixmap(0, 0, 200, 200, ICON(assets::fa_trophy_solid_png))
    horizontal_area := ui::HorizontalLayout(0, 300, w, 200, win_scene)
    horizontal_area.pack_center(trophy)

    button_height := 200
    game_btn := new ui::Button((w-800)/2, 800, 800, button_height, "Play Again")
    *game_btn += BTN_STYLE.justify_center().valign_middle()
    game_btn->mouse.click += PLS_LAMBDA(auto ev)
      self.start_new_game(state.game_mode)
      ui::MainLoop::set_scene(game_scene)
      ui::MainLoop::refresh()
    ;
    win_scene->add(game_btn)

    menu_btn := new ui::Button((w-800)/2, 1000, 800, button_height, "Main Menu")
    *menu_btn += BTN_STYLE.justify_center().valign_middle()
    menu_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      ui::MainLoop::set_scene(menu_scene)
      ui::MainLoop::refresh()
    ;
    win_scene->add(menu_btn)

    score_text = new ui::Text((w - 400)/2, 600, 400, 100, "Score: 50")
    *score_text += TEXT_STYLE
    win_scene->add(score_text)



  void build_help_scene():
    // TODO: build help scene instead of a modal
    fb := framebuffer::get()
    help_scene = ui::make_scene()
    help_text = new ui::MultiText(50, 100, fb->width - 100, fb->height - 100, ABOUT_SCOUNDREL)

    fs := 40
    *help_text += ui::Stylesheet().font_size(fs)
    tw, th := help_text->get_render_size()
    if th > (fb->height - 100):
      scale := (fb->height - 100) / float(th)
      fs = int(scale * fs)

    *help_text += ui::Stylesheet().font_size(fs)
    help_scene->add(help_text)

    top_bar := ui::HorizontalLayout(0, 0, fb->display_width, 50, help_scene)

    back_btn := new ui::Button(0, 0, 200, 50, "Back")
    *back_btn += ui::Stylesheet().justify_center().valign_middle().font_size(48)
    back_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      ui::MainLoop::set_scene(prev_scene)
      ui::MainLoop::refresh()
    ;
    donsol_btn := new ui::Button(0, 0, 300, 50, "Donsol Help")
    *donsol_btn += ui::Stylesheet().justify_center().valign_middle().font_size(48)
    donsol_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      help_text->set_text(ABOUT_DONSOL)
      ui::MainLoop::refresh()
    ;
    scoundrel_btn := new ui::Button(0, 0, 300, 50, "Scoundrel Help")
    *scoundrel_btn += ui::Stylesheet().justify_center().valign_middle().font_size(48)
    scoundrel_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      help_text->set_text(ABOUT_SCOUNDREL)
      ui::MainLoop::refresh()
    ;

    top_bar.pack_start(back_btn)
    top_bar.pack_end(scoundrel_btn, 50)
    top_bar.pack_end(donsol_btn, 50)

  void build_game_scene():
    fb := framebuffer::get()
    game_scene = ui::make_scene()

    top_bar := ui::HorizontalLayout(0, 0, fb->display_width, 50, game_scene)

    back_btn := new ui::Button(0, 0, 200, 50, "Menu")
    *back_btn += ui::Stylesheet().justify_center().valign_middle().font_size(48)
    back_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      ui::MainLoop::set_scene(menu_scene)
      ui::MainLoop::refresh()
    ;
    top_bar.pack_start(back_btn)

    diff_box = new ui::Text(0, 0, 200, 50, "")
    *diff_box += ui::Stylesheet().justify_center().valign_middle().font_size(48)
    top_bar.pack_center(diff_box)

    help_btn := new ui::Button(0, 0, 200, 50, "Help")
    *help_btn += ui::Stylesheet().justify_center().valign_middle().font_size(48)
    top_bar.pack_end(help_btn)
    help_btn->mouse.click += PLS_LAMBDA(auto ev)
      fb->clear_screen()
      prev_scene = game_scene
      if state.game_mode == GAME_MODE::SCOUNDREL:
        help_text->set_text(ABOUT_SCOUNDREL)
      else if state.game_mode == GAME_MODE::DONSOL:
        help_text->set_text(ABOUT_DONSOL)
      ui::MainLoop::set_scene(help_scene)
      ui::MainLoop::refresh()
    ;

    w, h := fb->get_display_size()
    w -= 100
    hp_box = new ui::Text(0, 0, w/5, 100, "11 HP")
    *hp_box += TEXT_STYLE
    sp_box = new ui::Text(0, 0, w/5, 100, "0 SH 13")
    *sp_box += TEXT_STYLE
    xp_box = new ui::Text(0, 0, w/5, 100, "0 XP")
    *xp_box += TEXT_STYLE
    run_box = new ui::Button(0, 0, w/5, 100, "Flee")
    *run_box += BTN_STYLE
    run_box->mouse.click += PLS_LAMBDA(auto):
      self.escape()
    ;

    button_area := ui::HorizontalLayout(50, 75, w, 200, game_scene)
    button_area.pack_start(hp_box)
    button_area.pack_start(sp_box)
    button_area.pack_start(xp_box)
    button_area.pack_end(run_box)


    oy := 200
    card_area := ui::HorizontalLayout(50, oy, w, h/3, game_scene)

    for i := 0; i < 4; i++:
      if i == 2:
        oy += h/3 + 50
        card_area = ui::HorizontalLayout(50, oy, w, h/3, game_scene)

      card := new Card(0, 0, w/2-50, h/3)
      card->mouse.click += PLS_LAMBDA(auto):
        self.use_card(card)
      ;
      cards.push_back(card)
      if i % 2 == 0:
        card_area.pack_start(card)
      else:
        card_area.pack_end(card)

      debug "CARD POSITIONED", card->x, card->y, card->w, card->h

    replay_bar := ui::HorizontalLayout(0, (h-200)/2, fb->display_width, 200, game_scene)
    replay_box = new ui::Button(0, 0, 800, 200, "Restart")
    *replay_box += BTN_STYLE
    replay_box->mouse.click += PLS_LAMBDA(auto):
      self.start_new_game(state.game_mode)
    ;
    replay_box->hide()
    replay_bar.pack_center(replay_box)


    oy += h/3 + 50
    self.feedback_text = new ui::MultiText(50, oy, fb->display_width - 50,
      fb->height - oy, "Good Luck!")
    self.feedback_text->set_style(TEXT_STYLE)
    game_scene->add(feedback_text)

  void reset_deck():
    deck.clear()
    for i := 0; i < 54; i++:
      deck.push_back(i)
    random_shuffle(deck.begin(), deck.end())

  bool can_flee():
    if state.experience > 0 && state.escaped:
      return false

    return true

  void escape():
    if state.game_over:
      return

    if !can_flee():
      return

    set_feedback("You flee")

    for i := 0; i < cards.size(); i++:
      if cards[i]->active:
        deck.push_front(cards[i]->value)
    deal_cards()

    if state.experience > 0:
      state.escaped = true
    update_status()

  void save_active():
    for auto card : cards:
      if card->active:
        deck.push_back(card->value)

  void deal_cards():
    if state.game_over:
      return

    for i := 0; i < cards.size(); i++:
      if deck.size():
        value := deck.back(); deck.pop_back()
        cards[i]->value = value
        cards[i]->active = true
      else:
        cards[i]->active = false

      cards[i]->dirty = 1
      cards[i]->game_mode = state.game_mode

    state.escaped = false
    state.drank_potion = false

  void use_card(Card *card):
    if state.game_over or !card->active:
      return

    debug "CLICKED CARD", card->get_suit(), card->get_value()
    card->active = false
    card->dirty = 1
    state.experience++
    state.last_potion = 0

    switch card->get_suit():
      case 'H':
        state.last_potion = card->get_health()
        if !state.drank_potion:
          state.health += card->get_health()
          if state.health > MAX_HP:
            state.health = MAX_HP
          set_feedback("You heal " + to_string(card->get_health()) + " health")
        else:
          set_feedback("The health potion had no effect")

        state.drank_potion = true
        break
      case 'D':
        state.shield = card->get_shield()
        state.shield_monster = 0
        if state.game_mode == GAME_MODE::DONSOL:
          set_feedback("You equipped the shield (" + to_string(card->get_shield()) + ")")
        if state.game_mode == GAME_MODE::SCOUNDREL:
          set_feedback("You equipped the sword (" + to_string(card->get_shield()) + ")")
        if state.game_mode == GAME_MODE::DONSOL:
          state.drank_potion = false
        break
      case 'C':
      case 'S':
        damage := card->get_damage()
        broke_shield := false
        if state.game_mode == GAME_MODE::DONSOL:
          state.drank_potion = false

        if state.shield:
          if state.game_mode == GAME_MODE::DONSOL:
            if state.shield_monster and card->get_damage() >= state.shield_monster:
              broke_shield = true
              state.shield = 0
              state.shield_monster = 0
            else:
              damage -= state.shield
              state.shield_monster = card->get_damage()
          if state.game_mode == GAME_MODE::SCOUNDREL:
            if state.shield_monster and card->get_damage() >= state.shield_monster:
              pass
            else:
              damage -= state.shield
              state.shield_monster = card->get_damage()

        damage = max(damage, 0)
        if damage > 0:
          state.health -= damage

        string text
        if broke_shield:
          text = "Your shield breaks! "

        if state.health > 0:
          text += ("You defeat the " + card->get_monster() +
            " and took " + to_string(damage) + " damage")
          set_feedback(text)
        else:
          text += ("The " + card->get_monster() + " kills you :-[")
          set_feedback(text)

        break

    check_game_over()
    if state.game_mode == GAME_MODE::SCOUNDREL:
      if count_active() <= 1:
        save_active()
        self.deal_cards()

    if state.game_mode == GAME_MODE::DONSOL:
      if count_active() == 0:
        self.deal_cards()

    update_status()

  bool has_monster():
    for auto card : cards:
      suit := card->get_suit()
      if !card->active:
        continue

      if suit == 'C' or suit == 'S':
        return true
    return false

  int count_active():
    cnt := 0
    for auto card : cards:
      if card->active:
        cnt++
    return cnt

  void check_game_over():
    if state.health <= 0:
      self.game_lost()
      replay_box->show()
      replay_box->mark_redraw()
    else if deck.size() == 0 and !count_active():
      self.game_won()

  void game_lost():
    state.game_over = true
  void game_won():
    state.game_over = true
    score := to_string(state.health)
    if state.health == MAX_HP:
      score = to_string(state.health + state.last_potion)
    score_text->set_text("Score: " + score)

    framebuffer::get()->clear_screen()
    ui::MainLoop::set_scene(win_scene)
    ui::MainLoop::refresh()

  void reset_status():
    state.health = 11
    state.shield = 0
    state.shield_monster = 0
    state.experience = 0
    state.last_potion = 0
    state.health = 11; /* health remaining */
    state.experience = 0; /* number of cards used */
    state.shield = 0; /* value of shield */
    state.shield_monster = 0; /* last monster fought with shield */
    state.drank_potion = false; /* drank a potion */
    state.escaped = false; /* escaped last room */
    state.game_over = 0; /* game ended */

  void update_status():
    hp_box->undraw()
    sp_box->undraw()
    xp_box->undraw()
    diff_box->undraw()
    run_box->undraw()

    diff_box->set_text(get_game_mode(state.game_mode))

    hp_box->set_text(to_string(state.health) + "HP")
    shield_suffix := state.game_mode == GAME_MODE::SCOUNDREL ? "SW" : "SH"
    sp_box->set_text(to_string(state.shield) + shield_suffix)
    if state.shield_monster:
      sp_box->text += " " + to_string(state.shield_monster)

    xp_box->set_text(to_string(state.experience) + "XP")
    if can_flee():
      run_box->show()
    else:
      run_box->hide()
      run_box->undraw()
    run_box->dirty = 1


  void start_new_game(int game_mode):
    fb := framebuffer::get()
    fb->clear_screen()
    ui::MainLoop::set_scene(game_scene)
    state.game_mode = game_mode
    reset_deck()
    reset_status()
    deal_cards()
    update_status()
    replay_box->hide()
    ui::MainLoop::refresh()

    set_feedback("Welcome to the dungeon... of FUN!")


  void set_feedback(string text):
    debug "SETTING TEXT", text
    self.feedback_text->undraw()
    self.feedback_text->set_text(text)
    debug feedback_text->x, feedback_text->y, feedback_text->w, feedback_text->h


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
