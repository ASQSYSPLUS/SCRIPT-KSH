#!/bin/bash

# Bing Daily Wallpaper Script for Linux
# Downloads and sets Bing's daily wallpaper as desktop background

# Configuration
WALLPAPER_DIR="$HOME/Pictures/BingWallpapers"
LOG_FILE="$HOME/.bing_wallpaper.log"
RESOLUTION="1920x1080"  # Change this to your preferred resolution

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to detect desktop environment
detect_de() {
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$DESKTOP_SESSION" = "gnome" ]; then
        echo "gnome"
    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "kde-plasma" ]; then
        echo "kde"
    elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ] || [ "$DESKTOP_SESSION" = "xfce" ]; then
        echo "xfce"
    elif [ "$XDG_CURRENT_DESKTOP" = "MATE" ]; then
        echo "mate"
    elif [ "$XDG_CURRENT_DESKTOP" = "Cinnamon" ]; then
        echo "cinnamon"
    else
        echo "unknown"
    fi
}

# Function to set wallpaper based on desktop environment
set_wallpaper() {
    local wallpaper_path="$1"
    local de=$(detect_de)

    case $de in
        "gnome")
            gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_path"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper_path"
            ;;
        "kde")
            # KDE Plasma 5/6
            qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                var allDesktops = desktops();
                print('Desktops: ' + allDesktops);
                for (i=0;i<allDesktops.length;i++) {
                    d = allDesktops[i];
                    d.wallpaperPlugin = 'org.kde.image';
                    d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
                    d.writeConfig('Image', 'file://$wallpaper_path');
                }
            "
            ;;
        "xfce")
            # XFCE4
            xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$wallpaper_path"
            ;;
        "mate")
            gsettings set org.mate.background picture-filename "$wallpaper_path"
            ;;
        "cinnamon")
            gsettings set org.cinnamon.desktop.background picture-uri "file://$wallpaper_path"
            ;;
        *)
            # Fallback using feh (install with: sudo apt install feh)
            if command -v feh >/dev/null 2>&1; then
                feh --bg-fill "$wallpaper_path"
            else
                log "ERROR: Unknown desktop environment and feh not installed"
                return 1
            fi
            ;;
    esac
}

# Function to download Bing wallpaper
download_bing_wallpaper() {
    log "Starting Bing wallpaper download..."

    # Get Bing wallpaper metadata
    local bing_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
    local metadata

    if ! metadata=$(curl -s "$bing_url"); then
        log "ERROR: Failed to fetch Bing metadata"
        return 1
    fi

    # Extract image URL and title
    local image_url=$(echo "$metadata" | grep -Po '"url":"\K[^"]*' | head -1)
    local title=$(echo "$metadata" | grep -Po '"title":"\K[^"]*' | head -1)
    local copyright=$(echo "$metadata" | grep -Po '"copyright":"\K[^"]*' | head -1)

    if [ -z "$image_url" ]; then
        log "ERROR: Could not extract image URL from Bing response"
        return 1
    fi

    # Construct full image URL
    local full_url="https://www.bing.com${image_url}"

    # Replace resolution in URL if needed
    full_url="${full_url/1366x768/$RESOLUTION}"

    # Generate filename
    local date_str=$(date '+%Y-%m-%d')
    local filename="${date_str}_bing_wallpaper.jpg"
    local filepath="$WALLPAPER_DIR/$filename"

    # Check if wallpaper already exists
    if [ -f "$filepath" ]; then
        log "Wallpaper for today already exists: $filename"
        set_wallpaper "$filepath"
        return 0
    fi

    # Download wallpaper
    log "Downloading: $title"
    log "URL: $full_url"

    if curl -L -o "$filepath" "$full_url"; then
        log "Successfully downloaded: $filename"

        # Create info file
        cat > "$WALLPAPER_DIR/${date_str}_info.txt" << EOF
Title: $title
Copyright: $copyright
URL: $full_url
Downloaded: $(date)
EOF

        # Set as wallpaper
        if set_wallpaper "$filepath"; then
            log "Successfully set wallpaper: $filename"
        else
            log "ERROR: Failed to set wallpaper"
            return 1
        fi

        # Clean up old wallpapers (keep last 30)
        # find "$WALLPAPER_DIR" -name "*_bing_wallpaper.jpg" -type f -mtime +30 -delete
        find "$WALLPAPER_DIR" -name "*_info.txt" -type f -mtime +30 -delete

    else
        log "ERROR: Failed to download wallpaper"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -r, --res      Set resolution (default: 1920x1080)"
    echo "  -d, --dir      Set wallpaper directory (default: ~/Pictures/BingWallpapers)"
    echo "  --setup-cron   Set up automatic daily wallpaper updates"
}

# Function to setup cron job
setup_cron() {
    local script_path=$(realpath "$0")
    local cron_entry="0 9 * * * $script_path >/dev/null 2>&1"

    # Check if cron entry already exists
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        echo "Cron job already exists for this script"
        return 0
    fi

    # Add cron entry
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    echo "Cron job added: Daily wallpaper update at 9:00 AM"
    echo "Current crontab:"
    crontab -l
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -r|--res)
            RESOLUTION="$2"
            shift 2
            ;;
        -d|--dir)
            WALLPAPER_DIR="$2"
            mkdir -p "$WALLPAPER_DIR"
            shift 2
            ;;
        --setup-cron)
            setup_cron
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
log "Bing Wallpaper Script started (Resolution: $RESOLUTION)"
log "Desktop Environment: $(detect_de)"

if download_bing_wallpaper; then
    log "Script completed successfully"
    exit 0
else
    log "Script failed"
    exit 1
fi
