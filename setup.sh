#!/usr/bin/env bash
# this script is only intended for deployment and not for development (it targets Raspberry Pi hardware)

set -e
BASEDIR=$(dirname "$0")

# set up docker
# based on https://docs.docker.com/engine/install/raspbian/ but we use the debian repo
# because it has arm64 packages (unlike the raspian repo)
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove $pkg || true
done
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg openssl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo groupadd docker || true
sudo usermod -aG docker "${USER}"
# make sure the user inside the docker container has permissions to access files in the shared logs folder
sudo chmod 777 "${BASEDIR}/logs"

# set web interface password (in .htpasswd)
PW_FILE="${BASEDIR}/.htpasswd"

if grep -q "Tux7" "${PW_FILE}"; then
  echo "⚠️ It seems you did not yet set the password of the web interface. This is strongly recommended."
  read -rp "Do you want to do this now? (y/n): " response

  if [[ $response =~ ^[YyjJ]$ ]]; then
      echo -n "Username: "
      read -r user
      echo -n "Password: "
      read -rs password
      hashed_pw=$(openssl passwd -6 "${password}")
      echo "${user}:${hashed_pw}" > "${PW_FILE}"
      printf "\n✅ Web interface password set successfully."
  else
      printf "❌️ Warning: Web interface password not set.\n"
  fi
fi

# activate the changes to groups
newgrp docker
