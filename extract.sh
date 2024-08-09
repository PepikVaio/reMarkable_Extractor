#!/bin/bash

# Název složky, která začíná na eaf3f838 (nepovinný)
folder_prefix=""

# Vzdálený server a cesta
server="root@10.0.1.24"
remote_path="/home/root/.local/share/remarkable/xochitl"

if [ -z "$folder_prefix" ]; then
    # Pokud je folder_prefix prázdný, najdi nejnovější složku bez tečky v názvu
    latest_directory=$(ssh "$server" "
        find \"$remote_path\" -maxdepth 1 -type d ! -name '*.*' ! -name 'xochitl' -print | while read dir; do
            echo \"\$(stat -c '%Y' \"\$dir\") \$dir\"
        done | sort -n | tail -1 | awk '{print \$2}'
    ")

    echo "Nalezená složka: $latest_directory"  # Pro ladění

    if [ -n "$latest_directory" ] && [ "$latest_directory" != "$remote_path" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(ssh "$server" "
            find \"$latest_directory\" -type f -print | while read file; do
                echo \"\$(stat -c '%Y' \"\$file\") \$file\"
            done | sort -n | tail -1 | awk '{print \$2}'
        ")

        if [ -n "$latest_file" ]; then
            # Získání názvu souboru bez cesty
            file_name=$(basename "$latest_file")
            echo "Nejnověji upravený soubor!"
            echo "Soubor: $file_name"

            # Stáhnout soubor
            scp "$server:\"$latest_file\"" .
        else
            echo "Ve složce '$latest_directory' nejsou žádné soubory."
        fi
    else
        echo "Složka nebyla nalezena nebo je stejná jako základní cesta."
    fi
else
    # Pokud je folder_prefix neprázdný, vyhledej složku podle prefixu
    latest_file=$(ssh "$server" "
        find \"$remote_path\" -maxdepth 1 -type d -name '${folder_prefix}*' ! -name '*.*' -print | while read dir; do
            find \"\$dir\" -type f -print | while read file; do
                echo \"\$(stat -c '%Y' \"\$file\") \$file\"
            done
        done | sort -n | tail -1 | awk '{print \$2}'
    ")

    if [ -n "$latest_file" ]; then
        # Získání názvu souboru bez cesty
        file_name=$(basename "$latest_file")
        echo "Nejnověji upravený soubor!"
        echo "Soubor: $file_name"

        # Stáhnout soubor
        scp "$server:\"$latest_file\"" .
    else
        echo "Soubor nebyl nalezen."
    fi
fi
