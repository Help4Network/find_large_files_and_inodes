# **Find Large Files and Inodes**

This script helps identify the largest files and directories with high inode usage, focusing on `/home*` directories, specifically for `cPanel` users. It can be used to monitor disk usage, inode consumption, and detect anomalous directories. 

The script is free for public use but requires **public credit** for commercial use, as outlined in the license.

## **Features**
- Displays the largest files for each cPanel user's home directory.
- Detects directories with high inode usage.
- Excludes system directories like `/proc` and `virtfs` to prevent performance issues.
- Includes system-wide checks for large files and high inode usage while excluding user directories.

## **Installation**

1. **Download the Script**:

   You can download the script using `wget`:

   ```bash
   wget -qO find_large_files_and_inodes.sh https://yourdownloadlink.com/find_large_files_and_inodes.sh
   ```

2. **Make the Script Executable**:

   Set the correct permissions to make the script executable:

   ```bash
   sudo chmod +x find_large_files_and_inodes.sh
   ```

3. **Run the Script**:

   Execute the script to analyze disk usage and inode consumption:

   ```bash
   sudo bash find_large_files_and_inodes.sh
   ```

## **Requirements**

- **Root or sudo access** is required to run this script, as it checks inode usage and file sizes across multiple users and directories.
- The script is designed to work on systems with shared hosting environments using `cPanel`.

## **License**

This project is licensed under the **GNU General Public License v3**, with additional terms for commercial use:

- The script is free for public and personal use.
- For commercial use:
  - Public credit must be given to **Help4 Network** for every use of this script.
  - The output, including credit lines, must remain intact and unmodified in reports, scripts, or distributions.

For more details, please refer to the [LICENSE](./LICENSE) file.
