#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

JENKINS_SERVICE="jenkins"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install Java (OpenJDK 11)
install_java() {
    echo "📦 Installing Java (OpenJDK 11)..."
    sudo apt update -y
    sudo apt install -y openjdk-17-jdk fontconfig 
    echo "✅ Java installation complete."
}

# Function to install Jenkins
install_jenkins() {
    echo "📦 Installing Jenkins..."

    sudo wget -4 -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins
    # Enable and start Jenkins service
    sudo systemctl enable $JENKINS_SERVICE
    sudo systemctl start $JENKINS_SERVICE

    echo "✅ Jenkins installation complete."
}

# Function to install Docker
install_docker() {
    echo "📦 Installing Docker..."

    # Remove old Docker versions if installed
    sudo apt remove -y docker docker-engine docker.io containerd runc || true

    # Install dependencies
    sudo apt update -y
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Add Docker repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Update and install Docker
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Add user to the Docker group
    sudo usermod -aG docker $USER

    echo "✅ Docker installation complete."
}

# Function to verify installations
verify_installations() {
    echo "🔍 Verifying installations..."
    echo "✅ Git Version: $(git --version)"
    echo -n "Java Version: " && java -version 2>&1 | head -n 1
    echo -n "Jenkins Status: " && systemctl is-active jenkins
    echo -n "Docker Version: " && docker --version

    echo "✅ All installations verified."
}
# Function to install Git
install_git() {
    echo "📦 Installing Git..."

    # Update package list
    sudo apt update -y

    # Install Git
    sudo apt install -y git

    # Verify installation
    if command_exists git; then
        echo "✅ Git installation complete. Version: $(git --version)"
    else
        echo "❌ Git installation failed!" >&2
        exit 1
    fi
}
# Function to display next steps
next_steps() {
    echo "🚀 Jenkins is now installed and running."
    echo "➡ Access Jenkins at: http://$(curl -s ifconfig.me):8080"
    echo "🔑 Get the initial admin password using:"
    echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}

# Run installation functions
install_java
install_jenkins
install_docker
install_git
verify_installations
next_steps
