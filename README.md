# **Find Large Files and Inodes**

This script identifies the largest files and directories with high inode usage, focusing on `/home*` directories, specifically for `cPanel` users. It helps monitor disk usage, inode consumption, and detect anomalous directories. 

The script is free for public use but requires **public credit** for commercial use, as outlined in the license.

## **Features**
- Displays the largest files for each cPanel user's home directory.
- Detects directories with high inode usage.
- Excludes system directories like `/proc` and `virtfs` to prevent performance issues.
- Includes system-wide checks for large files and high inode usage while excluding user directories.

## **Installation and Usage**

### **Option 1: Run the Script in Place**

You can run the script directly from the hosted location without downloading it:

#### Using `wget`:
```bash
sudo wget -qO- https://fixitphill.com/scripts/find_large_files_and_inodes.sh | sudo bash
```

#### Using `curl`:
```bash
sudo curl -s https://fixitphill.com/scripts/find_large_files_and_inodes.sh | sudo bash
```

### **Option 2: Download and Run Locally**

If you prefer to download the script and run it locally, follow these steps:

#### Using `wget`:
```bash
wget https://fixitphill.com/scripts/find_large_files_and_inodes.sh
sudo chmod +x find_large_files_and_inodes.sh
sudo ./find_large_files_and_inodes.sh
```

#### Using `curl`:
```bash
curl -O https://fixitphill.com/scripts/find_large_files_and_inodes.sh
sudo chmod +x find_large_files_and_inodes.sh
sudo ./find_large_files_and_inodes.sh
```

## **Requirements**

- **Root or sudo access** is required to run this script since it checks inode usage and file sizes across multiple users and directories.
- The script is designed to work on systems with shared hosting environments using `cPanel`.

## **License**

This project is licensed under the **GNU General Public License v3**, with additional terms for commercial use:

- The script is free for public and personal use.
- For commercial use:
  - Public credit must be given to **Help4 Network** for every use of this script.
  - The output, including credit lines, must remain intact and unmodified in reports, scripts, or distributions.

For more details, please refer to the [LICENSE](./LICENSE) file.

---
