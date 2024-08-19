#!/bin/bash

##-- Script to build ec2 AMI for the deployment of client for a LucidLink Filespace
. config_vars.txt
##-- Generate ec2 instance user data file
mkdir -m 777 -p ../files
USRDATAF="build_script.sh"
if [ -e $USRDATAF ]; then
  echo "File $USRDATAF already exists!"
else
  echo "Creating $USRDATAF..."
  touch ../files/$USRDATAF
fi

if [ -w ../files/$USRDATAF ] ; then
     :
else
     echo -e "\e[91mError: write $USRDATAF permission denied.\e[0m"
     exit
fi

echo "FILESPACE1=${FILESPACE1}" > ../files/lucidlink-service-vars1.txt
echo "FSUSER1=${FSUSER1}" >> ../files/lucidlink-service-vars1.txt
echo "ROOTPOINT1=${ROOTPOINT1}" >> ../files/lucidlink-service-vars1.txt
echo -n "${LLPASSWD1}" | base64 >> ../files/lucidlink-password1.txt

# Create build script
cat >../files/build_script.sh <<EOF 
#!/bin/bash

set -x

# Install necessary OS dependencies
sudo echo "deb http://cz.archive.ubuntu.com/ubuntu lunar main universe" >> /etc/apt/sources.list
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt update -y
sudo apt -y -qq install curl wget git vim apt-transport-https ca-certificates xfsprogs

# Setup sudo to allow no-password sudo for "lucidlink" group and adding "lucidlink" user
sudo groupadd -r lucidlink
sudo useradd -M -r -g lucidlink lucidlink
sudo useradd -m -s /bin/bash lucidlink
sudo usermod -a -G lucidlink lucidlink
sudo cp /etc/sudoers /etc/sudoers.orig
echo "lucidlink  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/lucidlink

# Install LucidLink client and configure systemd services
sudo mkdir /client
sudo mkdir /client/lucid
sudo wget -q https://www.lucidlink.com/download/latest/lin64/stable/ -O /client/lucidinstaller.deb && apt install /client/lucidinstaller.deb -y
sudo wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /client/amazon-cloudwatch-agent.deb
sudo dpkg -i -E /client/amazon-cloudwatch-agent.deb
sudo mv /tmp/lucidlink-service-vars1.txt /client/lucid/lucidlink-service-vars1.txt
sudo mv /tmp/lucidlink-1.service /etc/systemd/system/lucidlink-1.service

# Encrypt LucidLink passwords and shred the original base64 plaintext files
LLPASSWORD1=\$(cat /tmp/lucidlink-password1.txt | base64 --decode)
echo -n "\${LLPASSWORD1}" | systemd-creds encrypt --name=ll-password-1 - /client/lucid/ll-password-1.cred &
wait
shred -uz /tmp/lucidlink-password1.txt

# Set permissions and update fuse.conf
sudo mkdir /media/lucidlink/\${FILESPACE1}/
sudo chown -R lucidlink:lucidlink /client/lucid
sudo chmod 700 -R /client/lucid
sudo chmod 400 /client/lucid/ll-password-1.cred
sudo sed -i -e 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
EOF

# Create systemd service files
cat >../files/lucidlink-1.service <<EOF
[Unit]
Description=LucidLink Daemon
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0
[Service]
Restart=on-failure
RestartSec=1
TimeoutStartSec=180
Type=exec
User=lucidlink
Group=lucidlink
WorkingDirectory=/client/lucid
EnvironmentFile=/client/lucid/lucidlink-service-vars1.txt
LoadCredentialEncrypted=ll-password-1:/client/lucid/ll-password-1.cred
ExecStart=/bin/bash -c "/usr/bin/systemd-creds cat ll-password-1 | /usr/bin/lucid --instance 501 daemon --fs \${FILESPACE1} --user \${FSUSER1} --mount-point /media/lucidlink --root-point \${ROOTPOINT1} --root-path /data --config-path /data --fuse-allow-other"
ExecStop=/usr/bin/lucid exit
[Install]
WantedBy=multi-user.target
EOF

echo "EC2 instance build script created: $USRDATAF"

exit 0
