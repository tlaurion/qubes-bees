#!/bin/bash

# Directory containing .img files
IMG_DIR="/var/lib/qubes/"

# Function to analyze shared extents
analyze_shared_extents() {
    local dir=$1
    echo "Analyzing shared extents in $dir"

    # Find all .img files and sort them by size to assume parent/child relationship
    mapfile -t img_files < <(find "$dir" -name "*.img" -printf "%s %p\n" | sort -nr | cut -d' ' -f2-)

    # Loop through each .img file and find shared extents
    for img_file in "${img_files[@]}"; do
        echo "Parent File: $img_file"
        # Get the physical extents of the file
        mapfile -t extents < <(sudo btrfs fiemap --logical "$img_file" | awk '{print $4}')

        # Check for shared extents in other files
        for extent in "${extents[@]}"; do
            mapfile -t shared_files < <(sudo btrfs inspect-internal inode-resolve "$extent" / | grep -v "$img_file")
            for shared_file in "${shared_files[@]}"; do
                echo "|-> Child File: $shared_file"
            done
        done
    done
}

# Analyze .img files for shared extents
analyze_shared_extents "$IMG_DIR"

