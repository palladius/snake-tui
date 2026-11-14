#!/usr/bin/env ruby

=begin
Test suite for SnakeTUI (TUI Vim Snake).
Verifies all acceptance criteria from SPEC.md + arrow key support:
- Vim keybindings (h/j/k/l, case-insensitive) AND standard arrow keys (Up/Down/Left/Right)
- 180-degree reversal prevention
- Food spawning distribution (🔵, 🔴, 🟡, 🟢 23% each = 92%, 🟣 8%) and non-collision with snake body
- Scoring (+10 standard Google ball, +50 rare purple ball) and snake growth
- Dynamic tick speed acceleration as the snake grows
- Wall collision and self-collision -> Game Over
- Restart ('r'/'R') and Quit ('q'/'Q')
- Rendering (emoji and --no-emoji fallback)
=end

require "minitest/autorun"
require_relative "../lib/snake_tui"

class TestSnakeTUI < Minitest::Test
  def setup
    @rng = Random.new(42)
    @game = SnakeTUI::Game.new(width: 20, height: 15, rng: @rng)
  end

  def test_initial_state
    assert_equal 20, @game.width
    assert_equal 15, @game.height
    assert_equal 0, @game.score
    refute @game.game_over?
    assert_equal :right, @game.direction
    assert_equal 3, @game.snake.length
    refute_nil @game.food
    refute_includes @game.snake, @game.food.position
  end

  def test_vim_keybindings_lowercase_and_uppercase
    @game.handle_key("k")
    @game.tick
    assert_equal :up, @game.direction

    @game.handle_key("H")
    @game.tick
    assert_equal :left, @game.direction

    @game.handle_key("j")
    @game.tick
    assert_equal :down, @game.direction

    @game.handle_key("L")
    @game.tick
    assert_equal :right, @game.direction
  end

  def test_arrow_keybindings_csi_and_ss3
    # Starting :right -> Up (\e[A), Left (\e[D), Down (\e[B), Right (\e[C)
    @game.handle_key("\e[A")
    @game.tick
    assert_equal :up, @game.direction

    @game.handle_key("\e[D")
    @game.tick
    assert_equal :left, @game.direction

    @game.handle_key("\e[B")
    @game.tick
    assert_equal :down, @game.direction

    @game.handle_key("\e[C")
    @game.tick
    assert_equal :right, @game.direction

    # Also test SS3 application-mode sequences (\eOA, \eOD, \eOB, \eOC)
    @game.handle_key("\eOA")
    @game.tick
    assert_equal :up, @game.direction

    @game.handle_key("\eOD")
    @game.tick
    assert_equal :left, @game.direction
  end

  def test_prevents_180_degree_reversal
    # Starting :right -> pressing 'h' or Left Arrow (\e[D) must be ignored
    @game.handle_key("h")
    @game.tick
    assert_equal :right, @game.direction

    @game.handle_key("\e[D")
    @game.tick
    assert_equal :right, @game.direction

    # Move :up, then try 'j' or Down Arrow (\e[B) -> ignored
    @game.handle_key("k")
    @game.tick
    assert_equal :up, @game.direction
    @game.handle_key("\e[B")
    @game.tick
    assert_equal :up, @game.direction
  end

  def test_prevents_rapid_double_key_reversal_in_single_tick
    @game.handle_key("k")
    @game.handle_key("h")
    @game.tick
    refute @game.game_over?
    assert_equal :up, @game.direction
  end

  def test_ignores_unrelated_keys
    ["w", "a", "s", "d", "x", " "].each do |invalid_key|
      @game.handle_key(invalid_key)
    end
    assert_equal :right, @game.direction
  end

  def test_food_probability_distribution
    blue = SnakeTUI::Food.from_roll([5, 5], 0.10)
    assert_equal :blue, blue.color
    assert_equal "🔵", blue.emoji
    assert_equal 10, blue.points

    red = SnakeTUI::Food.from_roll([5, 5], 0.30)
    assert_equal :red, red.color
    assert_equal "🔴", red.emoji
    assert_equal 10, red.points

    yellow = SnakeTUI::Food.from_roll([5, 5], 0.55)
    assert_equal :yellow, yellow.color
    assert_equal "🟡", yellow.emoji
    assert_equal 10, yellow.points

    green = SnakeTUI::Food.from_roll([5, 5], 0.80)
    assert_equal :green, green.color
    assert_equal "🟢", green.emoji
    assert_equal 10, green.points

    purple = SnakeTUI::Food.from_roll([5, 5], 0.95)
    assert_equal :purple, purple.color
    assert_equal "🟣", purple.emoji
    assert_equal 50, purple.points
  end

  def test_eating_standard_food_grows_snake_and_adds_10_points
    head_y, head_x = @game.snake.first
    @game.force_food(SnakeTUI::Food.from_roll([head_y, head_x + 1], 0.10))
    initial_len = @game.snake.length

    @game.tick

    assert_equal initial_len + 1, @game.snake.length
    assert_equal 10, @game.score
    assert_equal [head_y, head_x + 1], @game.snake.first
  end

  def test_eating_purple_food_adds_50_points_and_accelerates_speed
    head_y, head_x = @game.snake.first
    initial_interval = @game.tick_interval
    @game.force_food(SnakeTUI::Food.from_roll([head_y, head_x + 1], 0.96))

    @game.tick

    assert_equal 50, @game.score
    assert_operator @game.tick_interval, :<, initial_interval
  end

  def test_wall_collision_triggers_game_over
    until @game.game_over?
      @game.tick
    end
    assert @game.game_over?
    assert_equal :wall, @game.death_reason
  end

  def test_self_collision_triggers_game_over
    5.times do
      hy, hx = @game.snake.first
      @game.force_food(SnakeTUI::Food.from_roll([hy, hx + 1], 0.10))
      @game.tick
    end

    @game.handle_key("j")
    @game.tick
    @game.handle_key("h")
    @game.tick
    @game.handle_key("k")
    @game.tick

    assert @game.game_over?
    assert_equal :self, @game.death_reason
  end

  def test_restart_and_quit_controls
    until @game.game_over?
      @game.tick
    end
    assert @game.game_over?

    @game.handle_key("r")
    refute @game.game_over?
    assert_equal 0, @game.score
    assert_equal 3, @game.snake.length

    @game.handle_key("q")
    assert @game.quit_requested?
  end

  def test_renderer_emoji_and_no_emoji_modes
    renderer_emoji = SnakeTUI::Renderer.new(no_emoji: false)
    frame_emoji = renderer_emoji.render_to_string(@game)
    assert_includes frame_emoji, @game.food.emoji
    assert_includes frame_emoji, "SCORE:"

    renderer_ascii = SnakeTUI::Renderer.new(no_emoji: true)
    frame_ascii = renderer_ascii.render_to_string(@game)
    refute_includes frame_ascii, "🔵"
    assert_includes frame_ascii, "SCORE:"
  end
end
