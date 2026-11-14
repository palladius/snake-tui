# 🐍 TUI Vim Snake (`snake-tui`)

A colorful, nostalgic Nokia-inspired Terminal User Interface (TUI) Snake game written in pure **Ruby** (zero native compilation needed, ideal for headless Linux & Raspberry Pi) built from [`respec`'s `tui-vim-snake` specification](SPEC.md).

## ✨ Features

- **Strict Vim Muscle-Memory Controls:** Move exclusively with `H` (Left), `J` (Down), `K` (Up), `L` (Right) — case-insensitive. Arrow keys and WASD are ignored!
- **Google-Colored Emoji Food:**
  - `🔵` Blue, `🔴` Red, `🟡` Yellow, `🟢` Green (23% each = 92% total) → **+10 points**
  - `🟣` Super Rare Purple ball (8% chance) → **+50 bonus points**
- **Dynamic Acceleration:** Tick speed increases as your snake grows.
- **Raspberry Pi Friendly:** Pure Ruby standard library (`io/console`, `optparse`) + `--no-emoji` ASCII fallback for legacy terminals.

## 🚀 Quick Start

```bash
# Run the game
./bin/snake-tui

# Preview a static board frame (--dryrun)
./bin/snake-tui -n

# Fallback for non-emoji terminals
./bin/snake-tui --no-emoji

# Run the TDD test suite
just test
```
