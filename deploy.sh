#!/bin/bash
# ==============================================
# HNG13 Stage 1 - Auto Deployment Script
# Author: Chisom.N
# ==============================================

# --- Error handling ---
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# --- Logging ---
LOG_FILE="deploy.log"
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- User Inputs ---
read -rp "Enter Git Repository URL: " GIT_REPO
[[ -z "$GIT_REPO" ]] && echo "Git repo cannot be empty" && exit 1

read -rp "Enter Personal Access Token (PAT): " PAT
[[ -z "$PAT" ]] && echo "PAT cannot be empty" && exit 1

read -rp "Enter Branch name (default: main): " BRANCH
BRANCH=${BRANCH:-main}

read -rp "Enter SSH Username: " SSH_USER
[[ -z "$SSH_USER" ]] && echo "SSH username cannot be empty" && exit 1

read -rp "Enter Server IP Address: " SERVER_IP
[[ -z "$SERVER_IP" ]] && echo "Server IP cannot be empty" && exit 1

read -rp "Enter SSH Key Path (e.g., ~/.ssh/id_rsa): " SSH_KEY
[[ ! -f "$SSH_KEY" ]] && echo "SSH key not found" && exit 1

read -rp "Enter Application Port (container internal port): " APP_PORT
[[ -z "$APP_PORT" ]] && echo "Port cannot be empty" && exit 1

log "All parameters collected successfully"

# --- SSH connectivity check ---
log "Checking SSH connectivity to $SERVER_IP..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "echo SSH connection OK"

# --- Server Preparation ---
log "Preparing server..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "
  # Update packages
  sudo apt-get update -y
  sudo apt-get upgrade -y

  # Install Docker if missing
  if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
  fi

  # Install Docker Compose if missing
  if ! command -v docker-compose &> /dev/null; then
    sudo apt-get install -y docker-compose
  fi

  # Install Nginx if missing
  if ! command -v nginx &> /dev/null; then
    sudo apt-get install -y nginx
  fi

  # Ensure Docker service is running
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo systemctl enable nginx
  sudo systemctl start nginx
"

# --- Git operations & deployment ---
log "Deploying application with Docker..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "
  REPO_DIR=\$(basename $GIT_REPO .git)

  # Clone or pull repository
  if [ -d \"\$REPO_DIR\" ]; then
    cd \$REPO_DIR
    git fetch
    git checkout $BRANCH
    git pull origin $BRANCH
  else
    git clone -b $BRANCH https://$PAT@${GIT_REPO#https://}
    cd \$REPO_DIR
  fi

  # Stop existing container if running
  if docker ps -q --filter name=auto_deploy_app | grep -q .; then
    docker stop auto_deploy_app
    docker rm auto_deploy_app
  fi

  # Run container
  docker run -d --name auto_deploy_app -p $APP_PORT:$APP_PORT -v \$(pwd):/app node:18 bash -c 'npm install && npm start'
"

# --- Configure Nginx ---
log "Configuring Nginx reverse proxy..."
NGINX_CONF="
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
"
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "echo \"$NGINX_CONF\" | sudo tee /etc/nginx/sites-enabled/app_$APP_PORT.conf > /dev/null"
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "sudo nginx -t && sudo systemctl reload nginx"

# --- Deployment Validation ---
log "Validating deployment..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "
  if docker ps | grep -q auto_deploy_app; then
    echo 'Docker container running ✅'
  else
    echo 'Docker container NOT running ❌' && exit 1
  fi

  if curl -s http://localhost:$APP_PORT >/dev/null; then
    echo 'Application responding ✅'
  else
    echo 'Application NOT responding ❌' && exit 1
  fi

  if sudo systemctl is-active nginx | grep -q active; then
    echo 'Nginx running ✅'
  else
    echo 'Nginx NOT running ❌' && exit 1
  fi
"

log "Deployment completed successfully!"

