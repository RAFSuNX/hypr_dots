# NixOS + Hyprland Rice - Wallpaper-Based Material You Theming

> **Dynamic theming system that extracts colors from wallpaper and applies them across all components**

## Features

- **Material You Color Extraction** - Uses `matugen` to extract beautiful color palettes
- **Dynamic Theming** - One wallpaper change themes everything
- **Live Reload** - Changes apply instantly without restart
- **Production Quality** - Clean, well-documented, reusable code

## Components

- **Hyprland** - Wayland compositor with themed borders and UI
- **Waybar** - Status bar with themed modules
- **SwayNC** - Notification center with themed notifications
- **Rofi** - App launcher with themed UI
- **Kitty** - Terminal with themed colors
- **SWWW** - Wallpaper daemon with smooth transitions

## Directory Structure

```
~/claude/rice/
├── README.md              # This file
├── CLAUDE.md              # Rice manager guide (for Claude)
├── hypr/
│   ├── hyprland.conf      # Main Hyprland config
│   ├── theme.conf.template # Generates ~/.config/hypr/theme.conf
│   └── scripts/
│       └── theme-switch.sh # Theme switcher script
├── waybar/
│   ├── config.jsonc       # Waybar modules
│   └── style.template.css # Generates ~/.config/waybar/style.css
├── swaync/
│   ├── config.json        # Notification settings
│   └── style.template.css # Generates ~/.config/swaync/style.css
├── rofi/
│   ├── config.rasi        # Rofi configuration
│   └── theme.template.rasi # Generates ~/.config/rofi/theme.rasi
├── kitty/
│   ├── kitty.conf         # Terminal config
│   └── theme.conf.template # Generates ~/.config/kitty/theme.conf
├── matugen/
│   └── config.toml        # Theme engine config
└── walls/
    └── default.jpg        # Default wallpaper
```

## Usage

Generated files are not tracked in this repo. `matugen` writes them into `~/.config` from the templates stored here.

### Quick Start

```bash
# Apply theme with default wallpaper
~/.config/hypr/scripts/theme-switch.sh

# Apply theme with specific wallpaper
~/.config/hypr/scripts/theme-switch.sh ~/Pictures/wallpaper.jpg

# Apply theme with wallpaper from walls folder
~/.config/hypr/scripts/theme-switch.sh ~/claude/rice/walls/mywall.jpg
```

### Add New Wallpapers

```bash
# Copy wallpaper to walls folder
cp ~/Downloads/cool-wallpaper.jpg ~/claude/rice/walls/

# Apply it
~/.config/hypr/scripts/theme-switch.sh ~/claude/rice/walls/cool-wallpaper.jpg
```

### What Happens When You Run theme-switch.sh

1. **Starts SWWW daemon** (if not running)
2. **Sets wallpaper** with smooth transition
3. **Extracts colors** using matugen Material You algorithm
4. **Generates themed configs** from templates:
   - `~/.config/hypr/theme.conf`
   - `~/.config/waybar/style.css`
   - `~/.config/swaync/style.css`
   - `~/.config/rofi/theme.rasi`
   - `~/.config/kitty/theme.conf`
5. **Reloads applications** to apply new theme
6. **Saves current wallpaper** for next session

## Customization

### Modify Theme Templates

Edit the `.template` files to customize how colors are applied:

- `hypr/theme.conf.template` - Border colors, UI elements
- `waybar/style.template.css` - Status bar styling
- `swaync/style.template.css` - Notification styling
- `rofi/theme.template.rasi` - App launcher styling
- `kitty/theme.conf.template` - Terminal colors

After editing templates, run `theme-switch.sh` to regenerate.

### Change Color Scheme Algorithm

Edit `matugen/config.toml`:

```toml
[config]
type = "scheme-tonal-spot"  # Change to: scheme-vibrant, scheme-neutral, etc.
mode = "dark"               # Change to: light
contrast = 0.0              # Adjust: -1 to 1
```

### Available Template Variables

All templates have access to Material You colors:

```
{{ colors.primary.default.hex }}
{{ colors.on_primary.default.hex }}
{{ colors.primary_container.default.hex }}
{{ colors.on_primary_container.default.hex }}
{{ colors.secondary.default.hex }}
{{ colors.surface.default.hex }}
{{ colors.on_surface.default.hex }}
{{ colors.surface_container.default.hex }}
{{ colors.outline.default.hex }}
{{ colors.error.default.hex }}
... and many more
```

## Keybindings (Hyprland)

Default keybindings from `hyprland.conf`:

- `SUPER + Q` - Open terminal (kitty)
- `SUPER + C` - Close window
- `SUPER + R` - Open app launcher (rofi)
- `SUPER + E` - Open file manager
- `SUPER + 1-9` - Switch workspace
- `SUPER + SHIFT + 1-9` - Move window to workspace

## Troubleshooting

### Theme not applying

```bash
# Check if configs were generated
ls -la ~/.config/hypr/theme.conf
ls -la ~/.config/waybar/style.css

# Make sure files are writable
chmod +w ~/.config/waybar/*
chmod +w ~/.config/swaync/*

# Re-run theme script
~/.config/hypr/scripts/theme-switch.sh
```

### Wallpaper not showing

```bash
# Check if swww daemon is running
pgrep swww-daemon

# Restart swww
killall swww-daemon
swww-daemon &
```

### Colors look wrong

Try different Material You algorithms:

```bash
# Edit matugen config
nano ~/.config/matugen/config.toml

# Change type to: scheme-vibrant, scheme-fidelity, scheme-expressive, etc.
# Then re-run theme-switch.sh
```

## Installation (Fresh System)

1. **Install NixOS packages** (already done in `/etc/nixos/configuration.nix`)

2. **Clone/copy this rice folder**:
   ```bash
   cp -r ~/claude/rice ~/.config/
   ```

3. **Make theme script executable**:
   ```bash
   chmod +x ~/.config/hypr/scripts/theme-switch.sh
   ```

4. **Apply theme**:
   ```bash
   ~/.config/hypr/scripts/theme-switch.sh
   ```

5. **Reload Hyprland** or restart

## Color Scheme Examples

The Material You algorithm generates different palettes based on the wallpaper:

- **scheme-tonal-spot** (default) - Balanced, harmonious colors
- **scheme-vibrant** - More saturated, energetic colors
- **scheme-neutral** - Subtle, low-contrast colors
- **scheme-expressive** - Bold, creative colors
- **scheme-fidelity** - Stays closer to wallpaper's original colors

## Credits

- **matugen** - Color extraction and theming engine
- **Material You** - Color system by Google
- **Hyprland** - Wayland compositor
- **Created with**: Claude Sonnet 4.5

## License

Free to use, modify, and share. Public dotfiles ready!

---

**Last Updated**: 2026-03-25
**Version**: 1.0.0
