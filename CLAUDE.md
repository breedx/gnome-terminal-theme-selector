# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GNOME Terminal theme selector tool consisting of two bash scripts that provide an interactive interface for previewing and switching terminal color themes.

## Architecture

The project has two main components:

- `select_terminal_profile.sh` - Main script that lists all GNOME Terminal profiles with color previews and allows interactive selection using fzf
- `preview_theme.sh` - Helper script that generates detailed color previews for selected themes in the fzf preview window

### Core Functionality

**select_terminal_profile.sh:**
- Reads GNOME Terminal profiles from dconf (`/org/gnome/terminal/legacy/profiles:/`)
- Parses profile data including names, color palettes, background/foreground colors
- Converts GNOME's 12-character hex format (`#RRRRGGGGBBBB`) to 8-bit RGB for display
- Creates compact color bars showing background, foreground, and palette colors
- Uses fzf for interactive selection with live previews
- Can change current terminal theme immediately and optionally set as default

**preview_theme.sh:**
- Takes profile UUID and name as arguments
- Retrieves color settings from dconf for the specified profile
- Generates a detailed terminal simulation showing typical command output with proper colors
- Handles color conversion from GNOME format to ANSI escape sequences

### Color Handling

Both scripts handle GNOME Terminal's specific color format:
- GNOME uses 12-character hex colors: `#RRRRGGGGBBBB` 
- Scripts extract the high bytes (positions 0, 4, 8) to get 8-bit RGB values
- Fallback to standard 6-character hex format (`#RRGGBB`) when needed
- Color conversion functions map RGB to 256-color palette indices for terminal display

## Usage

### Running the Theme Selector
```bash
./select_terminal_profile.sh
```

This launches an interactive fzf interface where you can:
- Browse available terminal themes with color previews
- See detailed previews in the right panel
- Select a theme to apply to current terminal
- Optionally set the selected theme as default

### Dependencies
- `fzf` - Required for interactive selection interface
- `dconf` - Required to read/write GNOME Terminal settings
- GNOME Terminal - The scripts are designed specifically for GNOME Terminal

### Testing the Scripts
```bash
# Test if the main script can list profiles
./select_terminal_profile.sh

# Test preview functionality manually
./preview_theme.sh [UUID] [THEME_NAME]
```

## Development Notes

- The scripts handle GNOME Terminal's specific dconf structure and color format
- Color conversion functions are optimized for speed since they're called frequently
- The preview system simulates realistic terminal output with proper syntax highlighting colors
- Error handling includes fallbacks for missing color values
- Scripts are designed to work both in active GNOME Terminal sessions and standalone