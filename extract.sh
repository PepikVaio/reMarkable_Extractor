#!/bin/bash

# Název složky, která začíná na eaf3f838
folder_prefix="eaf3f838"

# Vzdálený server a cesta
server="root@10.0.1.24"
remote_path="/home/root/.local/share/remarkable/xochitl"

# Vyhledání složky začínající na eaf3f838 a neobsahující tečku a nalezení nejnovějšího souboru ve složce
latest_file=$(ssh -T "$server" bash <<EOF
    # Vyhledání složky
    target_directory=\$(find "$remote_path" -maxdepth 1 -type d -name '${folder_prefix}*' ! -name '*.*')

    if [ -n "\$target_directory" ]; then
        # Nalezení nejnovějšího souboru ve složce
        find "\$target_directory" -type f -exec stat -c '%Y %n' {} + | sort -n | tail -1 | cut -d' ' -f2-
    else
        echo "Složka nebyla nalezena."
    fi
EOF
)

if [ -n "$latest_file" ] && [ "$latest_file" != "Složka nebyla nalezena." ]; then
    # Získání názvu souboru bez cesty
    file_name=$(basename "$latest_file")
    echo "Nejnověji upravený soubor!"
    echo "Soubor:" "$file_name"

    # Stáhnout soubor
    scp "$server:\"$latest_file\"" .
else
    echo "Soubor nebyl nalezen."
fi
