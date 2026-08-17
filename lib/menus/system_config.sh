#!/usr/bin/env bash
# System configuration menu module (hostname, keyboard, locale, timezone)

menu_select_hostname() {
    local default_hostname="arch"
    local hostname
    
    hostname=$(whiptail --title "Hostname Configuration" \
        --inputbox "Enter hostname for your system:" 10 60 "$default_hostname" \
        3>&2 2>&1 1>&3)
    
    local exit_code=$?
    [[ $exit_code -ne 0 || -z "$hostname" ]] && hostname="$default_hostname"
    echo "$hostname"
}

menu_select_keyboard() {
    local kb_layout
    
    kb_layout=$(whiptail --title "Keyboard Layout" \
        --menu "Select keyboard layout:" 20 70 12 \
        "us" "US English (default)" \
        "es" "Spanish" \
        "pt" "Portuguese" \
        "br" "Brazilian Portuguese" \
        "uk" "UK English" \
        "de" "German" \
        "fr" "French" \
        "it" "Italian" \
        "ru" "Russian" \
        "jp" "Japanese" \
        "latam" "Latin American Spanish" \
        "dvorak" "Dvorak" \
        3>&2 2>&1 1>&3)
    
    local exit_code=$?
    [[ $exit_code -ne 0 || -z "$kb_layout" ]] && kb_layout="us"
    echo "$kb_layout"
}

menu_select_locale() {
    local locale
    
    locale=$(whiptail --title "System Locale" \
        --menu "Select system locale:" 20 70 10 \
        "en_US.UTF-8" "English (US) - default" \
        "es_ES.UTF-8" "Spanish (Spain)" \
        "pt_PT.UTF-8" "Portuguese (Portugal)" \
        "pt_BR.UTF-8" "Portuguese (Brazil)" \
        "en_GB.UTF-8" "English (UK)" \
        "de_DE.UTF-8" "German" \
        "fr_FR.UTF-8" "French" \
        "it_IT.UTF-8" "Italian" \
        "ru_RU.UTF-8" "Russian" \
        "ja_JP.UTF-8" "Japanese" \
        3>&2 2>&1 1>&3)
    
    local exit_code=$?
    [[ $exit_code -ne 0 || -z "$locale" ]] && locale="en_US.UTF-8"
    echo "$locale"
}

menu_select_timezone() {
    local detected_tz="${1:-UTC}"
    local tz_choice
    
    # Ask if user wants to keep detected timezone or change it
    if whiptail --title "Timezone Configuration" \
        --yesno "Detected timezone: $detected_tz\n\nDo you want to keep this timezone?" 10 60 \
        3>&2 2>&1 1>&3; then
        tz_choice="$detected_tz"
    else
        # Show common timezones
        tz_choice=$(whiptail --title "Select Timezone" \
            --menu "Select your timezone:" 22 70 14 \
            "UTC" "UTC (Universal)" \
            "Europe/Lisbon" "Portugal" \
            "Europe/Madrid" "Spain" \
            "Europe/London" "UK" \
            "Europe/Paris" "France/Germany/Italy" \
            "Europe/Berlin" "Germany/Central Europe" \
            "Europe/Moscow" "Russia/Moscow" \
            "America/New_York" "US Eastern" \
            "America/Chicago" "US Central" \
            "America/Denver" "US Mountain" \
            "America/Los_Angeles" "US Pacific" \
            "America/Sao_Paulo" "Brazil" \
            "America/Mexico_City" "Mexico" \
            "Asia/Tokyo" "Japan" \
            3>&2 2>&1 1>&3)
        
        local exit_code=$?
        [[ $exit_code -ne 0 || -z "$tz_choice" ]] && tz_choice="$detected_tz"
    fi
    
    echo "$tz_choice"
}

show_system_config_summary() {
    local hostname="$1"
    local kb_layout="$2"
    local locale="$3"
    local tz_choice="$4"
    
    whiptail --title "System Configuration Summary" --msgbox \
"Configuration set:

Hostname: $hostname
Keyboard: $kb_layout
Locale: $locale
Timezone: $tz_choice

These settings will be applied during installation." 14 60
}
