#!/bin/bash

# Zeptejte se uživatele na uživatelské jméno a IP adresu reMarkable zařízení
read -p "Zadejte uživatelské jméno: " REMOTE_USER
read -p "Zadejte IP adresu reMarkable zařízení: " REMOTE_IP

# Definujte cestu k souboru na reMarkable
REMOTE_FILE_PATH="/home/root/.local/share/remarkable/xochitl/a05f671f-1b09-4210-bf3c-868879e714b2/7fbc381c-04f8-41c3-a0a3-aa5831d1b64b.rm"

# Stáhněte soubor z reMarkable do aktuální pracovní složky
scp "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_FILE_PATH}" .

echo "Soubor byl úspěšně stažen do aktuální složky."
