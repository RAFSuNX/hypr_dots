#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Installing hypr_dots from: $DOTS_DIR"

# Create target directories
mkdir -p "$CONFIG_DIR/hypr/scripts"
mkdir -p "$CONFIG_DIR/waybar/scripts"
mkdir -p "$CONFIG_DIR/kitty"
mkdir -p "$CONFIG_DIR/rofi"
mkdir -p "$CONFIG_DIR/swaync"
mkdir -p "$CONFIG_DIR/matugen"
mkdir -p "$CONFIG_DIR/walls"
mkdir -p "$CONFIG_DIR/gtk-3.0"
mkdir -p "$CONFIG_DIR/gtk-4.0"
mkdir -p "$HOME/Pictures/Screenshots"

# hypr
cp "$DOTS_DIR/hypr/hyprland.lua"             "$CONFIG_DIR/hypr/hyprland.lua"
cp "$DOTS_DIR/hypr/theme.lua"                "$CONFIG_DIR/hypr/theme.lua"
cp "$DOTS_DIR/hypr/theme.lua.template"       "$CONFIG_DIR/hypr/theme.lua.template"
cp "$DOTS_DIR/hypr/hyprlock.conf"            "$CONFIG_DIR/hypr/hyprlock.conf"
cp "$DOTS_DIR/hypr/hyprlock.conf.template"   "$CONFIG_DIR/hypr/hyprlock.conf.template"
cp "$DOTS_DIR/hypr/scripts/theme-switch.sh"    "$CONFIG_DIR/hypr/scripts/theme-switch.sh"
cp "$DOTS_DIR/hypr/scripts/switch-workspace.sh" "$CONFIG_DIR/hypr/scripts/switch-workspace.sh"

# waybar
cp "$DOTS_DIR/waybar/config.jsonc"                   "$CONFIG_DIR/waybar/config.jsonc"
cp "$DOTS_DIR/waybar/style.css"                      "$CONFIG_DIR/waybar/style.css"
cp "$DOTS_DIR/waybar/style.template.css"             "$CONFIG_DIR/waybar/style.template.css"
cp "$DOTS_DIR/waybar/scripts/cpu-status.sh"          "$CONFIG_DIR/waybar/scripts/cpu-status.sh"
cp "$DOTS_DIR/waybar/scripts/gpu-status.sh"          "$CONFIG_DIR/waybar/scripts/gpu-status.sh"
cp "$DOTS_DIR/waybar/scripts/netspeed.sh"            "$CONFIG_DIR/waybar/scripts/netspeed.sh"
cp "$DOTS_DIR/waybar/scripts/audio-manager.sh"       "$CONFIG_DIR/waybar/scripts/audio-manager.sh"
cp "$DOTS_DIR/waybar/scripts/network-manager.sh"     "$CONFIG_DIR/waybar/scripts/network-manager.sh"
cp "$DOTS_DIR/waybar/scripts/power-manager.sh"       "$CONFIG_DIR/waybar/scripts/power-manager.sh"

# kitty
cp "$DOTS_DIR/kitty/kitty.conf"              "$CONFIG_DIR/kitty/kitty.conf"
cp "$DOTS_DIR/kitty/theme.conf"              "$CONFIG_DIR/kitty/theme.conf"
cp "$DOTS_DIR/kitty/theme.conf.template"     "$CONFIG_DIR/kitty/theme.conf.template"

# rofi
cp "$DOTS_DIR/rofi/config.rasi"              "$CONFIG_DIR/rofi/config.rasi"
cp "$DOTS_DIR/rofi/theme.rasi"               "$CONFIG_DIR/rofi/theme.rasi"
cp "$DOTS_DIR/rofi/theme.template.rasi"      "$CONFIG_DIR/rofi/theme.template.rasi"

# swaync
cp "$DOTS_DIR/swaync/config.json"            "$CONFIG_DIR/swaync/config.json"
cp "$DOTS_DIR/swaync/style.css"              "$CONFIG_DIR/swaync/style.css"
cp "$DOTS_DIR/swaync/style.template.css"     "$CONFIG_DIR/swaync/style.template.css"

# matugen
cp "$DOTS_DIR/matugen/config.toml"           "$CONFIG_DIR/matugen/config.toml"

# walls
cp "$DOTS_DIR/walls/"*                       "$CONFIG_DIR/walls/"

# gtk
cp "$DOTS_DIR/gtk/gtk-3.0/settings.ini"     "$CONFIG_DIR/gtk-3.0/settings.ini"
cp "$DOTS_DIR/gtk/gtk-4.0/settings.ini"     "$CONFIG_DIR/gtk-4.0/settings.ini"

# make scripts executable
chmod +x "$CONFIG_DIR/hypr/scripts/theme-switch.sh"
chmod +x "$CONFIG_DIR/hypr/scripts/switch-workspace.sh"
chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh

# Chrome dark mode
printf -- '--force-dark-mode\n--enable-features=WebUIDarkMode\n' > "$HOME/.config/chrome-flags.conf"

echo ""
echo "Done. Run theme-switch.sh to apply theming:"
echo "  ~/.config/hypr/scripts/theme-switch.sh"
