#!/usr/bin/env bash
# Run this on the EC2 instance as root or via sudo. Designed to be idempotent.
# Usage: sudo bash deploy_ec2.sh
set -euo pipefail

# Edit these if you install to a different path or user
APP_USER=todoapp
APP_HOME=/home/${APP_USER}
REPO_URL=https://github.com/Prabhat-Kr-Sahu/todoapp.git
APP_DIR=${APP_HOME}/todoapp
BACKEND_DIR=${APP_DIR}/backend

echo "==> Updating apt and installing base packages"
apt update
apt install -y python3-pip python3-venv nginx git curl ufw

echo "==> Creating system user '${APP_USER}' (if missing)"
if ! id -u ${APP_USER} >/dev/null 2>&1; then
  adduser --system --group --home ${APP_HOME} --shell /bin/bash ${APP_USER}
  mkdir -p ${APP_HOME}
  chown ${APP_USER}:${APP_USER} ${APP_HOME}
fi

echo "==> Cloning/updating repository into ${APP_DIR} (owner: ${APP_USER})"
if [ ! -d "${APP_DIR}" ]; then
  sudo -u ${APP_USER} git clone ${REPO_URL} ${APP_DIR}
else
  cd ${APP_DIR}
  sudo -u ${APP_USER} git pull
fi

echo "==> Preparing Python virtualenv and installing dependencies"
cd ${BACKEND_DIR}
if [ ! -d venv ]; then
  sudo -u ${APP_USER} python3 -m venv venv
fi
# Install inside the virtualenv as the app user
sudo -u ${APP_USER} ${BACKEND_DIR}/venv/bin/python -m pip install --upgrade pip
sudo -u ${APP_USER} ${BACKEND_DIR}/venv/bin/pip install -r ${BACKEND_DIR}/requirements.txt

echo "==> Ensuring .env exists"
if [ ! -f ${BACKEND_DIR}/.env ]; then
  cp ${BACKEND_DIR}/.env.example ${BACKEND_DIR}/.env
  chown ${APP_USER}:${APP_USER} ${BACKEND_DIR}/.env
  echo "A default .env was created at ${BACKEND_DIR}/.env. Edit it with production values (DATABASE_URL, JWT_SECRET_KEY, SECRET_KEY) and re-run this script." 
  exit 0
fi

echo "==> Installing systemd unit and socket"
cp ${BACKEND_DIR}/deploy/gunicorn.socket /etc/systemd/system/gunicorn.socket
cp ${BACKEND_DIR}/deploy/gunicorn.service /etc/systemd/system/gunicorn.service
chown root:root /etc/systemd/system/gunicorn.socket /etc/systemd/system/gunicorn.service
chmod 644 /etc/systemd/system/gunicorn.socket /etc/systemd/system/gunicorn.service

systemctl daemon-reload

echo "==> Enabling and starting gunicorn socket & service"
systemctl enable --now gunicorn.socket
systemctl enable --now gunicorn.service

echo "==> Installing Nginx site"
cp ${BACKEND_DIR}/deploy/nginx_todo /etc/nginx/sites-available/todo
ln -sf /etc/nginx/sites-available/todo /etc/nginx/sites-enabled/todo
nginx -t
systemctl restart nginx

echo "==> Ensuring runtime socket directory exists and has correct owner"
mkdir -p /run/todoapp
chown ${APP_USER}:www-data /run/todoapp || true

echo "==> Creating DB tables (if using SQLAlchemy create_all) as ${APP_USER}"
sudo -u ${APP_USER} ${BACKEND_DIR}/venv/bin/python - <<'PY'
from app import create_app
from models import db
app = create_app()
with app.app_context():
    db.create_all()
print('DB tables created (if not present)')
PY

echo "==> Optional: Configure firewall (UFW) to allow HTTP/HTTPS and enable it"
if command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH
  ufw allow 'Nginx Full'
  ufw --force enable
fi

echo "==> Optional: If you have a domain, install certbot and obtain a certificate"
echo "If you want certbot automation, install certbot and run: sudo apt install -y certbot python3-certbot-nginx && sudo certbot --nginx -d your-domain.com"

echo "Deployment finished. Check: systemctl status gunicorn.socket, systemctl status gunicorn.service, journalctl -u gunicorn -f, and nginx logs if needed."
