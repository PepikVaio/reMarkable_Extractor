#!/bin/bash

# Přečtěte vstupy ze standardního vstupu (stdin)
IFS=$'\n' read -d '' -r USERNAME IP_ADDRESS PASSWORD

# Odstranění zbytečných mezer
IP_ADDRESS=$(echo "$IP_ADDRESS" | xargs)
PASSWORD=$(echo "$PASSWORD" | xargs)

# Zobrazte zadané hodnoty pro kontrolu
echo "Uživatelské jméno: $USERNAME"
echo "IP adresa: $IP_ADDRESS"
echo "Heslo: $PASSWORD"

# Cesta k souboru na reMarkable
REMOTE_FILE_PATH="/home/root/.local/share/remarkable/xochitl/a05f671f-1b09-4210-bf3c-868879e714b2/7fbc381c-04f8-41c3-a0a3-aa5831d1b64b.rm"

# Stáhněte soubor z reMarkable do aktuální pracovní složky
sshpass -p "$PASSWORD" scp "${USERNAME}@${IP_ADDRESS}:${REMOTE_FILE_PATH}" .

echo "Soubor byl úspěšně stažen do aktuální složky."
