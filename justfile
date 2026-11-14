# SnakeTUI Justfile

# Default recipe: play the game!
default: play

# Play TUI Vim Snake interactively
play *ARGS:
    ./bin/snake-tui {{ARGS}}

# Alias for play
run *ARGS:
    ./bin/snake-tui {{ARGS}}

# Launch the Web Pseudo-Terminal Bridge (Static Ruby WASM + Native PTY WebSocket)
web PORT="4567":
    ./bin/snake-tui-web {{PORT}}

# Run the Minitest suite
test:
    ruby test/test_snake_tui.rb

# Preview a single frame (dry-run)
preview:
    ./bin/snake-tui --dryrun

# Preview ASCII fallback mode
preview-ascii:
    ./bin/snake-tui --dryrun --no-emoji
