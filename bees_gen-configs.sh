#!/bin/bash

# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

# Define the base hash table size for 1TB of unique data (in bytes)
BASE_HASH_TABLE_SIZE_MB=128
BASE_HASH_TABLE_SIZE_BYTES=$((BASE_HASH_TABLE_SIZE_MB * 1024 * 1024))

# Get a list of all Btrfs filesystem UUIDs
BTRFS_UUIDS=$(blkid -o value -s UUID -t TYPE=btrfs)

# Check if no Btrfs filesystems were found and exit if none are present
if [ -z "$BTRFS_UUIDS" ]; then
    echo "No Btrfs filesystems found. Exiting..."
    exit 1
fi

# Loop through all Btrfs filesystems
for FS in $BTRFS_UUIDS
do
    # Use awk to extract the mount point from /etc/fstab for the UUID
    MOUNT_POINT=$(awk -v uuid="$FS" '$0 ~ "UUID=" uuid {print $2}' /etc/fstab)

    # If no mount point is found in /etc/fstab, skip the filesystem
    if [ -z "$MOUNT_POINT" ]; then
        echo "Mount point for UUID $FS not found in /etc/fstab. Skipping..."
        continue
    fi

    # Discover the disk size in GB of the Btrfs partition
    DISK_SIZE_OUTPUT=$(df -BG --output=size "$MOUNT_POINT" | tail -n 1)
    DISK_SIZE_GB=$(echo $DISK_SIZE_OUTPUT | awk '{print $1}' | sed 's/G//')
    echo "Disk size for UUID $FS: ${DISK_SIZE_GB}GB"

    # Calculate the hash table size in bytes based on the disk size
    HASH_TABLE_SIZE_BYTES=$((BASE_HASH_TABLE_SIZE_BYTES * DISK_SIZE_GB / 1024))
    HASH_TABLE_SIZE_MB=$((HASH_TABLE_SIZE_BYTES / 1024 / 1024))
    echo "Calculated hash table size for ${DISK_SIZE_GB}GB: ${HASH_TABLE_SIZE_BYTES} bytes (${HASH_TABLE_SIZE_MB}MB)"

    # Create the configuration directory if it doesn't exist
    mkdir -p /etc/bees/

    # Generate the bees.conf file
    cat <<EOF > /etc/bees/${FS}.conf
# bees.conf - configuration for bees deduplication agent

# UUID of the Btrfs filesystem
UUID=${FS}

# Size of the hash table for deduplication (in bytes)
DB_SIZE=${HASH_TABLE_SIZE_BYTES}

# Path to the working directory for bees
BEESHOME=/var/lib/bees/

EOF

    # Output the beesd command for the user to run
    echo "To run beesd for filesystem UUID ${FS}, use the following command:"
    echo "beesd ${FS}"

    # Provide the generated configuration details
    echo "bees.conf for filesystem UUID ${FS} has been generated."
done

