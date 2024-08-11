#!/bin/bash

# | Popis!
# | Tento skript se připojuje k serveru reMarkable přes SSH.
# 
# * Vyhledává nejnovější soubory a složky na základě zadaných kritérií.
# * Stahuje je do lokálního adresáře.
# * Skript využívá nástroj sshpass pro autentizaci a scp pro stahování souborů.

# | Použití!
# | Skript lze spustit bez parametrů.

# * Pokud je zadané ID souboru, bude hledat složku začínající tímto ID a stáhne nejnovější soubor.
# * Jinak hledá nejnovější soubor ve složkách bez tečky v názvu.

# | Konfigurace!
# | Najdete v nastavení reMarkable.

# * reMarkable_User_Name: Uživatelské jméno pro přístup k reMarkable
# * reMarkable_IP_Addresses: IP adresa reMarkable
# * reMarkable_Password: Heslo pro přístup k reMarkable
# * reMarkable_File_ID: ID souboru (nepovinné)
# * reMarkable_Path: Cesta k adresáři na reMarkable
# ************************************************************************************************

#    ___      _   _   _                              __  __          _        _    _     
#   / __| ___| |_| |_(_)_ _  __ _ ___  ___   _ _ ___|  \/  |__ _ _ _| |____ _| |__| |___ 
#   \__ \/ -_)  _|  _| | ' \/ _` (_-< |___| | '_/ -_) |\/| / _` | '_| / / _` | '_ \ / -_)
#   |___/\___|\__|\__|_|_||_\__, /__/       |_| \___|_|  |_\__,_|_| |_\_\__,_|_.__/_\___|
#                           |___/                                                        

# Vzdálený reMarkable_Server
reMarkable_User_Name="root"
reMarkable_IP_Addresses="10.0.1.24"
reMarkable_Password="qLA21wsX9x"

# Spojení proměnných do jedné pro použití v příkazu ssh
reMarkable_Server="$reMarkable_User_Name@$reMarkable_IP_Addresses"

# ID souboru, například eaf3f838 (nepovinný)
reMarkable_File_ID=""

# Cesta k souborům
reMarkable_Path="/home/root/.local/share/remarkable/xochitl/"


#    ___             _   _          
#   | __|  _ _ _  __| |_(_)___ _ _  
#   | _| || | ' \/ _|  _| / _ \ ' \ 
#   |_| \_,_|_||_\__|\__|_\___/_||_|
#                                   

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

# Funkce pro nalezení nejnovější složky bez tečky na konci
find_Latest_Directory() {
    local search_path="$1"
    local search_pattern="$2"
    sshpass -p "$reMarkable_Password" ssh "$reMarkable_Server" "
        find \"$search_path\" -maxdepth 1 -type d -name '$search_pattern' ! -name '*.*' ! -name 'xochitl' -print | while read dir; do
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


#    __  __      _         __           _      _   _          
#   |  \/  |__ _(_)_ _    / _|_  _ _ _ | |____| |_(_)___ _ _  
#   | |\/| / _` | | ' \  |  _| || | ' \| / / _|  _| / _ \ ' \ 
#   |_|  |_\__,_|_|_||_| |_|  \_,_|_||_|_\_\__|\__|_\___/_||_|
#                                                                                   

# Kontrola, zda je zadané heslo
if [ -z "$reMarkable_Password" ]; then
    echo "Chyba: Nebylo zadané heslo pro připojení k serveru."
    exit 1
fi

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
        echo "Složka nebyla nalezena."
    fi
fi