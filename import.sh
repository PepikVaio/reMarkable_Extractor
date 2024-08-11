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



# Funkce pro nalezení složky, která začíná na reMarkable_File_ID a nemá tečku na konci
find_Directory() {
    local search_path="$1"
    local search_pattern="$2"
    find "$search_path" -maxdepth 1 -type d -name "$search_pattern" ! -name '*.*' ! -name 'xochitl' -print -quit
}




#    __  __      _         __           _      _   _          
#   |  \/  |__ _(_)_ _    / _|_  _ _ _ | |____| |_(_)___ _ _  
#   | |\/| / _` | | ' \  |  _| || | ' \| / / _|  _| / _ \ ' \ 
#   |_|  |_\__,_|_|_||_| |_|  \_,_|_||_|_\_\__|\__|_\___/_||_|
#  

# Hlavní část skriptu
if [ -z "$reMarkable_File_ID" ]; then
    # Pokud je reMarkable_File_ID prázdný zastav script.
    echo "Error: Složka nebyla nalezena."
    exit 1
else
    # Pokud je reMarkable_File_ID neprázdný, vyhledej složku podle prefixu
    latest_directory=$(find_Directory "$reMarkable_Path" "${reMarkable_File_ID}*")

    # Kopírování souboru do aktuální složky
    cp "$latest_directory"
fi



