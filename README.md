# HNG13 Stage 1 — Automated Deployment Script

**Author:** Chisom Nwafor    
**Task:** HNG13 Stage 1 — DevOps Internship  

---

## 🌟 Overview

This project provides an **automated Bash script (`deploy.sh`)** that sets up, deploys, and configures a **Dockerized Node.js application** on a remote Linux server.  

The script handles environment preparation, application deployment, reverse proxy configuration using Nginx, and automated logging to ensure a smooth, reliable, and repeatable deployment process.

---

## ⚙️ Features

- Automated setup and deployment of a Dockerized Node.js app.  
- Secure GitHub repository cloning using a Personal Access Token (PAT).  
- Automatic installation of Docker, Docker Compose, and Nginx on the server.  
- Configuration of Nginx as a reverse proxy to expose the app.  
- Logging and error handling for visibility and reliability.  
- Idempotent: safe to re-run without affecting the existing setup.    

---

## 🖥 Requirements

- Remote Linux server (Ubuntu recommended) with SSH access and sudo privileges.  
- Dockerized Node.js project containing at least a `package.json` and an entry file (e.g., `index.js`).  
- GitHub Personal Access Token (PAT) for repository access.  
- SSH key for remote server access.  

---

## 📂 Repository Structure

.
├── deploy.sh
├── README.md
├── (Optional) Dockerfile
├── (Optional) docker-compose.yml


---

## 📝 Notes

- Designed for reliability and repeatability, with automated error handling and logging.  
- Idempotent deployment ensures safe reruns without breaking existing services.  
- Portable across Linux servers and adaptable for similar Dockerized applications.  

---

**Author:** Chisom Nwafor  
**GitHub Repository:** [https://github.com/username/auto-deploy-script-hng13-stage1](https://github.com/username/auto-deploy-script-hng13-stage1)
