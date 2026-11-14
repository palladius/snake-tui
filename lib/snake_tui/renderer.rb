#!/usr/bin/env ruby

=begin
SnakeTUI::Renderer draws the colorful Nokia-inspired Snake TUI frame using ANSI
escape sequences, double-width grid cells (so 🔵🔴🟡🟢🟣 emojis align cleanly
with the `██` snake blocks), and an optional `--no-emoji` mode for legacy terminals.
=end

module SnakeTUI
  class Renderer
    CSI = "\e["
    RESET        = "\e[0m"
    BOLD_GREEN   = "\e[1;32m"
    BRIGHT_GREEN = "\e[38;5;46m"
    BODY_GREEN   = "\e[38;5;40m"
    WALL_COLOR   = "\e[38;5;240m"
    BANNER_COLOR = "\e[1;36m"
    ALERT_COLOR  = "\e[1;31m"
    GOLD_COLOR   = "\e[1;33m"
    PURPLE_COLOR = "\e[1;35m"

    def initialize(no_emoji: false)
      @no_emoji = no_emoji
    end

    def render_to_string(game)
      lines = []
      inner_char_width = game.width * 2

      # Header / Banner
      title = @no_emoji ? "=== TUI VIM SNAKE [ASCII] ===" : "🐍 TUI VIM SNAKE 🔵🔴🟡🟢🟣"
      lines << "#{BANNER_COLOR}#{title}#{RESET}"
      speed_ms = (game.tick_interval * 1000).round
      lines << "#{GOLD_COLOR}SCORE: #{format('%04d', game.score)}#{RESET}  |  HI: #{format('%04d', game.high_score)}  |  LEN: #{game.snake.length}  |  TICK: #{speed_ms}ms"
      lines << "Controls: #{BOLD_GREEN}[H]#{RESET} Left  #{BOLD_GREEN}[J]#{RESET} Down  #{BOLD_GREEN}[K]#{RESET} Up  #{BOLD_GREEN}[L]#{RESET} Right  |  #{BOLD_GREEN}[Q]#{RESET} Quit"

      # Top Wall
      lines << "#{WALL_COLOR}╔#{'═' * inner_char_width}╗#{RESET}"

      snake_set = {}
      game.snake.each_with_index { |pos, idx| snake_set[pos] ||= idx }
      food_pos = game.food&.position

      (0...game.height).each do |y|
        row = +"#{WALL_COLOR}║#{RESET}"
        (0...game.width).each do |x|
          pos = [y, x]
          if (idx = snake_set[pos])
            if idx == 0
              row << "#{BRIGHT_GREEN}██#{RESET}"
            else
              row << "#{BODY_GREEN}▓▓#{RESET}"
            end
          elsif food_pos == pos
            row << (@no_emoji ? game.food.ascii : game.food.emoji)
          else
            row << "  "
          end
        end
        row << "#{WALL_COLOR}║#{RESET}"
        lines << row
      end

      # Bottom Wall
      lines << "#{WALL_COLOR}╚#{'═' * inner_char_width}╝#{RESET}"

      if game.game_over?
        bump = @no_emoji ? "!!" : "💥"
        reason_str = case game.death_reason
                     when :wall then "CRASHED INTO THE WALL!"
                     when :self then "BIT YOUR OWN TAIL!"
                     when :victory then "BOARD CLEARED — YOU WIN!"
                     else "GAME OVER!"
                     end
        lines << "#{ALERT_COLOR}#{bump} #{reason_str} Final Score: #{game.score} — Press [R] to Restart or [Q] to Quit#{RESET}"
      elsif @no_emoji
        lines << "#{PURPLE_COLOR}Tip:#{RESET} Google balls (●) = +10 pts | Rare Purple (★) = +50 pts"
      else
        lines << "#{PURPLE_COLOR}Tip:#{RESET} Google balls 🔵🔴🟡🟢 = +10 pts | Rare Purple 🟣 = +50 pts"
      end

      lines.map { |line| "#{line}\e[K" }.join("\r\n")
    end
  end
end
