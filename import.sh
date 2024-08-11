#!/bin/bash

# ID souboru, například eaf3f838 (nepovinný)
reMarkable_File_ID="${1:-}"

# Cesta k souborům
reMarkable_Path="/home/root/.local/share/remarkable/xochitl/"

# Funkce pro nalezení složky začínající na reMarkable_File_ID a bez tečky na konci
find_Directory() {
    local search_path="$1"
    local prefix="$2"
    find "$search_path" -maxdepth 1 -type d -name "${prefix}*" ! -name '*.*' -print | head -n 1
}

# Hlavní část skriptu
if [ -z "$reMarkable_File_ID" ]; then
    echo "Error: ID souboru není zadáno."
    exit 1
else
    directory=$(find_Directory "$reMarkable_Path" "$reMarkable_File_ID")
    
    if [ -n "$directory" ]; then
        # Extrakce názvu složky bez cesty
        folder_name=$(basename "$directory")
        echo "$folder_name"
    else
        echo "Error: Složka podle prefixu '$reMarkable_File_ID' nebyla nalezena."
        exit 1
    fi
fi
