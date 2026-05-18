#!/usr/bin/env bash
# Finds unmounted partitions and mounts them under /media/$USER/

set -euo pipefail

MOUNT_BASE="/media/${USER}"

while read -r name fstype label; do
    mount_name="${label:-$name}"
    mount_point="${MOUNT_BASE}/${mount_name}"

    echo "Mounting /dev/${name} (${fstype}) -> ${mount_point}"
    sudo mkdir -p "${mount_point}"

    if [[ "${fstype}" == "ntfs" || "${fstype}" == "ntfs-3g" ]]; then
        sudo mount -t ntfs-3g "/dev/${name}" "${mount_point}"
    else
        sudo mount "/dev/${name}" "${mount_point}"
    fi

    echo "  Done."

done < <(lsblk -o NAME,FSTYPE,LABEL,MOUNTPOINT -rn \
    | awk '$2 != "" && $4 == "" && $1 !~ /^(loop|sr)/ {print $1, $2, ($3 == "" ? $1 : $3)}')
