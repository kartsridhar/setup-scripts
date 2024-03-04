#!/bin/bash
set -e

# Function to display a spinner
spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf "\r %c " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
  done
  printf "\r"
}

# Function to retry package installation with logging
install_package() {
  pkg_name="$1"
  max_attempts=3
  attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "Installing $pkg_name, attempt $attempt..."
    if sudo apt install -y "$pkg_name" > /dev/null 2>&1 & spinner; then
      echo "$pkg_name installed successfully."
      echo "Package: $pkg_name" >> install.log
      echo "Status: Successfully installed" >> install.log
      echo "---------------------------------------------" >> install.log
      return 0
    else
      echo "Failed to install $pkg_name, attempt $attempt."
      ((attempt++))
      sleep 5
    fi
  done

  echo "Failed to install $pkg_name after $max_attempts attempts."
  echo "Package: $pkg_name" >> install.log
  echo "Status: Installation failed after $max_attempts attempts." >> install.log
  echo "---------------------------------------------" >> install.log
}

# Update and upgrade packages
sudo apt update -y > /dev/null && sudo apt upgrade -y > /dev/null

# Install packages with retry and logging
declare -a packages=("openssh-server" "htop" "net-tools" "curl" "python3-pip" "unzip" "git" "default-jdk")
for pkg in "${packages[@]}"; do
  install_package "$pkg"
done

# Check status, enable, and start SSH service
sudo systemctl status ssh
sudo systemctl enable ssh
sudo systemctl start ssh

# Install AWS CLI v2
attempt=1
max_attempts=3
while [ $attempt -le $max_attempts ]; do
  echo "Installing AWS CLI v2, attempt $attempt..."
  if curl https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install > /dev/null 2>&1 & spinner; then
    echo -e "\rAWS CLI v2 installed successfully."
    rm awscliv2.zip
    echo "Package: AWS CLI v2" >> install.log
    echo "Status: Successfully installed" >> install.log
    echo "---------------------------------------------" >> install.log
    break
  else
    echo -e "\rFailed to install AWS CLI v2, attempt $attempt."
    ((attempt++))
    sleep 5
  fi
done

if [ $attempt -gt $max_attempts ]; then
  echo "Failed to install AWS CLI v2 after $max_attempts attempts."
  echo "Package: AWS CLI v2" >> install.log
  echo "Status: Installation failed after $max_attempts attempts." >> install.log
  echo "---------------------------------------------" >> install.log
fi

# Create ggc_user and ggc_group
sudo adduser --system ggc_user
sudo addgroup --system ggc_group

# Install Docker with retry and logging
attempt=1
while [ $attempt -le $max_attempts ]; do
  echo "Installing Docker, attempt $attempt..."
  if curl -fsSL https://get.docker.com -o get-docker.sh && sudo bash ./get-docker.sh > /dev/null 2>&1 & spinner; then
    echo -e "\rDocker installed successfully."
    rm get-docker.sh
    echo "Package: Docker" >> install.log
    echo "Status: Successfully installed" >> install.log
    echo "---------------------------------------------" >> install.log
    break
  else
    echo -e "\rFailed to install Docker, attempt $attempt."
    ((attempt++))
    sleep 5
  fi
done

if [ $attempt -gt $max_attempts ]; then
  echo "Failed to install Docker after $max_attempts attempts."
  echo "Package: Docker" >> install.log
  echo "Status: Installation failed after $max_attempts attempts." >> install.log
  echo "---------------------------------------------" >> install.log
fi

# Add ggc_user and the current user to the Docker group

sudo usermod -aG docker ggc_user
sudo usermod -aG docker $(whoami)

# Activate changes in group membership

newgrp docker

# Install Nodejs via. nodesource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install nodejs
