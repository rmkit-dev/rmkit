# run with wget -O- url.sh -q | sh -

wget https://path/to/release.zip
yes | unzip harmony-release.zip
ln -s /home/root/harmony/harmony.service /etc/systemd/system/harmony.service
systemctl enable --now harmony
