#!/usr/bin/env ruby

=begin
SnakeTUI::Game manages the core grid state, snake movement, Vim keybinding
controls (H=left, J=down, K=up, L=right) AND standard arrow keys (←/↓/↑/→),
buffered direction queue (for crisp 1-cell turns), start/restart countdown,
difficulty levels (:easy, :medium, :hard), food spawning, score calculation,
speed scaling, and collision detection.
=end

module SnakeTUI
  class Game
    VECTORS = {
      left:  [0, -1],
      down:  [1,  0],
      up:    [-1, 0],
      right: [0,  1]
    }.freeze

    OPPOSITES = {
      left:  :right,
      right: :left,
      up:    :down,
      down:  :up
    }.freeze

    VIM_KEYS = {
      "h" => :left,
      "j" => :down,
      "k" => :up,
      "l" => :right
    }.freeze

    ARROW_KEYS = {
      "\e[A" => :up,
      "\e[B" => :down,
      "\e[C" => :right,
      "\e[D" => :left,
      "\eOA" => :up,
      "\eOB" => :down,
      "\eOC" => :right,
      "\eOD" => :left
    }.freeze

    DIFFICULTIES = {
      easy:   { base_tick: 0.20,  min_tick: 0.09,  speed_step: 0.002, label: "EASY 🟢" },
      medium: { base_tick: 0.14,  min_tick: 0.05,  speed_step: 0.004, label: "MEDIUM 🟡" },
      hard:   { base_tick: 0.085, min_tick: 0.03,  speed_step: 0.005, label: "HARD 🔴" }
    }.freeze

    DIFFICULTY_KEYS = {
      "1" => :easy,
      "2" => :medium,
      "3" => :hard
    }.freeze

    BASE_TICK_INTERVAL = DIFFICULTIES[:medium][:base_tick]
    MIN_TICK_INTERVAL  = DIFFICULTIES[:medium][:min_tick]
    SPEED_STEP         = DIFFICULTIES[:medium][:speed_step]
    MAX_DIRECTION_QUEUE = 2

    attr_reader :width, :height, :snake, :direction, :direction_queue,
                :food, :score, :high_score, :death_reason, :foods_eaten,
                :difficulty, :countdown

    def initialize(width: 24, height: 18, difficulty: :medium, countdown: 0, rng: Random.new)
      @width = width
      @height = height
      @difficulty = DIFFICULTIES.key?(difficulty) ? difficulty : :medium
      @initial_countdown = countdown.to_i.clamp(0, 5)
      @rng = rng
      @high_score = 0
      @quit_requested = false
      reset!
    end

    def reset!
      mid_y = @height / 2
      mid_x = @width / 2
      @snake = [
        [mid_y, mid_x],
        [mid_y, mid_x - 1],
        [mid_y, mid_x - 2]
      ]
      @direction = :right
      @direction_queue = []
      @score = 0
      @foods_eaten = 0
      @game_over = false
      @death_reason = nil
      @countdown = @initial_countdown
      spawn_food!
    end

    def difficulty=(new_diff)
      @difficulty = new_diff if DIFFICULTIES.key?(new_diff)
    end

    def countdown?
      @countdown > 0
    end

    def decrement_countdown!
      @countdown -= 1 if @countdown > 0
    end

    def game_over?
      @game_over
    end

    def quit_requested?
      @quit_requested
    end

    def tick_interval
      cfg = DIFFICULTIES[@difficulty] || DIFFICULTIES[:medium]
      interval = cfg[:base_tick] - (@foods_eaten * cfg[:speed_step])
      [interval, cfg[:min_tick]].max
    end

    # Returns :turned if a new perpendicular direction was queued on an empty queue,
    # allowing the interactive loop to react immediately without multi-cell lag.
    def handle_key(raw_key)
      return nil if raw_key.nil?

      raw_str = raw_key.to_s
      key = raw_str.downcase
      if key == "q"
        @quit_requested = true
        return :quit
      end

      if DIFFICULTY_KEYS.key?(key)
        @difficulty = DIFFICULTY_KEYS[key]
        return :difficulty
      end

      if key == "r" && @game_over
        reset!
        return :restart
      end

      return nil if @game_over

      desired = ARROW_KEYS[raw_str] || VIM_KEYS[key]
      return nil unless desired

      reference_dir = @direction_queue.last || @direction
      return nil if desired == reference_dir
      return nil if OPPOSITES[reference_dir] == desired
      return nil if @direction_queue.size >= MAX_DIRECTION_QUEUE

      was_empty = @direction_queue.empty?
      @direction_queue << desired
      was_empty ? :turned : :queued
    end

    def tick
      return if @game_over || @quit_requested || countdown?

      @direction = @direction_queue.shift unless @direction_queue.empty?
      dy, dx = VECTORS[@direction]
      head_y, head_x = @snake.first
      new_head = [head_y + dy, head_x + dx]

      if out_of_bounds?(new_head)
        trigger_game_over!(:wall)
        return
      end

      eating = (@food && new_head == @food.position)
      body_to_check = eating ? @snake : @snake[0...-1]

      if body_to_check.include?(new_head)
        trigger_game_over!(:self)
        return
      end

      @snake.unshift(new_head)
      if eating
        @score += @food.points
        @high_score = [@high_score, @score].max
        @foods_eaten += 1
        spawn_food!
      else
        @snake.pop
      end
    end

    def force_food(food_obj)
      @food = food_obj
    end

    def resize!(new_width, new_height)
      @width = new_width.clamp(8, 150)
      @height = new_height.clamp(8, 100)
    end

    private

    def out_of_bounds?(pos)
      y, x = pos
      y < 0 || y >= @height || x < 0 || x >= @width
    end

    def trigger_game_over!(reason)
      @game_over = true
      @death_reason = reason
    end

    def spawn_food!
      available = []
      (0...@height).each do |y|
        (0...@width).each do |x|
          pos = [y, x]
          available << pos unless @snake.include?(pos)
        end
      end

      if available.empty?
        trigger_game_over!(:victory)
        return
      end

      chosen_pos = available[@rng.rand(available.size)]
      @food = Food.from_roll(chosen_pos, @rng.rand)
    end
  end
end
