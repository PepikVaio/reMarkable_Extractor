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

WGET="wget"

#    ___             _   _          
#   | __|  _ _ _  __| |_(_)___ _ _  
#   | _| || | ' \/ _|  _| / _ \ ' \ 
#   |_| \_,_|_||_\__|\__|_\___/_||_|
#    

# Pro stahování souborů v reMarkable.
# reMarkable má staré wget, které nepodporuje STL, toto chybu opraví.
upgrade_WGET () {
    wget_path=/home/root/.local/share/@Wajsar_Josef/wget
    wget_remote=http://toltec-dev.org/thirdparty/bin/wget-v1.21.1-1
    wget_checksum=c258140f059d16d24503c62c1fdf747ca843fe4ba8fcd464a6e6bda8c3bbb6b5

    # Tato část skriptu kontroluje, zda je soubor wget na specifikované cestě ($wget_path) a zda má správný kontrolní součet.
    # Pokud kontrolní součet nesouhlasí, soubor se smaže.
    if [ -f "$wget_path" ] && ! sha256sum -c <(echo "$wget_checksum  $wget_path") > /dev/null 2>&1; then
        rm "$wget_path"
    fi

    # Tato část skriptu kontroluje, zda je soubor wget na specifikované cestě ($wget_path).
    # Pokud ne, soubor se stáhne.
    if ! [ -f "$wget_path" ]; then
        echo "Info: Načítání zabezpečeného wget"
        # Stáhněte si a porovnejte s hash
        mkdir -p "$(dirname "$wget_path")"
        if ! wget -cq "$wget_remote" --output-document "$wget_path"; then
            echo "Error: Nelze načíst wget, ujistěte se, že máte stabilní připojení Wi-Fi"
            exit 1
        fi
    fi

    # Tento úsek skriptu kontroluje integritu staženého souboru wget pomocí jeho SHA-256 kontrolního součtu.
    if ! sha256sum -c <(echo "$wget_checksum  $wget_path") > /dev/null 2>&1; then
        echo "Error: Neplatný kontrolní součet pro místní binární soubor wget"
        exit 1
    fi

    chmod 755 "$wget_path"
    WGET="$wget_path"
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
    upgrade_WGET
    
    # Kopírování souboru do aktuální složky
    cp "$specified_file" "${reMarkable_Path}/${reMarkable_File_ID}"
fi