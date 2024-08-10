#!/bin/bash

# | Popis!
# | Tento skript se připojuje k serveru reMarkable přes SSH.
# 
# * Vyhledává nejnovější soubory a složky na základě zadaných kritérií.
# * Stahuje je do lokálního adresáře.
# * Skript využívá nástroj scp pro stahování souborů.

# | Použití!
# | Skript lze spustit s parametry: [ID souboru (nepovinné)]

# Po stažení scriptu na lokální disk
# * ./extract.sh [ID souboru (nepovinné)]
# Bez stažení na lokální disk
# * bash -c "$(wget https://raw.githubusercontent.com/pepikvaio/reMarkable_Extractor/main/extract.sh -O-)" -- [ID souboru (nepovinné)]

# | Konfigurace!
# | Najdete v nastavení reMarkable.

# * reMarkable_File_ID: ID souboru (nepovinné)
# * reMarkable_Path: Cesta k adresáři na reMarkable
# *******************************************************************************************************************************************************************************************************

reMarkable_File_ID="${1:-}"  # Pokud první parametr není zadán, použije prázdný řetězec

# Spojení proměnné IP adresy do příkazu ssh
reMarkable_Server="remarkable"

# Cesta k souborům
reMarkable_Path="/home/remarkable/.local/share/remarkable/xochitl/"

# Funkce pro nalezení nejnovějšího souboru
find_Latest_File() {
    local search_path="$1"
    local search_pattern="$2"
    ssh "$reMarkable_Server" "
        find \"$search_path\" -type f -name '$search_pattern' -print | while read file; do
            echo \"\$(stat -c '%Y' \"\$file\") \$file\"
        done | sort -n | tail -1 | awk '{print \$2}'
    "
}

# Funkce pro nalezení nejnovější složky bez tečky na konci
find_Latest_Directory() {
    local search_path="$1"
    local search_pattern="$2"
    ssh "$reMarkable_Server" "
        find \"$search_path\" -maxdepth 1 -type d -name '$search_pattern' ! -name '*.*' ! -name 'xochitl' -print | while read dir; do
            echo \"\$(stat -c '%Y' \"\$dir\") \$dir\"
        done | sort -n | tail -1 | awk '{print \$2}'
    "
}

# Funkce pro stažení souboru
download_File() {
    
    upgrade_WGET
    
    local file_path="$1"
    echo "Stahuji soubor: $file_path"
    scp "$reMarkable_Server:\"$file_path\"" .
}

# Funkce pro zpracování nalezeného souboru
process_Latest_File() {
    local latest_file="$1"
    local latest_directory="$2"

    if [ -n "$latest_file" ]; then
        # Získání názvu souboru bez cesty
        file_name=$(basename "$latest_file")
        echo "Nejnověji upravený soubor: $file_name"

        # Volání funkce pro stažení souboru
        download_File "$latest_file"
    else
        echo "Ve složce '$latest_directory' nejsou žádné soubory."
    fi
}

# Pro stahování souborů v reMarkable.
# reMarkable má staré wget, které nepodporuje STL, toto chybu opraví.
upgrade_WGET () {
    wget_path=/home/root/.local/share/@Wajsar_Josef/wget
    wget_remote=http://toltec-dev.org/thirdparty/bin/wget-v1.21.1-1
    wget_checksum=c258140f059d16d24503c62c1fdf747ca843fe4ba8fcd464a6e6bda8c3bbb6b5

    if [ -f "$wget_path" ] && ! sha256sum -c <(echo "$wget_checksum  $wget_path") > /dev/null 2>&1; then
        rm "$wget_path"
    fi

    if ! [ -f "$wget_path" ]; then
        echo "Fetching secure wget..."
        # Download and compare to hash
        mkdir -p "$(dirname "$wget_path")"
        if ! wget -cq "$wget_remote" --output-document "$wget_path"; then
            echo "Error: Could not fetch wget, make sure you have a stable Wi-Fi connection"
            exit 1
        fi
    fi

    if ! sha256sum -c <(echo "$wget_checksum  $wget_path") > /dev/null 2>&1; then
        echo "Error: Invalid checksum for the local wget binary"
        exit 1
    fi

    chmod 755 "$wget_path"
    WGET="$wget_path"
}

# Hlavní část skriptu
if [ -z "$reMarkable_File_ID" ]; then
    # Pokud je reMarkable_File_ID prázdný, najdi nejnovější složku bez tečky v názvu
    latest_directory=$(find_Latest_Directory "$reMarkable_Path" "*")

    if [ -n "$latest_directory" ] && [ "$latest_directory" != "$reMarkable_Path" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(find_Latest_File "$latest_directory" "*")

        # Volání funkce pro zpracování nalezeného souboru
        process_Latest_File "$latest_file" "$latest_directory"
    else
        echo "Složka nebyla nalezena."
    fi
else
    # Pokud je reMarkable_File_ID neprázdný, vyhledej složku podle prefixu
    latest_directory=$(find_Latest_Directory "$reMarkable_Path" "${reMarkable_File_ID}*")

    if [ -n "$latest_directory" ]; then
        # Nalezení nejnovějšího souboru v nalezené složce
        latest_file=$(find_Latest_File "$latest_directory" "*")

        # Volání funkce pro zpracování nalezeného souboru
        process_Latest_File "$latest_file" "$latest_directory"
    else
        echo "Složka podle prefixu '$reMarkable_File_ID' nebyla nalezena."
    fi
fi
