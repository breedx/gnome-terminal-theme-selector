#!/bin/bash

# Preview script for terminal themes
uuid_raw="$1"
name_raw="$2"
# Clean up UUID and name
uuid=$(echo "$uuid_raw" | xargs | sed 's/^://')  # Remove leading colon
name=$(echo "$name_raw" | sed 's/\x1b\[[0-9;]*m//g' | xargs)

# Get colors from the profile  
fg=$(dconf read /org/gnome/terminal/legacy/profiles:/:$uuid/foreground-color 2>/dev/null)
bg=$(dconf read /org/gnome/terminal/legacy/profiles:/:$uuid/background-color 2>/dev/null)
palette=$(dconf read /org/gnome/terminal/legacy/profiles:/:$uuid/palette 2>/dev/null)

# Fallback if colors not found
if [[ -z "$fg" ]]; then
    fg="'#D7D7D7D7DBDB'"  # Light gray
fi
if [[ -z "$bg" ]]; then
    bg="'#2A2A2A2A2E2E'"  # Dark gray
fi
if [[ -z "$palette" ]]; then
    palette="['#2A2A2A2A2E2E', '#B9B98E8EFFFF', '#FFFF7D7DE9E9', '#72729F9FCFCF', '#6666A0A05B5B', '#757550507B7B', '#ACACACACAEAE', '#FFFFFFFFFFFF']"
fi

# Extract palette colors (convert to RGB)
parse_palette_color() {
    local color="$1"
    local clean=$(echo "$color" | tr -d "'\"#")
    if [[ ${#clean} -eq 12 ]]; then
        local r=$((0x${clean:0:2}))
        local g=$((0x${clean:4:2}))
        local b=$((0x${clean:8:2}))
        echo "$r;$g;$b"
    else
        echo "255;255;255"  # fallback
    fi
}

# Get specific palette colors
palette_clean=$(echo "$palette" | tr -d "[]'\"")
IFS=',' read -ra COLORS <<< "$palette_clean"

# Extract common terminal colors (skip leading/trailing spaces)
red_rgb=$(parse_palette_color "$(echo "${COLORS[1]}" | xargs)")      # Red
green_rgb=$(parse_palette_color "$(echo "${COLORS[2]}" | xargs)")    # Green  
yellow_rgb=$(parse_palette_color "$(echo "${COLORS[3]}" | xargs)")   # Yellow
blue_rgb=$(parse_palette_color "$(echo "${COLORS[4]}" | xargs)")     # Blue
magenta_rgb=$(parse_palette_color "$(echo "${COLORS[5]}" | xargs)")  # Magenta
cyan_rgb=$(parse_palette_color "$(echo "${COLORS[6]}" | xargs)")     # Cyan


# Convert hex colors to RGB for preview
fg_clean=$(echo "$fg" | tr -d "'\"#")
bg_clean=$(echo "$bg" | tr -d "'\"#")

# Extract RGB values (GNOME uses #RRRRGGGGBBBB format - take high bytes)
if [[ ${#fg_clean} -eq 12 ]]; then
    fg_r=$((0x${fg_clean:0:2}))
    fg_g=$((0x${fg_clean:4:2}))
    fg_b=$((0x${fg_clean:8:2}))
else
    # Try 6-character format #RRGGBB
    fg_r=$((0x${fg_clean:0:2}))
    fg_g=$((0x${fg_clean:2:2}))
    fg_b=$((0x${fg_clean:4:2}))
fi

if [[ ${#bg_clean} -eq 12 ]]; then
    bg_r=$((0x${bg_clean:0:2}))
    bg_g=$((0x${bg_clean:4:2}))
    bg_b=$((0x${bg_clean:8:2}))
else
    # Try 6-character format #RRGGBB
    bg_r=$((0x${bg_clean:0:2}))
    bg_g=$((0x${bg_clean:2:2}))
    bg_b=$((0x${bg_clean:4:2}))
fi


# Function to calculate visual length (excluding ANSI codes)
visual_length() {
    local text="$1"
    # Remove all ANSI escape sequences and count remaining characters
    echo "$text" | sed 's/\x1b\[[0-9;]*m//g' | wc -c | xargs
}

# Create preview with actual colors
# Apply background and foreground colors to each line
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "+------------------------------------------------+"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
printf "| %-46s |\n" "Theme: $name"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "+------------------------------------------------+"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "|                                                |"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="user@host:~/projects\$ ls --color"
visual_len=$(visual_length "$line_content")
printf "| \033[38;2;%sm\033[48;2;%d;%d;%dmuser@host\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm:\033[38;2;%sm\033[48;2;%d;%d;%dm~/projects\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm\$ ls --color%*s|\n" "$green_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b "$blue_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="drwxr-xr-x  2 user  4096 Dec 25 Documents"
visual_len=$(visual_length "$line_content")
printf "| drwxr-xr-x  2 user  4096 Dec 25 \033[38;2;%sm\033[48;2;%d;%d;%dmDocuments\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm%*s|\n" "$blue_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="-rwxr-xr-x  1 user  1024 Dec 24 script.sh"
visual_len=$(visual_length "$line_content")
printf "| -rwxr-xr-x  1 user  1024 Dec 24 \033[38;2;%sm\033[48;2;%d;%d;%dmscript.sh\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm%*s|\n" "$green_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="-rw-r--r--  1 user   512 Dec 23 readme.txt"
visual_len=$(visual_length "$line_content")
printf "| -rw-r--r--  1 user   512 Dec 23 readme.txt%*s|\n" $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "|                                                |"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="user@host:~/projects\$ git status"
visual_len=$(visual_length "$line_content")
printf "| \033[38;2;%sm\033[48;2;%d;%d;%dmuser@host\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm:\033[38;2;%sm\033[48;2;%d;%d;%dm~/projects\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm\$ git status%*s|\n" "$green_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b "$blue_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="On branch main"
visual_len=$(visual_length "$line_content")
printf "| On branch \033[38;2;%sm\033[48;2;%d;%d;%dmmain\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm%*s|\n" "$cyan_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
line_content="modified: script.sh"
visual_len=$(visual_length "$line_content")
printf "| \033[38;2;%sm\033[48;2;%d;%d;%dmmodified: \033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dmscript.sh\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm%*s|\n" "$red_rgb" $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b $((48-visual_len)) ""
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "|                                                |"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "|                                                |"
printf "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" $fg_r $fg_g $fg_b $bg_r $bg_g $bg_b
echo "+------------------------------------------------+"

# Reset colors
printf "\033[0m"