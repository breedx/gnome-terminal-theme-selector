#!/usr/bin/env bash
set -e

PROFILES_PATH="/org/gnome/terminal/legacy/profiles:/"

# Convert RGB to closest 256-color palette index
rgb_to_256() {
    local r=$1 g=$2 b=$3
    # Use 256-color cube: colors 16-231 are 6x6x6 RGB cube
    local cr=$(( (r * 5 + 127) / 255 ))
    local cg=$(( (g * 5 + 127) / 255 ))
    local cb=$(( (b * 5 + 127) / 255 ))
    echo $(( 16 + 36 * cr + 6 * cg + cb ))
}

# Convert GNOME #RRGGRRGGBBBB to R;G;B (8-bit each)
parse_hex() {
    local hex=${1#"#"}
    printf "%d;%d;%d" $((0x${hex:0:2})) $((0x${hex:4:2})) $((0x${hex:8:2}))
}

# Fast color bar - show bg/fg first, then palette colors
make_palette_bar() {
    local palette="$1" bg="$2" fg="$3" bar=""
    local esc=$'\033'
    
    # Show background first
    if [[ -n "$bg" ]]; then
        local bg_clean=$(echo "$bg" | tr -d "'\"#")
        if [[ ${#bg_clean} -eq 12 ]]; then
            # GNOME format is #RRRRGGGGBBBB - take high bytes (positions 0,4,8)
            local r=$((0x${bg_clean:0:2})) g=$((0x${bg_clean:4:2})) b=$((0x${bg_clean:8:2}))
        else
            # Try 6-character format #RRGGBB
            local r=$((0x${bg_clean:0:2})) g=$((0x${bg_clean:2:2})) b=$((0x${bg_clean:4:2}))
        fi
        local color_idx=$(( (r/51)*36 + (g/51)*6 + (b/51) + 16 ))
        bar+="${esc}[48;5;${color_idx}m  ${esc}[0m"
    fi
    
    # Show foreground second
    if [[ -n "$fg" ]]; then
        local fg_clean=$(echo "$fg" | tr -d "'\"#")
        if [[ ${#fg_clean} -eq 12 ]]; then
            # GNOME format is #RRRRGGGGBBBB - take high bytes (positions 0,4,8)
            local r=$((0x${fg_clean:0:2})) g=$((0x${fg_clean:4:2})) b=$((0x${fg_clean:8:2}))
        else
            # Try 6-character format #RRGGBB
            local r=$((0x${fg_clean:0:2})) g=$((0x${fg_clean:2:2})) b=$((0x${fg_clean:4:2}))
        fi
        local color_idx=$(( (r/51)*36 + (g/51)*6 + (b/51) + 16 ))
        bar+="${esc}[48;5;${color_idx}m  ${esc}[0m"
    fi
    
    # Then show palette colors
    if [[ -n "$palette" ]]; then
        local colors=$(echo "$palette" | grep -o "'#[^']*'" | tr -d "'")
        for color in $colors; do
            if [[ -n "$color" ]]; then
                local hex=${color#"#"}
                if [[ ${#hex} -eq 12 ]]; then
                    # GNOME format is #RRRRGGGGBBBB - take high bytes
                    local r=$((0x${hex:0:2})) g=$((0x${hex:4:2})) b=$((0x${hex:8:2}))
                else
                    # Standard format #RRGGBB
                    local r=$((0x${hex:0:2})) g=$((0x${hex:2:2})) b=$((0x${hex:4:2}))
                fi
                local color_idx=$(( (r/51)*36 + (g/51)*6 + (b/51) + 16 ))
                bar+="${esc}[48;5;${color_idx}m  ${esc}[0m"
            fi
        done
    fi
    echo "$bar"
}

# Read dconf dump - keep it simple and fast
DUMP=$(dconf dump $PROFILES_PATH)

MENU=""
CURRENT_UUID=""
NAME=""
PALETTE=""
BG=""
FG=""

while IFS= read -r line; do
    if [[ $line =~ ^\[([^]]+)\]$ ]]; then
        # Save previous profile entry
        if [[ -n "$CURRENT_UUID" ]]; then
            bar=$(make_palette_bar "$PALETTE" "$BG" "$FG")
            # Pad name to 25 characters for alignment
            printf -v padded_name "%-25s" "$NAME"
            MENU+="$padded_name $bar:::$CURRENT_UUID"$'\n'
        fi
        CURRENT_UUID="${BASH_REMATCH[1]}"
        # Clean up UUID - remove leading colon if present  
        CURRENT_UUID=$(echo "$CURRENT_UUID" | sed 's/^://')
        NAME="(Unnamed)"
        PALETTE=""
        BG=""
        FG=""
    elif [[ $line =~ visible-name=\'(.*)\'$ ]]; then
        NAME="${BASH_REMATCH[1]}"
    elif [[ $line =~ palette=(\[.*\])$ ]]; then
        PALETTE="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^background-color=(.*)$ ]]; then
        BG="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^foreground-color=(.*)$ ]]; then
        FG="${BASH_REMATCH[1]}"
    fi
done <<< "$DUMP"

# Add last profile
if [[ -n "$CURRENT_UUID" ]]; then
    bar=$(make_palette_bar "$PALETTE" "$BG" "$FG")
    # Pad name to 25 characters for alignment
    printf -v padded_name "%-25s" "$NAME"
    MENU+="$padded_name $bar:::$CURRENT_UUID"$'\n'
fi

# Sort by name but keep ANSI intact
MENU_SORTED=$(echo -e "$MENU" | sort -f)

# Display selector with enhanced preview - extract name and colorbar from field 1
SELECTED=$(echo -e "$MENU_SORTED" | fzf --ansi --delimiter=":::" --with-nth=1 --height=40% --reverse --prompt="Select Theme: " --preview='./preview_theme.sh {2} {1}' --preview-window=right:60%)

if [[ -n "$SELECTED" ]]; then
    UUID_SELECTED=$(echo "$SELECTED" | awk -F':::' '{print $2}' | xargs)
    NAME_SELECTED=$(echo "$SELECTED" | awk -F':::' '{print $1}' | sed 's/\x1b\[[0-9;]*m//g' | xargs)
    
    # Change current terminal's profile immediately
    if [[ -n "$GNOME_TERMINAL_SCREEN" ]]; then
        # Get current terminal window ID and change its profile
        dconf write /org/gnome/terminal/legacy/profiles:/:$UUID_SELECTED/use-theme-colors false 2>/dev/null || true
        echo -e "\033]50;SetProfile=$NAME_SELECTED\007"
        echo "🎨 Current terminal theme changed to: $NAME_SELECTED"
    else
        echo "⚠️  Not running in GNOME Terminal, cannot change current theme"
    fi
    
    # Ask if user wants to set as default
    echo
    read -p "Set '$NAME_SELECTED' as default theme for new terminals? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        dconf write ${PROFILES_PATH}default "'$UUID_SELECTED'"
        echo "✅ '$NAME_SELECTED' set as default profile"
    else
        echo "👍 Current terminal theme changed, default unchanged"
    fi
else
    echo "❌ No theme selected."
fi