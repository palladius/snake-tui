#!/usr/bin/env ruby

=begin
SnakeTUI::Game manages the core grid state, snake movement, Vim keybinding
controls (H=left, J=down, K=up, L=right) AND standard arrow keys (←/↓/↑/→),
food spawning, score calculation, speed scaling, and collision detection.
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

    BASE_TICK_INTERVAL = 0.14
    MIN_TICK_INTERVAL  = 0.045
    SPEED_STEP         = 0.004

    attr_reader :width, :height, :snake, :direction, :food, :score, :high_score, :death_reason, :foods_eaten

    def initialize(width: 24, height: 18, rng: Random.new)
      @width = width
      @height = height
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
      @next_direction = :right
      @score = 0
      @foods_eaten = 0
      @game_over = false
      @death_reason = nil
      spawn_food!
    end

    def game_over?
      @game_over
    end

    def quit_requested?
      @quit_requested
    end

    def tick_interval
      interval = BASE_TICK_INTERVAL - (@foods_eaten * SPEED_STEP)
      [interval, MIN_TICK_INTERVAL].max
    end

    def handle_key(raw_key)
      return if raw_key.nil?

      raw_str = raw_key.to_s
      key = raw_str.downcase
      if key == "q"
        @quit_requested = true
        return
      end

      if key == "r" && @game_over
        reset!
        return
      end

      return if @game_over

      desired = ARROW_KEYS[raw_str] || VIM_KEYS[key]
      return unless desired

      # Prevent 180-degree reversal against the committed direction of the current tick
      unless OPPOSITES[@direction] == desired
        @next_direction = desired
      end
    end

    def tick
      return if @game_over || @quit_requested

      @direction = @next_direction
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
