#!/usr/bin/env ruby

=begin
SnakeTUI main module loader.
Loads Food, Game, and Renderer classes for the TUI Vim Snake game.
=end

require_relative "snake_tui/food"
require_relative "snake_tui/game"
require_relative "snake_tui/renderer"

module SnakeTUI
  VERSION = "0.2.0"
end
