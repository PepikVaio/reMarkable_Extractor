#!/bin/bash

# Název složky, která začíná na eaf3f838 (nepovinný)
folder_prefix=""

# Vzdálený server a cesta
server="root@10.0.1.24"
remote_path="/home/root/.local/share/remarkable/xochitl/"
password=""

# Funkce pro nalezení nejnovějšího souboru
find_latest_file() {
    local search_path="$1"
    local search_pattern="$2"
    sshpass -p "$password" ssh "$server" "
        find \"$search_path\" -type f -name '$search_pattern' -print | while read file; do
            echo \"\$(stat -c '%Y' \"\$file\") \$file\"
        done | sort -n | tail -1 | awk '{print \$2}'
    "
}

# Funkce pro nalezení nejnovější složky
find_latest_directory() {
    local search_path="$1"
    sshpass -p "$password" ssh "$server" "
        find \"$search_path\" -maxdepth 1 -type d ! -name '*.*' ! -name 'xochitl' -print | while read dir; do
            echo \"\$(stat -c '%Y' \"\$dir\") \$dir\"
        done | sort -n | tail -1 | awk '{print \$2}'
    "
}

# Funkce pro stažení souboru
download_file() {
    local file_path="$1"
    echo "Stahuji soubor: $file_path"
    sshpass -p "$password" scp "$server:\"$file_path\"" .
}

# Hlavní část skriptu
if [ -z "$folder_prefix" ]; then
    # Pokud je folder_prefix prázdný, najdi nejnovější složku bez tečky v názvu
    latest_directory=$(find_latest_directory "$remote_path")

    echo "Nalezená složka: $latest_directory"  # Pro ladění

    if [ -n "$latest_directory" ] && [ "$latest_directory" != "$remote_path" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(find_latest_file "$latest_directory" "*")

        if [ -n "$latest_file" ]; then
            # Získání názvu souboru bez cesty
            file_name=$(basename "$latest_file")
            echo "Nejnověji upravený soubor!"
            echo "Soubor: $file_name"

            # Volání funkce pro stažení souboru
            download_file "$latest_file"
        else
            echo "Ve složce '$latest_directory' nejsou žádné soubory."
        fi
    else
        echo "Složka nebyla nalezena."
    fi
else
    # Pokud je folder_prefix neprázdný, vyhledej složku podle prefixu
    latest_directory=$(find_latest_directory "$remote_path" "${folder_prefix}*")

    if [ -n "$latest_directory" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(find_latest_file "$latest_directory" "*")

        if [ -n "$latest_file" ]; then
            # Získání názvu souboru bez cesty
            file_name=$(basename "$latest_file")
            echo "Nejnověji upravený soubor!"
            echo "Soubor: $file_name"

            # Volání funkce pro stažení souboru
            download_file "$latest_file"
        else
            echo "Ve složce '$latest_directory' nejsou žádné soubory."
        fi
    else
        echo "Složka podle prefixu '$folder_prefix' nebyla nalezena."
    fi
fi
