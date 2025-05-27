# Building a secure Tails+Obsidian USB drive for Kansas Socialist Book Club

This technical guide provides step-by-step instructions for creating a pre-configured Tails USB with Obsidian AppImage installation for the Kansas Socialist Book Club (KSBC). **The setup enables secure, anonymous document collaboration with hardware key authentication** while maintaining a "clone once, deploy many" distribution model that balances security with usability.

## Creating the master Tails USB drive (Debian 12 host)

### Download and verify Tails

```bash
# Create a directory for the installation files
mkdir -p ~/tails-install
cd ~/tails-install

# Download Tails image and verification materials
wget https://tails.net/install/download/tails-amd64-6.15.img
wget https://tails.net/tails-signing.key
wget https://tails.net/install/download/tails-amd64-6.15.img.sig

# Import and verify the Tails signing key
gpg --import < tails-signing.key
sudo apt update && sudo apt install debian-keyring
gpg --keyring=/usr/share/keyrings/debian-keyring.gpg --export chris@chris-lamb.co.uk | gpg --import
gpg --keyid-format 0xlong --check-sigs A490D0F4D311A4153E2BB7CADBB802B258ACD84F
gpg --keyid-format 0xlong --verify tails-amd64-6.15.img.sig tails-amd64-6.15.img
```

### Write Tails to your 32GB USB drive

```bash
# Identify your USB drive
lsblk

# Write the image (replace /dev/sdX with your actual USB device)
sudo dd if=tails-amd64-6.15.img of=/dev/sdX bs=16M oflag=direct status=progress
```

### Boot and configure persistence

1. Boot from the USB drive (usually F12, F2, or Esc during startup)
2. At the Tails Greeter, select your language and click "Start Tails"
3. Once Tails is running, go to Applications → Tails → Configure Persistent Storage
4. Create a strong passphrase and enable these persistence features:
   - Persistent Folder
   - GnuPG
   - SSH Client
   - Dotfiles
   - Additional Software
   - Network Connections
   - Tor Browser Bookmarks
5. Click "Save" then restart Tails
6. At the Greeter, unlock your Persistent Storage with your passphrase
7. Enable the Administration Password option and set a password for this session

## Installing Obsidian with required plugins

### Install dependencies and Obsidian AppImage

```bash
# Install required dependencies
sudo apt update
sudo apt install -y libfuse2 git curl

# Create directories for Obsidian
mkdir -p ~/Persistent/Obsidian
mkdir -p ~/Persistent/Obsidian/Vault

# Download Obsidian AppImage via Tor Browser
# Save to the default Tor Browser download location
# (Manual step: Visit https://obsidian.md/download and download Linux AppImage)

# Move and make executable
mv ~/Tor\ Browser/Obsidian-*.AppImage ~/Persistent/Obsidian/
chmod +x ~/Persistent/Obsidian/*.AppImage

# Create a launcher shortcut
mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications

cat > /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/obsidian.desktop << EOL
[Desktop Entry]
Name=Obsidian
Exec=/home/amnesia/Persistent/Obsidian/Obsidian-*.AppImage
Type=Application
Categories=Office;
EOL
```

### Configure Obsidian for persistence

```bash
# Launch Obsidian for the first time
cd ~/Persistent/Obsidian/
./Obsidian-*.AppImage

# When prompted, choose "Open folder as vault" and select ~/Persistent/Obsidian/Vault
# Enable community plugins in Settings → Community plugins (disable "Restricted mode")

# Ensure plugin settings persist across reboots
mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.config/obsidian
```

### Install and configure the 17 required plugins

Once Obsidian is running with community plugins enabled:

1. Go to Settings → Community plugins → Browse
2. Search and install each of these plugins:
   - Advanced slides
   - Advanced tables
   - CSS editor
   - Dataloom
   - Dataview
   - Git
   - GPG encrypt
   - Kanban
   - Linter
   - Metaedit
   - Projects
   - Shell commands
   - Tag wrangler
   - Tagfolder
   - Tasks

3. Configure each plugin:

```bash
# For Git plugin, install git if not already available
sudo apt-get install -y git

# For GPG Encrypt plugin, verify GPG is installed and working
gpg --version

# Configure plugin settings in Obsidian's settings panel
# For each plugin, enable and configure as needed

# Create a folder for CSS customizations
mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.config/obsidian/snippets
```

### Ensure plugin persistence across reboots

```bash
# Make sure the Obsidian config stays in persistent storage
mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.config/obsidian

# Copy Obsidian's config to persistent storage
cp -r ~/Persistent/Obsidian/Vault/.obsidian/* /live/persistence/TailsData_unlocked/dotfiles/.config/obsidian/

# Create symbolic link
ln -sf /live/persistence/TailsData_unlocked/dotfiles/.config/obsidian ~/Persistent/Obsidian/Vault/.obsidian
```

## Hardware key authentication setup

### Install required packages

```bash
# Install the necessary packages for hardware key support
sudo apt update
sudo apt install -y libfido2-1 opensc pcscd scdaemon yubikey-manager pcsc-tools

# Add these to the persistent additional software list
# Applications → System Tools → Additional Software
```

### Create scripts for Feitian K9D key setup

```bash
# Create a directory for scripts
mkdir -p ~/Persistent/scripts

# Create SSH key generation script
cat > ~/Persistent/scripts/create-ssh-keys-hardware.sh << 'EOF'
#!/bin/bash
# Script to create SSH keys with Feitian K9D ePass NFC hardware key
set -e

echo "=== SSH Key Generation with Hardware Security Key ==="
echo "This script will help you create SSH keys using your Feitian hardware key."
echo "Please insert your Feitian K9D security key now."
echo ""

read -p "Enter a comment to identify your key (e.g., your email): " COMMENT
read -p "Enter a filename for your key (without path): " FILENAME

if [ -z "$FILENAME" ]; then
  FILENAME="id_ecdsa_sk_$(date +%Y%m%d)"
fi

echo ""
echo "Attempting to generate ed25519-sk key..."
if ssh-keygen -t ed25519-sk -O resident -O verify-required -C "$COMMENT" -f ~/.ssh/$FILENAME; then
  KEY_TYPE="ed25519-sk"
  echo "Successfully created ed25519-sk key."
else
  echo "Failed to create ed25519-sk key. Trying ecdsa-sk instead..."
  if ssh-keygen -t ecdsa-sk -O resident -O verify-required -C "$COMMENT" -f ~/.ssh/$FILENAME; then
    KEY_TYPE="ecdsa-sk"
    echo "Successfully created ecdsa-sk key."
  else
    echo "Failed to create hardware-based SSH key. Please check if your hardware key is inserted properly."
    exit 1
  fi
fi

# Add to SSH config
cat >> ~/.ssh/config << SSHCONF

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/$FILENAME
  IdentitiesOnly yes
SSHCONF

echo ""
echo "=== Next Steps ==="
echo "1. Your SSH key has been created and configured."
echo "2. Your public key is: ~/.ssh/$FILENAME.pub"
echo "3. To add this key to GitHub or another service, copy the contents of this file:"
echo "   cat ~/.ssh/$FILENAME.pub"
echo ""
echo "4. To test your connection to GitHub, run:"
echo "   ssh -T git@github.com"
echo ""
echo "Your SSH keys are stored in the Persistent Storage and will be available each time you start Tails."
EOF

# Create GPG key generation script
cat > ~/Persistent/scripts/create-gpg-key.sh << 'EOF'
#!/bin/bash
# Script to help users create a GPG key
set -e

echo "=== GPG Key Generation Tool ==="
echo "This script will help you create a secure GPG key pair."
echo ""

read -p "Enter your name: " NAME
read -p "Enter your email: " EMAIL
read -p "Enter an optional comment (or press Enter to skip): " COMMENT

if [ -n "$COMMENT" ]; then
  USERINFO="$NAME ($COMMENT) <$EMAIL>"
else
  USERINFO="$NAME <$EMAIL>"
fi

echo ""
echo "You are about to create a key for: $USERINFO"
read -p "Is this correct? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
  echo "Aborting. Please run the script again."
  exit 1
fi

echo ""
echo "Creating GPG key..."
gpg --batch --gen-key <<GPG_BATCH
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $NAME
Name-Email: $EMAIL
$([ -n "$COMMENT" ] && echo "Name-Comment: $COMMENT")
Expire-Date: 2y
%no-protection
%commit
GPG_BATCH

KEY_ID=$(gpg --list-secret-keys --keyid-format LONG "$EMAIL" | grep sec | awk '{print $2}' | cut -d'/' -f2)

echo ""
echo "GPG key created successfully!"
echo "Your key ID is: $KEY_ID"
echo ""
echo "Creating revocation certificate..."

gpg --output ~/Persistent/gpg-revocation-cert.asc --gen-revoke "$KEY_ID"
chmod 600 ~/Persistent/gpg-revocation-cert.asc

echo ""
echo "=== Next Steps ==="
echo "1. Backup your GPG key:"
echo "   gpg --export-secret-keys --armor $KEY_ID > ~/Persistent/gpg-secret-key.asc"
echo "2. Store your revocation certificate safely"
echo "3. Configure Git to use your new key:"
echo "   git config --global user.signingkey $KEY_ID"
echo "   git config --global commit.gpgsign true"
echo ""
echo "Your GPG keys are stored in the Persistent Storage and will be available each time you start Tails."
EOF

# Make scripts executable
chmod +x ~/Persistent/scripts/create-gpg-key.sh
chmod +x ~/Persistent/scripts/create-ssh-keys-hardware.sh
```

### Create documentation and welcome guide

```bash
# Create a README file with instructions
cat > ~/Persistent/README.md << 'EOF'
# KSBC Tails+Obsidian Setup Guide

Welcome to your secure Tails environment! This document will help you set up your personal security keys and authentication.

## First-Time Setup

1. **Start Tails and unlock the Persistent Storage**
   - When the Tails Greeter appears, enter the Persistent Storage passphrase provided to you
   - Click "Start Tails"

2. **Create your GPG key**
   - Open a Terminal window (Applications → System Tools → Terminal)
   - Run the GPG key creation script:
     ```
     ~/Persistent/scripts/create-gpg-key.sh
     ```
   - Follow the prompts to create your key
   - Make sure to backup your key and revocation certificate to a secure location

3. **Set up your hardware security key for SSH authentication**
   - Insert your Feitian K9D security key into a USB port
   - Open a Terminal window
   - Run the SSH key creation script:
     ```
     ~/Persistent/scripts/create-ssh-keys-hardware.sh
     ```
   - Follow the prompts to create your key
   - When prompted, enter your hardware key's PIN and touch the key when it flashes

4. **Configure Git**
   - Open a Terminal window
   - Set your Git identity:
     ```
     git config --global user.name "Your Name"
     git config --global user.email "your.email@example.com"
     git config --global user.signingkey YOUR_GPG_KEY_ID
     git config --global commit.gpgsign true
     ```
   - Replace YOUR_GPG_KEY_ID with the key ID from step 2

5. **Launch Obsidian**
   - Launch Obsidian from the Applications menu or by running:
     ```
     ~/Persistent/Obsidian/Obsidian-*.AppImage
     ```
   - Your vault and all plugins are pre-configured and ready to use

## Using Your Secure Environment

- Your GPG and SSH keys are stored in the Persistent Storage and will be available each time you start Tails
- When authenticating with Git or SSH, you'll be prompted to enter your hardware key's PIN and touch the key
- All your work should be saved in the Persistent folder to be preserved across sessions
- Use the GPG Encrypt plugin within Obsidian for sensitive notes

## Security Best Practices

- Keep your Tails USB drive secure at all times
- Keep your hardware security key separate from your Tails USB drive when not in use
- Never share your PINs or passphrases
- Regularly backup important data (but be careful about where you store backups)
- If you lose your hardware key or Tails USB, notify the administrator immediately
EOF

# Create a welcome script for first boot
cat > ~/Persistent/welcome-setup.sh << 'EOF'
#!/bin/bash
# This script helps users set up their personal configuration on first boot

# Check if this is the first run
FIRST_RUN_MARKER="/live/persistence/TailsData_unlocked/.welcome-completed"
if [ -f "$FIRST_RUN_MARKER" ]; then
  exit 0
fi

zenity --info --title="Welcome to KSBC Tails" --width=500 --text="Welcome to your secure Tails environment!\n\nThis wizard will help you set up your personal security keys and Git configuration.\n\nPlease read the instructions carefully and follow the steps to complete your setup."

# Show README file
zenity --text-info --title="Setup Instructions" --filename="/home/amnesia/Persistent/README.md" --width=700 --height=500

# Mark as completed
touch "$FIRST_RUN_MARKER"

# Open Terminal for the user to run setup scripts
zenity --question --title="Begin Setup" --text="Would you like to open a Terminal to begin the setup process now?" --width=400
if [ $? -eq 0 ]; then
  gnome-terminal
fi
EOF

# Make the script executable
chmod +x ~/Persistent/welcome-setup.sh

# Create an autostart entry for the welcome script
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/welcome-setup.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Welcome Setup
Exec=/home/amnesia/Persistent/welcome-setup.sh
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# Copy to persistent dotfiles
mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.config/autostart
cp ~/.config/autostart/welcome-setup.desktop /live/persistence/TailsData_unlocked/dotfiles/.config/autostart/
```

## Cloning process for distribution

### Verify master USB configuration

Before cloning, ensure:

1. Tails USB boots correctly
2. Persistence is properly configured
3. Obsidian launches with all plugins
4. All required scripts are in place
5. Documentation is complete

### Clone to multiple USB drives

```bash
# Boot into your master Tails USB with Persistent Storage unlocked

# Use the Tails Cloner to create copies
# Applications → Tails → Tails Cloner

# For each target USB drive:
# 1. Insert the target USB drive
# 2. In Tails Cloner, select "Clone the current Tails"
# 3. Check "Clone the current Persistent Storage"
# 4. Select the target USB in the dropdown
# 5. Enter a distinct passphrase for each user's Persistent Storage
# 6. Click "Install" and confirm
```

### USB drive distribution logistics

1. **Prepare secure distribution packages for each user:**
   - USB drive in tamper-evident packaging
   - Feitian K9D ePass NFC hardware key (separately packaged)
   - Printed welcome guide with initial persistent storage passphrase
   - Emergency contact information card

2. **Track distribution:**
   - Maintain a secure log of which drive went to which user
   - Record the USB drive serial number or identifier
   - Do not record persistent storage passphrases

## First use workflow for team members

When a user receives their Tails USB:

1. **Boot from the USB drive**
   - Enter the provided temporary persistent storage passphrase
   - The welcome script will automatically run and guide setup

2. **Hardware key setup**
   - Insert the Feitian K9D key
   - Set/change the hardware key PIN:
     ```bash
     ykman fido access change-pin
     ```
   - Run the SSH key creation script:
     ```bash
     ~/Persistent/scripts/create-ssh-keys-hardware.sh
     ```

3. **GPG key creation**
   - Run the GPG key creation script:
     ```bash
     ~/Persistent/scripts/create-gpg-key.sh
     ```
   - Note the Key ID for Git configuration

4. **Git configuration**
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   git config --global user.signingkey YOUR_GPG_KEY_ID
   git config --global commit.gpgsign true
   ```

5. **Change Persistent Storage passphrase**
   - Applications → Tails → Persistent Storage
   - Click "Change Passphrase" and set a strong personal passphrase

6. **Test repository access**
   - Add SSH public key to GitHub/GitLab
   - Test cloning a repository:
     ```bash
     mkdir -p ~/Persistent/git-repos
     cd ~/Persistent/git-repos
     git clone git@github.com:ksbc/repository.git
     ```

## Security considerations and troubleshooting

### Key security practices

- **Hardware key storage:** Keep the Feitian K9D key physically separate from the Tails USB when not in use
- **Repository security:** Configure repositories to require signed commits
- **Key verification:** Regularly verify fingerprints of team members' keys
- **Network access:** Only connect to trusted networks or use Tor

### Troubleshooting common issues

1. **Hardware key not detected:**
   ```bash
   # Check if the device is recognized
   pcsc_scan

   # Reset the hardware key interface
   sudo service pcscd restart
   ```

2. **Obsidian plugins not persisting:**
   ```bash
   # Verify symbolic links
   ls -la ~/Persistent/Obsidian/Vault/.obsidian

   # Recreate persistence link if needed
   ln -sf /live/persistence/TailsData_unlocked/dotfiles/.config/obsidian ~/Persistent/Obsidian/Vault/.obsidian
   ```

3. **Git authentication failures:**
   ```bash
   # Check SSH configuration
   cat ~/.ssh/config

   # Test SSH connection
   ssh -vT git@github.com
   ```

4. **Tails persistence issues:**
   ```bash
   # Verify persistence configuration
   cat /live/persistence/TailsData_unlocked/persistence.conf

   # Check if persistence is properly mounted
   mount | grep persist
   ```

## Emergency procedures

Create a document at `~/Persistent/emergency-procedures.md` with instructions for:

1. **Lost hardware key protocol:**
   - Immediately revoke the SSH key from all services
   - Generate new keys with a replacement hardware key
   - Update all repository access credentials

2. **Compromised Tails USB response:**
   - Do not boot from the USB drive
   - Report to admin for replacement
   - Prepare for key rotation

3. **Forgotten persistent storage passphrase:**
   - Data recovery is not possible
   - Request a new Tails USB
   - Recreate keys and configurations

By following this guide, you'll create a secure, portable Obsidian environment on Tails USB drives that can be easily distributed to Kansas Socialist Book Club members while maintaining strong security through hardware key authentication.
