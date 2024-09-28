#!/bin/bash

# Help4 Network Property - Public License - Version 1.4
#
# License:
# This script is free for public use under the following terms:
# 1. For **public and personal use**, this script is free of charge.
# 2. For **commercial use**, public credit to Help4 Network is required for each and every use.
#    - All output, including credit lines, must remain intact and cannot be edited or omitted.
#    - This includes any usage in reports, scripts, distributions, or communications.
# 3. Commercial entities are free to use and distribute this script, but they **must** include this 
#    license and public credit to Help4 Network in any instance of usage, sharing, or distribution.
#
# Redistribution of this script without this license intact is prohibited.

VERSION="1.4"

# Configurable variables
TOP_FILES=20                   # Number of top largest files per user
INODE_THRESHOLD=10000          # Threshold for high inode usage
EXCLUDE_DIRS=("virtfs" "cloudlinux" "some_other_system_dir") # Directories to exclude
KNOWN_USER_PATTERN="^[a-zA-Z0-9][a-zA-Z0-9_-]*$"  # Pattern for valid cPanel usernames

# Function to check if the directory should be excluded
is_excluded_dir() {
    local dir_name=$1
    for excluded in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$dir_name" == "$excluded" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to find and display the largest files in a user's home directory
find_largest_files() {
    local user_home=$1
    local user=$(basename "$user_home")
    echo "Top $TOP_FILES largest files for user: $user"

    # Find the largest files, excluding system files and directories
    find "$user_home" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n $TOP_FILES
    echo
}

# Function to find directories with large inode usage for a user
find_large_inodes() {
    local user_home=$1
    local user=$(basename "$user_home")
    echo "Checking for high inode usage in $user's home directory..."

    # Find directories with inode usage greater than the threshold
    find "$user_home" -type d 2>/dev/null | while read -r dir; do
        inode_count=$(find "$dir" -type f 2>/dev/null | wc -l)
        if [ "$inode_count" -gt "$INODE_THRESHOLD" ]; then
            echo "$dir: $inode_count files"
        fi
    done
    echo
}

# Function to calculate the total size of user directories, excluding system directories
calculate_user_dirs_size() {
    local home_dir=$1
    local total_size=0
    for user_home in "$home_dir"/*; do
        if [ -d "$user_home" ]; then
            base_user=$(basename "$user_home")

            # Skip excluded directories
            if is_excluded_dir "$base_user"; then
                >&2 echo "Skipping system directory: $base_user"
                continue
            fi

            # Add size of the user directory
            user_size=$(du -sb "$user_home" 2>/dev/null | awk '{print $1}')
            total_size=$((total_size + user_size))
        fi
    done
    echo "$total_size"
}

# Function to find erroneous or abnormal directories
find_erroneous_folders() {
    local home_dir=$1
    echo "Checking for erroneous or abnormal directories in $home_dir..."
    for folder in "$home_dir"/*; do
        if [ -d "$folder" ]; then
            base_folder=$(basename "$folder")

            # If folder doesn't match known user pattern and is not in excluded list
            if ! [[ "$base_folder" =~ $KNOWN_USER_PATTERN ]] && ! is_excluded_dir "$base_folder"; then
                folder_size=$(du -sh "$folder" 2>/dev/null | awk '{print $1}')
                echo "Erroneous folder found: $base_folder ($folder_size)"
            fi
        fi
    done
    echo
}

# Convert bytes to human-readable format
convert_size_to_human() {
    numfmt --to=iec --suffix=B "$1"
}

# Main script
echo "Starting directory analysis (Version $VERSION)..."

# Collect list of user home directories to exclude from system checks
USER_DIRS=()
for home_dir in /home*; do
    if [ -d "$home_dir" ]; then
        for user_home in "$home_dir"/*; do
            if [ -d "$user_home" ]; then
                base_user=$(basename "$user_home")

                # Skip excluded directories
                if is_excluded_dir "$base_user"; then
                    continue
                fi

                USER_DIRS+=("$user_home")
            fi
        done
    fi
done

# Check /home* directories
for home_dir in /home*; do
    if [ -d "$home_dir" ]; then
        # Get total size of /home* directory
        total_home_size=$(du -sb "$home_dir" 2>/dev/null | awk '{print $1}')

        # Calculate total size of user directories
        total_user_size=$(calculate_user_dirs_size "$home_dir")

        # Convert sizes to human-readable format
        total_home_size_human=$(convert_size_to_human "$total_home_size")
        total_user_size_human=$(convert_size_to_human "$total_user_size")

        # Display sizes
        echo "Total size of all /home* directories: $total_home_size_human"
        echo "Total size of user directories: $total_user_size_human"

        # Compare the total size of /home* and sum of user directories
        if [ "$total_home_size" -ne "$total_user_size" ]; then
            echo "Warning: There is a size difference between /home* and the sum of user directories!"
        else
            echo "The total size of /home* matches the sum of user directories."
        fi

        # Check for erroneous or abnormal folders
        find_erroneous_folders "$home_dir"

        # Process each user directory
        for user_home in "$home_dir"/*; do
            if [ -d "$user_home" ]; then
                base_user=$(basename "$user_home")

                # Skip excluded directories
                if is_excluded_dir "$base_user"; then
                    echo "Skipping system directory: $base_user"
                    continue
                fi

                # Process user home directory
                find_largest_files "$user_home"
                find_large_inodes "$user_home"
            fi
        done
    fi
done

# System directories to check (excluding /proc and /home*)
SYSTEM_DIRS=("/" "/var" "/usr" "/tmp" "/var/tmp" "/var/log")
# Remove duplicates and ensure they don't include user directories
SYSTEM_DIRS_UNIQUE=($(printf "%s\n" "${SYSTEM_DIRS[@]}" | sort -u))

# Build find command exclude options
EXCLUDE_PATHS=("-path" "/proc" "-prune" "-o")
for home_dir in /home*; do
    EXCLUDE_PATHS+=("-path" "$home_dir" "-prune" "-o")
done

# Exclude additional user directories
for user_dir in "${USER_DIRS[@]}"; do
    EXCLUDE_PATHS+=("-path" "$user_dir" "-prune" "-o")
done

# Exclude specified directories in EXCLUDE_DIRS
for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_PATHS+=("-path" "*/$exclude_dir" "-prune" "-o")
done

# Check system areas
echo "Checking system directories (excluding /proc, /home*, user directories, and excluded directories)..."
for system_dir in "${SYSTEM_DIRS_UNIQUE[@]}"; do
    if [ -d "$system_dir" ] && [[ "$system_dir" != "/proc" ]] && [[ "$system_dir" != /home* ]]; then
        echo "Analyzing $system_dir..."
        # Find high inode usage and large files, excluding /proc, /home*, user directories, and excluded directories
        find "$system_dir" "${EXCLUDE_PATHS[@]}" \( -type d -o -type f \) 2>/dev/null | while read -r item; do
            # Skip if the item is in /proc or /home*
            if [[ "$item" == /proc* ]] || [[ "$item" == /home* ]]; then
                continue
            fi

            # For directories, check inode usage
            if [ -d "$item" ]; then
                inode_count=$(find "$item" -type f 2>/dev/null | wc -l)
                if [ "$inode_count" -gt "$INODE_THRESHOLD" ]; then
                    echo "High inode usage: $item - $inode_count files"
                fi
            fi

            # For files, check if size exceeds threshold (e.g., 1GB)
            if [ -f "$item" ]; then
                file_size=$(du -b "$item" 2>/dev/null | awk '{print $1}')
                if [ "$file_size" -ge $((1*1024*1024*1024)) ]; then
                    file_size_human=$(du -h "$item" 2>/dev/null | awk '{print $1}')
                    echo "Large file: $item - $file_size_human"
                fi
            fi
        done
        echo
    fi
done

echo "Directory analysis complete."
echo "Script provided by Help4 Network. Public credit required for commercial use."
