# run with wget -O- https://raw.githubusercontent.com/rmkit-dev/rmkit/master/scripts/run/install_harmony.sh -q | bash -

killall remux.exe
killall harmony.exe
rm harmony-release.zip
wget https://build.rmkit.dev/master/latest/release.zip -O harmony-release.zip
yes | unzip harmony-release.zip

cp /home/root/apps/remux.service /etc/systemd/system/remux.service
systemctl enable --now remux
systemctl disable --now xochitl
