#!/bin/bash
# Setup a Debian or Ubuntu Virtual Private Server (VPS) hosted in Hetzner
# This script follows the guidelines recommended by Hetzner:
#  - https://community.hetzner.com/tutorials/setup-ubuntu-20-04
#
# This script is developed for Debian 12 and Ubuntu 20.04+.
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# Default username
ADMIN_USER="${2:-sysadmin}"

if [ -z "$1" ] || [ "$1" != "--confirm" ]; then
    echo "ATTENTION!!"
    echo "This command will disable password authentication and root login."
    echo "This means that once you logout from the current session you will no longer be able to login again as root."
    echo "After running make sure you can login with the newly created $ADMIN_USER user BEFORE closing this session."
    echo ""
    echo "Usage: $0 --confirm [username]"
    echo "  username: Optional. Name for admin user (default: sysadmin)"
    echo ""
    echo "If you understand this, execute the command with --confirm argument."
    exit 1
fi

if [ ! -f id_ed25519.pub ]; then
    echo -e "${RED}This script will create a $ADMIN_USER account. A file named id_ed25519.pub with the public key for this user needs to exist in this directory.${RESET}"
    echo -e "${RED}Exiting...${RESET}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo -e "${RED}Unable to detect OS. /etc/os-release not found.${RESET}"
    exit 1
fi

if [[ "$OS" != "debian" && "$OS" != "ubuntu" ]]; then
    echo -e "${RED}This script only supports Debian and Ubuntu. Detected OS: $OS${RESET}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS $OS_VERSION${RESET}"

update_apt() {
    echo -e "${GREEN} Updating apt-get repository and upgrading the system...${RESET}"
    apt-get update -qq
    apt-get upgrade -qq
}

setup_firewall() {
  echo -e "${GREEN}Installing firewall and opening only ports 1222 (ssh), 80 and 443... ${RESET}"
  apt-get install ufw -qq
  ufw default deny incoming
  ufw allow 1222/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw enable
}

setup_ssh_daemon() {
  echo -e "${GREEN}Disabbling password authentication, root login and changing SSH port to 1222...${RESET}"
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  # prohibit-password is Debian's default
  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
  # Ubuntu uses 'yes' as default
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i 's/#Port 22/Port 1222/' /etc/ssh/sshd_config
  systemctl restart ssh
}

setup_fail2ban() {
  echo -e "${GREEN}Installing and enabling fail2ban (using default configs)...${RESET}"
  apt-get install fail2ban -qq
  
  if [ "$OS" = "debian" ]; then
    # For Debian 12 install: https://github.com/fail2ban/fail2ban/issues/3292#issuecomment-1678844644
    # This should no longer be necessary in the next 1.1.1 release: https://github.com/fail2ban/fail2ban/commit/d0d07285234871bad3dc0c359d0ec03365b6dddc
    apt-get install python3-systemd -qq
  fi
  
  echo -e "[sshd]\nbackend=systemd\nenabled=true" | sudo tee /etc/fail2ban/jail.local
  systemctl enable fail2ban
  systemctl start fail2ban
}

setup_logwatch() {
  echo -e "${GREEN}Installing and enabling logwatch (using default configs)...${RESET}"
  apt-get install logwatch -qq
}

install_utils() {
  echo -e "${GREEN}Installing util tools: htop, vim, git, build-essential, devscripts, iproute2...${RESET}"
  apt-get install htop vim git build-essential devscripts iproute2 -qq
}

add_sysadmin_user() {
  echo -e "${GREEN}Adding a $ADMIN_USER user with sudo permission...${RESET}"
  adduser $ADMIN_USER
  usermod -aG sudo $ADMIN_USER
  mkdir /home/$ADMIN_USER/.ssh
  echo -e "${GREEN}Adding the id_ed25519.pub key to authorized_keys file of $ADMIN_USER user...${RESET}"
  cat id_ed25519.pub >> /home/$ADMIN_USER/.ssh/authorized_keys
  
  echo -e "${GREEN}Installing and setting zsh as default shell for $ADMIN_USER...${RESET}"
  apt-get install zsh -qq
  chsh -s $(which zsh) $ADMIN_USER
}

finish_message() {
  echo -e "${GREEN}Configuration Finished!! Before closing this session check that you can ssh in using port 1222 with the newly created $ADMIN_USER account.${RESET}"
}

install_docker() {
  echo -e "${GREEN}Installing latest version of docker...${RESET}"
  # Commands extracted from official documentation:
  # https://docs.docker.com/engine/install/debian/#install-using-the-repository
  # https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
  apt-get update -qq
  apt-get install ca-certificates curl -qq
  install -m 0755 -d /etc/apt/keyrings
  
  if [ "$OS" = "debian" ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
  else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi
  
  apt-get update -qq
  apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -qq

  echo -e "${GREEN}Adding $ADMIN_USER user to docker group...${RESET}"
  usermod -aG docker $ADMIN_USER
}

unattended_upgrades() {
  # Install and enable unattended-upgrades for automatic security upgrades.
  # https://wiki.debian.org/PeriodicUpdates?action=show&redirect=UnattendedUpgrades
  echo -e "${GREEN}Ensuring unattended-upgrades is installed and running...${RESET}"
  apt-get install unattended-upgrades -qq
  dpkg-reconfigure -f noninteractive unattended-upgrades
}

main () {
    update_apt
    setup_firewall
    setup_ssh_daemon
    setup_fail2ban
    setup_logwatch
    install_utils
    add_sysadmin_user
    install_docker
    unattended_upgrades
    finish_message
}

main
