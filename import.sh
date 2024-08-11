#!/bin/bash

#    ___      _   _   _                              __  __          _        _    _     
#   / __| ___| |_| |_(_)_ _  __ _ ___  ___   _ _ ___|  \/  |__ _ _ _| |____ _| |__| |___ 
#   \__ \/ -_)  _|  _| | ' \/ _` (_-< |___| | '_/ -_) |\/| / _` | '_| / / _` | '_ \ / -_)
#   |___/\___|\__|\__|_|_||_\__, /__/       |_| \___|_|  |_\__,_|_| |_\_\__,_|_.__/_\___|
#                           |___/                                                        

# Zadaný soubor
specified_file="${1:-}"

# ID souboru, například eaf3f838
reMarkable_File_ID="${2:-}"

# Cesta k souborům
reMarkable_Path="/home/root/.local/share/remarkable/xochitl/"

# Pro stahování souborů v reMarkable.
# reMarkable má staré wget, které nepodporuje STL, toto chybu opraví.
upgrade_WGET() {
    wget_path=/home/root/.local/share/@Wajsar_Josef/wget
    wget_remote=http://toltec-dev.org/thirdparty/bin/wget-v1.21.1-1
    wget_checksum=c258140f059d16d24503c62c1fdf747ca843fe4ba8fcd464a6e6bda8c3bbb6b5

    if [ -f "$wget_path" ] && ! echo "$wget_checksum  $wget_path" | sha256sum -c -; then
        rm "$wget_path"
    fi

    if [ ! -f "$wget_path" ]; then
        echo "Info: Načítání zabezpečeného wget"
        mkdir -p "$(dirname "$wget_path")"
        if ! wget -cq "$wget_remote" --output-document "$wget_path"; then
            echo "Error: Nelze načíst wget, ujistěte se, že máte stabilní připojení Wi-Fi"
            exit 1
        fi
    fi

    if ! echo "$wget_checksum  $wget_path" | sha256sum -c -; then
        echo "Error: Neplatný kontrolní součet pro místní binární soubor wget"
        exit 1
    fi

    chmod 755 "$wget_path"
    WGET="$wget_path"
}

# Funkce pro nalezení složky, která začíná na reMarkable_File_ID a nemá tečku na konci
find_Matching_Directory() {
    local search_path="$1"
    local search_pattern="$2"
    find "$search_path" -maxdepth 1 -type d -name "$search_pattern" ! -name '*.*' ! -name 'xochitl' -print -quit
}

# Hlavní část skriptu
if [ -z "$reMarkable_File_ID" ]; then
    echo "Error: Složka nebyla nalezena."
    exit 1
else
    # Kontrola, zda je soubor zadán a existuje
    if [ -z "$specified_file" ]; then
        echo "Error: Nebyl zadán žádný soubor."
        exit 1
    elif [ ! -f "$specified_file" ]; then
        echo "Error: Soubor '$specified_file' neexistuje."
        exit 1
    fi

    upgrade_WGET

    # Vyhledání složky odpovídající reMarkable_File_ID
    matching_directory=$(find_Matching_Directory "$reMarkable_Path" "${reMarkable_File_ID}*")

    if [ -z "$matching_directory" ]; then
        echo "Error: Složka podle prefixu '$reMarkable_File_ID' nebyla nalezena."
        exit 1
    fi

    # Zkontrolujte, zda cílový adresář existuje a je skutečně adresář
    if [ ! -d "$matching_directory" ]; then
        echo "Error: Cílový adresář '$matching_directory' neexistuje."
        exit 1
    fi

    # Kopírování souboru do nalezené složky
    cp "$specified_file" "$matching_directory/"
    if [ $? -eq 0 ]; then
        echo "Info: Soubor '$specified_file' byl úspěšně zkopírován do '$matching_directory'."
    else
        echo "Error: Kopírování souboru '$specified_file' do '$matching_directory' selhalo."
        exit 1
    fi
fi
