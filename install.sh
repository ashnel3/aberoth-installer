#!/usr/bin/env bash

{
    install_echo() {
        command printf %s\\n "$*" 2>/dev/null
    }

    install_error() {
        >&2 install_echo "$@"
    }

    install_has_command() {
        type "$1" > /dev/null 2>&1
    }

    install_get_platform() {
        install_echo "linux"
    }

    install_is_java_8() {
        local java_version=$($1 -version 2>&1 | grep -m 1 -Po '\d+\.\d+\.\d+')

        if [[ ! -z $java_version ]]; then
            if [[ "1.8.0" =~ $java_version ]]; then
                install_echo "  - Found Java v$java_version"
                return 0
            else
                install_echo "  - Found Java v$java_version"
            fi
        else
            install_echo "  - Nothing installed at $1"
        fi
        return 1
    }

    # TODO: Find new logo
    install_download_icon() {
        install_echo "Choose an icon..."
        while true; do
            install_echo "1. ) [128x128] Low res scaled - Recommended. Same as low res but scaled. (requires imagemagik)"
            install_echo "2. ) [16x16]   Low res logo   - The OG logo, super blurry without scaling."
            # install_echo "3. ) [128x128] Default logo   - The new logo, meh..."
            read -p "Choose logo (1-3): " -n 1 -r
            install_echo ""

            case "$REPLY" in
                "" | 1 )
                    if install_has_command "convert"; then
                        curl -O --progress-bar https://aberoth.com/favicon.ico
                        convert favicon.ico -scale 800% icon.png
                        rm -f favicon.ico
                        break
                    else
                        install_error "Error: Failed to find imagemagick!"
                        exit 1
                    fi
                ;;
                2 )
                    curl -O --progress-bar https://aberoth.com/favicon.ico
                    mv favicon.ico icon.ico
                    break
                ;;
                # 3 ) curl -O ;;
                * ) install_error "Please choose a number 1-3" ;;
            esac
        done
    }

    install_download_client() {
        install_echo "  - Downloading Aberoth.jar..." \
            && curl -O --progress-bar https://aberoth.com/resource/Aberoth.jar
    }

    install_write_start_script() {
        install_echo '#!/usr/bin/env bash' >> start.sh
        install_echo '' >> start.sh
        install_echo 'cd "$(dirname "$0")"' >> start.sh
        install_echo '' >> start.sh
        install_echo "$1 -jar Aberoth.jar" >> start.sh
        chmod +x Aberoth.jar start.sh
    }

    # TODO: Create start menu shortcut
    install_write_start_shortcut() {
        return 0
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
    installdir=~/.aberoth/
    platform="$(install_get_platform)"
    java_8=""

    if [[ ! -z $1 ]]; then
        installdir="$1/.aberoth"
    fi

    # Prompt to install
    install_prompt "  + Install aberoth to \"$installdir\"?" \
        && install_echo "  + Searching for Java 8..." \
        || exit 0

    # Search for Java 8
    locations=(java "$JAVA_HOME/bin/java")
    if [[ "$(echo /usr/lib/jvm/java-*/bin/java)" != "/usr/lib/jvm/java-*/bin/java" ]]; then
        locations+=("$(echo /usr/lib/jvm/java-*/bin/java)")
    fi

    for p in ${locations[@]}; do
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
    mkdir -p $installdir/aberoth && cd $1aberoth \
        && install_download_client "$installdiraberoth" \
        && install_download_icon "$installdiraberoth" \
        && install_write_start_script "$java_8" \
        && install_write_start_shortcut \
        && install_echo "Done!"
}
