#!/usr/bin/env ruby

=begin
SnakeTUI::Food models the colorful Google ball emojis and the super rare purple ball.
Probability distribution per SPEC.md:
- 92% standard Google colors (23% each: 🔵 blue, 🔴 red, 🟡 yellow, 🟢 green) -> 10 points
- 8% super rare purple ball (🟣 purple) -> 50 points
Includes ASCII fallback glyphs for older Raspberry Pi terminals (--no-emoji).
=end

module SnakeTUI
  class Food
    CATALOG = [
      { threshold: 0.23, color: :blue,   emoji: "🔵", ascii: "\e[1;34m●\e[0m ", points: 10 },
      { threshold: 0.46, color: :red,    emoji: "🔴", ascii: "\e[1;31m●\e[0m ", points: 10 },
      { threshold: 0.69, color: :yellow, emoji: "🟡", ascii: "\e[1;33m●\e[0m ", points: 10 },
      { threshold: 0.92, color: :green,  emoji: "🟢", ascii: "\e[1;32m●\e[0m ", points: 10 },
      { threshold: 1.00, color: :purple, emoji: "🟣", ascii: "\e[1;35m★\e[0m ", points: 50 }
    ].freeze

    attr_reader :position, :color, :emoji, :ascii, :points

    def initialize(position:, color:, emoji:, ascii:, points:)
      @position = position
      @color = color
      @emoji = emoji
      @ascii = ascii
      @points = points
    end

    def self.from_roll(position, roll)
      spec = CATALOG.find { |item| roll < item[:threshold] } || CATALOG.last
      new(
        position: position,
        color: spec[:color],
        emoji: spec[:emoji],
        ascii: spec[:ascii],
        points: spec[:points]
      )
    end
  end
end
