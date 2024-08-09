#!/bin/bash

# Vzdálený reMarkable_Server
reMarkable_Path="/home/root/.local/share/remarkable/xochitl/"
reMarkable_Server="root@10.0.1.24"
reMarkable_Password=""

# ID souboru, která začíná na eaf3f838 (nepovinný)
reMarkable_File_ID=""

# Funkce pro nalezení nejnovějšího souboru
find_Latest_File() {
    local search_path="$1"
    local search_pattern="$2"
    sshpass -p "$reMarkable_Password" ssh "$reMarkable_Server" "
        find \"$search_path\" -type f -name '$search_pattern' -print | while read file; do
            echo \"\$(stat -c '%Y' \"\$file\") \$file\"
        done | sort -n | tail -1 | awk '{print \$2}'
    "
}

# Funkce pro nalezení nejnovější složky
find_Latest_Directory() {
    local search_path="$1"
    sshpass -p "$reMarkable_Password" ssh "$reMarkable_Server" "
        find \"$search_path\" -maxdepth 1 -type d ! -name '*.*' ! -name 'xochitl' -print | while read dir; do
            echo \"\$(stat -c '%Y' \"\$dir\") \$dir\"
        done | sort -n | tail -1 | awk '{print \$2}'
    "
}

# Funkce pro stažení souboru
download_File() {
    local file_path="$1"
    echo "Stahuji soubor: $file_path"
    sshpass -p "$reMarkable_Password" scp "$reMarkable_Server:\"$file_path\"" .
}

# Hlavní část skriptu
if [ -z "$reMarkable_File_ID" ]; then
    # Pokud je reMarkable_File_ID prázdný, najdi nejnovější složku bez tečky v názvu
    latest_directory=$(find_Latest_Directory "$reMarkable_Path")

    echo "Nalezená složka: $latest_directory"  # Pro ladění

    if [ -n "$latest_directory" ] && [ "$latest_directory" != "$reMarkable_Path" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(find_Latest_File "$latest_directory" "*")

        if [ -n "$latest_file" ]; then
            # Získání názvu souboru bez cesty
            file_name=$(basename "$latest_file")
            echo "Nejnověji upravený soubor!"
            echo "Soubor: $file_name"

            # Volání funkce pro stažení souboru
            download_File "$latest_file"
        else
            echo "Ve složce '$latest_directory' nejsou žádné soubory."
        fi
    else
        echo "Složka nebyla nalezena."
    fi
else
    # Pokud je reMarkable_File_ID neprázdný, vyhledej složku podle prefixu
    latest_directory=$(find_Latest_Directory "$reMarkable_Path" "${reMarkable_File_ID}*")

    if [ -n "$latest_directory" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(find_Latest_File "$latest_directory" "*")

        if [ -n "$latest_file" ]; then
            # Získání názvu souboru bez cesty
            file_name=$(basename "$latest_file")
            echo "Nejnověji upravený soubor!"
            echo "Soubor: $file_name"

            # Volání funkce pro stažení souboru
            download_File "$latest_file"
        else
            echo "Ve složce '$latest_directory' nejsou žádné soubory."
        fi
    else
        echo "Složka podle prefixu '$reMarkable_File_ID' nebyla nalezena."
    fi
fi
