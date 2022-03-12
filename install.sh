#!/usr/bin/env bash

{
    install_echo() {
        command printf %s\\n "$*" 2>/dev/null
    }

    install_error() {
        install_echo "$@" >&2
    }

    install_has_command() {
        type "$1" > /dev/null 2>&1
    }

    install_is_java_8() {
        local grep=""
        if install_has_command "ggrep"; then
            grep="ggrep"
        elif install_has_command "grep"; then
            grep="grep"
        else
            install_error '  ! Error: failed to find grep!'
            exit 1
        fi

        local java_version=$($1 -version 2>&1 | $grep -m 1 -Po '\d+\.\d+\.\d+')
        if [[ -n "$java_version" ]]; then
            if [[ "1.8.0" =~ $java_version ]]; then
                install_echo "  - Found Java v$java_version"
                return 0
            else
                install_echo "  - Found Java v$java_version"
            fi
        else
            install_echo "  ! Error: nothing installed at - \"$1\""
        fi
        return 1
    }

    # TODO: This kinda sucks
    install_download_icon() {
        install_echo "Choose an icon..."
        while true; do
            install_echo "1. ) [128x128] Low-Res Upscaled - Recommended. Same as Low-Res but scaled. (requires imagemagik)"
            install_echo "2. ) [128x128] Steam logo       - The new logo"
            install_echo "3. ) [16x16]   Low-Res logo     - The old logo, super blurry without scaling."
            read -p "Choose logo (1-3): " -n 1 -r
            install_echo ""

            case "$REPLY" in
                "" | 1 )
                    local imagemagick=""
                    if install_has_command "magick"; then
                        imagemagick="magick"
                    elif install_has_command "convert" && ! install_has_command "convert.exe"; then
                        imagemagick="convert"
                    fi

                    if [[ -n "$imagemagick" ]]; then
                        curl --progress-bar -o icon.ico https://aberoth.com/favicon.ico \
                            && command "$imagemagick" icon.ico -scale 800% icon.ico
                        break
                    else
                        install_error "Error: Failed to find imagemagick!"
                    fi
                ;;
                2 )
                    curl --progress-bar -o icon.ico \
                        https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/354200/579294a20da00a2e4b5c703a546f6a6d68604608.ico
                    break
                ;;
                3 ) curl --progress-bar --output icon.ico https://aberoth.com/favicon.ico; break ;;
                * ) install_error "Please choose a number 1-3" ;;
            esac
        done
    }

    install_download_client() {
        install_echo "  - Downloading Aberoth.jar..." \
            && curl -O --progress-bar https://aberoth.com/resource/Aberoth.jar
    }

    install_create_start_script() {
        rm -f start
        install_echo '#!/usr/bin/env bash'   >> start
        install_echo ''                      >> start
        install_echo 'cd "$(dirname "$0")"'  >> start
        install_echo ''                      >> start
        install_echo "$1 -jar Aberoth.jar &" >> start
        chmod +x Aberoth.jar start
    }

    install_create_gnome_menu_shortcut() {
        local install_dir="$PWD"
        local desktop_file="$HOME/.local/share/applications/Aberoth.desktop"

        rm -f "$desktop_file"
        install_echo '[Desktop Entry]'            >> "$desktop_file"
        install_echo 'Type=Application'           >> "$desktop_file"
        install_echo 'Name=Aberoth'               >> "$desktop_file"
        install_echo "Exec=$1 -jar $install_dir/Aberoth.jar" >> "$desktop_file"
        install_echo "Icon=$install_dir/icon.ico" >> "$desktop_file"
        install_echo 'Categories=Game'            >> "$desktop_file"
        install_echo 'Terminal=false'             >> "$desktop_file"
        install_echo 'Comment=Free 8-Bit MMORPG'  >> "$desktop_file"
        chmod +x "$desktop_file"
    }

    install_create_windows_menu_shortcut() {
local vbs_createshortcut="$(cat << EOF
Set oWS = WScript.CreateObject("WScript.Shell")
Set oLink = oWS.CreateShortcut("..\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Aberoth.lnk")
oLink.TargetPath = "%USERPROFILE%\.aberoth\Aberoth.jar"
oLink.IconLocation = "%USERPROFILE%\.aberoth\icon.ico"
oLink.Save
EOF
)"

    install_echo "$vbs_createshortcut" >> "CreateShortcut.vbs" \
        && cscript.exe CreateShortcut.vbs 2>/dev/null \
        || install_error "  ! Error: failed to create menu shortcut!"
    rm -f CreateShortcut.vbs
    }

    install_create_menu_shortcut() {
        local USER="$(whoami)"

        install_echo "  - Creating menu shortcut..."
        if install_has_command "desktop-file-validate"; then
            install_create_gnome_menu_shortcut "$1"
        elif [ -d "/c/Users/$USER/AppData/Roaming/Microsoft/Windows/Start Menu/Programs" ]; then
            install_create_start_script "$1" \
                && install_create_windows_menu_shortcut "$PWD"
        else
            install_error "  ! Error: failed to create menu shortcut!"
        fi
    }

    install_prompt() {
        read -p "$1 (y/n): " -n 1 -r
        install_echo ""

        case "$REPLY" in
            y | Y | "" ) return 0 ;;
            * ) return 1 ;;
        esac
    }

    # Main
    install_dir=~/.aberoth/
    java_8=""

    if [[ -n "$1" ]]; then
        install_dir="$1/.aberoth/"
    fi

    # Prompt to install
    install_prompt "  + Install aberoth to \"$install_dir\"?" \
        && install_echo "  + Searching for Java 8..." \
        || exit 0

    # Search for Java 8
    locations=(java "$JAVA_HOME/bin/java")

    # AdoptOpenJDK locations
    if [[ "$(echo /usr/lib/jvm/adoptopenjdk-*/bin/java)" != "/usr/lib/jvm/adoptopenjdk-*/bin/java" ]]; then
        locations+=($(echo /usr/lib/jvm/adoptopenjdk-*/bin/java))
    fi

    # Ubuntu locations
    if [[ "$(echo /usr/lib/jvm/java-*/bin/java)" != "/usr/lib/jvm/java-*/bin/java" ]]; then
        locations+=($(echo /usr/lib/jvm/java-*/bin/java))
    fi

    # Windows locations
    if [[ "$(echo /c/Program\ Files/jre*/bin/javaw.exe)" != '/c/Program Files/jre*/bin/javaw.exe' ]]; then
        locations+=($(echo /c/Program\ Files/jre*/bin/javaw.exe))
    elif [[ "$(echo /c/Program\ Files/jdk*/bin/javaw.exe)" != '/c/Program Files/jdk*/bin/javaw.exe' ]]; then
        locations+=($(echo /c/Program\ Files/jdk*/bin/javaw.exe))
    fi

    # Loop over locations
    for p in "${locations[@]}"; do
        install_is_java_8 "$p" \
            && install_prompt "  + Use Java 8 located at: \"$p\"?" \
            && java_8="$p" \
            && break
    done

    # Checks
    if [[ -z $java_8 ]]; then
        install_error "Error: failed to find Java 8!"
        exit 1
    fi
    if ! install_has_command "curl"; then
        install_error "Error: failed to find curl!"
        exit 1
    fi

    # Start install
    mkdir -p "$install_dir" && cd "$install_dir" \
        && install_download_client \
        && install_download_icon \
        && install_create_menu_shortcut "$java_8" \
        && install_echo "  - Done!"
}
