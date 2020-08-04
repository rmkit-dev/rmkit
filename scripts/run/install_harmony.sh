# run with wget -O- https://raw.githubusercontent.com/raisjn/rmHarmony/master/scripts/install_harmony.sh -q | sh -

killall launcher
killall harmony
rm harmony-release.zip
wget https://github.com/raisjn/rmHarmony/releases/download/v0.0.1/release.zip -O harmony-release.zip
yes | unzip harmony-release.zip

ln -s /home/root/harmony/harmony.service /etc/systemd/system/harmony.service
systemctl enable --now harmony
