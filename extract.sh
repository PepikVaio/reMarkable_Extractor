#!/bin/bash

# | Popis!
# | Tento skript se připojuje k serveru reMarkable přes SSH.
# 
# * Vyhledává nejnovější soubory a složky na základě zadaných kritérií.
# * Stahuje je do lokálního adresáře.
# * Skript využívá nástroj sshpass pro autentizaci a scp pro stahování souborů.

# | Použití!
# | Skript lze spustit s parametry: [uživatelské jméno] [IP adresa] [heslo] [ID souboru (nepovinné)]

# * ./extract.sh [reMarkable_User_Name] [reMarkable_IP_Addresses] [reMarkable_Password] [reMarkable_File_ID]

# | Konfigurace!
# | Najdete v nastavení reMarkable.

# * reMarkable_User_Name: Uživatelské jméno pro přístup k reMarkable
# * reMarkable_IP_Addresses: IP adresa reMarkable
# * reMarkable_Password: Heslo pro přístup k reMarkable
# * reMarkable_File_ID: ID souboru (nepovinné)
# * reMarkable_Path: Cesta k adresáři na reMarkable
# **********************************************************************************************************


#    ___                _      
#   |_ _|_ _  _ __ _  _| |_ ___
#    | || ' \| '_ \ || |  _(_-<
#   |___|_||_| .__/\_,_|\__/__/
#            |_|               

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Chyba: Požadovány 3 nebo 4 parametry: uživatelské jméno, IP adresa, heslo, [ID souboru (nepovinné)]."
    exit 1
fi


#    ___      _   _   _                              __  __          _        _    _     
#   / __| ___| |_| |_(_)_ _  __ _ ___  ___   _ _ ___|  \/  |__ _ _ _| |____ _| |__| |___ 
#   \__ \/ -_)  _|  _| | ' \/ _` (_-< |___| | '_/ -_) |\/| / _` | '_| / / _` | '_ \ / -_)
#   |___/\___|\__|\__|_|_||_\__, /__/       |_| \___|_|  |_\__,_|_| |_\_\__,_|_.__/_\___|
#                           |___/                                                        

# reMarkable server
reMarkable_User_Name="$1"
reMarkable_IP_Addresses="$2"
reMarkable_Password="$3"
reMarkable_File_ID="${4:-}"  # Pokud čtvrtý parametr není zadán, použije prázdný řetězec

# Spojení proměnných do jedné pro použití v příkazu ssh
reMarkable_Server="$reMarkable_User_Name@$reMarkable_IP_Addresses"

# Cesta k souborům
reMarkable_Path="/home/$reMarkable_User_Name/.local/share/remarkable/xochitl/"

#    ___          _      _   _             
#   | __|  _ _ _ | |____| |_(_)___ _ _  ___
#   | _| || | ' \| / / _|  _| / _ \ ' \(_-<
#   |_| \_,_|_||_|_\_\__|\__|_\___/_||_/__/
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
        echo "Složka podle prefixu '$reMarkable_File_ID' nebyla nalezena."
    fi
fi
