# SnakeTUI Justfile

# Run the game interactively
run *ARGS:
    ./bin/snake-tui {{ARGS}}

# Run the Minitest suite
test:
    ruby test/test_snake_tui.rb

# Preview a single frame (dry-run)
preview:
    ./bin/snake-tui --dryrun

# Preview ASCII fallback mode
preview-ascii:
    ./bin/snake-tui --dryrun --no-emoji
