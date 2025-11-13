#!/bin/bash
# ==========================================
# CyberPatriot Linux Mint Hardening Script
# Safe Best-Practice Baseline
# ==========================================

# Confirm root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo bash scriptname.sh)"
  exit
fi

# -------------------------
# 1. Basic System Updates
# -------------------------
echo "[+] Updating system packages..."
apt update -y && apt upgrade -y

# -------------------------
# 2. Account and Password Policies
# -------------------------
echo "[+] Securing password policies..."
# Set password aging
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   10/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs

# Lock system accounts that don’t need login
echo "[+] Locking unnecessary system accounts..."
for user in $(awk -F: '($3 < 1000 && $1 != "root") {print $1}' /etc/passwd); do
  usermod -L "$user"
done

# Disable guest account (Mint/Ubuntu LightDM)
if [ -f /etc/lightdm/lightdm.conf ]; then
  echo "[Seat:*]" > /etc/lightdm/lightdm.conf
  echo "allow-guest=false" >> /etc/lightdm/lightdm.conf
fi

# -------------------------
# 3. Sudo and Admin Checks
# -------------------------
echo "[+] Checking admin users..."
grep 'sudo' /etc/group
echo "[*] Review the above list — remove unauthorized users with:"
echo "    deluser username sudo"

# -------------------------
# 4. Firewall Configuration
# -------------------------
echo "[+] Enabling UFW firewall..."
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw enable
ufw status verbose

# -------------------------
# 5. SSH Hardening
# -------------------------
if [ -f /etc/ssh/sshd_config ]; then
  echo "[+] Hardening SSH..."
  sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
  systemctl restart ssh
fi

# -------------------------
# 6. Service and Startup Management
# -------------------------
echo "[+] Disabling unnecessary services..."
systemctl disable avahi-daemon || true
systemctl disable cups-browsed || true
systemctl disable bluetooth || true
systemctl disable rpcbind || true

# -------------------------
# 7. Check for Suspicious Files
# -------------------------
echo "[+] Searching for media, hacking tools, and other suspicious files..."
find /home -type f \( -iname "*.mp3" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.torrent" \) > /root/suspicious_files.txt
echo "[*] Suspicious files listed in /root/suspicious_files.txt"

# -------------------------
# 8. Permissions & Ownership
# -------------------------
echo "[+] Fixing critical file permissions..."
chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
chmod 644 /etc/passwd /etc/group
chmod 640 /etc/shadow /etc/gshadow

# -------------------------
# 9. Malware and Rootkit Scan
# -------------------------
echo "[+] Installing and scanning with ClamAV and rkhunter..."
apt install clamav rkhunter -y
freshclam
clamscan -r /home --bell -i
rkhunter --update
rkhunter --check --sk

# -------------------------
# 10. Logging and Auditing
# -------------------------
echo "[+] Installing and enabling auditd..."
apt install auditd -y
systemctl enable auditd
systemctl start auditd

echo "[+] Setup complete. Please manually verify:"
echo "    - Users and groups"
echo "    - Installed packages (dpkg -l)"
echo "    - Running services (systemctl list-units --type=service --state=running)"
echo "    - SSH and firewall rules"

echo "[✔] CyberPatriot Mint Hardening Complete!"
