# Todo Application

A full-stack todo application with Flask backend and basic frontend.

## Project Structure

```
todo-app/
├─ backend/            # Flask backend
│  ├─ app.py          # Main application file
│  ├─ models.py       # Database models
│  ├─ routes.py       # API routes
│  ├─ auth.py         # Authentication
│  ├─ config.py       # Configuration
│  ├─ requirements.txt
│  ├─ Dockerfile
│  ├─ gunicorn.service
│  └─ tests/
│     └─ test_basic.py
├─ frontend/          # Frontend
│  └─ index.html
├─ docker-compose.yml # Docker configuration
├─ .github/workflows/ # CI/CD
│  └─ ci.yml
└─ README.md
```

## Setup

1. Clone the repository
2. Install backend dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

3. Run the application with Docker

    - Using docker-compose (recommended):
       ```powershell
       docker-compose up --build
       ```

    - Or run the backend image directly. Windows PowerShell requires different line continuation than Bash. Example single-line (PowerShell):
       ```powershell
       docker run --rm -p 5000:5000 -e "DATABASE_URL=sqlite:///todo.db" -e "JWT_SECRET_KEY=devjwt" todo-backend:latest
       ```

    - Multi-line PowerShell form (use backtick ` as continuation):
       ```powershell
       docker run --rm -p 5000:5000 `
          -e "DATABASE_URL=sqlite:///todo.db" `
          -e "JWT_SECRET_KEY=devjwt" `
          todo-backend:latest
       ```

    - If the image doesn't exist locally, build it from the backend folder first:
       ```powershell
       docker build -t todo-backend:latest ./backend
       docker run --rm -p 5000:5000 -e "DATABASE_URL=sqlite:///todo.db" -e "JWT_SECRET_KEY=devjwt" todo-backend:latest
       ```

## Development

- Backend runs on port 5000
- Frontend is served through Nginx on port 80
- Tests can be run with `pytest` in the backend directory

## Features

- Todo CRUD operations
- User authentication
- Docker containerization
- CI/CD with GitHub Actions

## Deployment: EC2 (Ubuntu) — Gunicorn + systemd + Nginx

This repo includes deploy helper files under `backend/deploy/` and an example `.env` at `backend/.env.example`.

Quick steps to deploy on an Ubuntu EC2 instance (replace values as needed):

1. SSH to EC2:
```bash
ssh -i yourkey.pem ubuntu@<EC2_PUBLIC_IP>
```

2. On the EC2 instance you can run the included helper script (reads `backend/.env`):
```bash
# on the EC2 instance
cd /home/ubuntu
# fetch/clone the repo (script will clone if missing)
bash backend/deploy/deploy_ec2.sh
```

3. The script will:
- install python3, venv, nginx, git
- clone or update the repo
- create and activate a venv and install requirements
- copy `backend/deploy/gunicorn.service` to `/etc/systemd/system/gunicorn.service` and start/enable it
- copy `backend/deploy/nginx_todo` to `/etc/nginx/sites-available/todo` and enable it
- create DB tables (runs a simple create_all)

4. Before re-running the script, edit `/home/ubuntu/todoapp/backend/.env` with production values (DATABASE_URL, JWT_SECRET_KEY, SECRET_KEY). You can copy `.env.example`.

5. Check services and logs:
```bash
sudo systemctl status gunicorn
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log
```

Files provided in repo (copy/paste-ready):
- `backend/deploy/gunicorn.service` — systemd unit
- `backend/deploy/nginx_todo` — nginx site config (enable by copying to `/etc/nginx/sites-available/todo`)
- `backend/deploy/deploy_ec2.sh` — convenience script to bootstrap deployment
- `backend/.env.example` — example environment variables

If you want, I can:
- Customize the `gunicorn.service` user/group to a non-ubuntu account (recommended for production)
- Add `ufw` firewall commands and Certbot automation for TLS
- Help you run the commands interactively and troubleshoot any errors you see on the server