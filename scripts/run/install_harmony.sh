# run with wget -O- https://raw.githubusercontent.com/rmkit-dev/rmkit/master/scripts/run/install_harmony.sh -q | bash -

killall remux.exe
killall harmony.exe
rm rmkit-release.zip
wget https://build.rmkit.dev/stable/latest/release.zip -O rmkit-release.zip
yes | unzip rmkit-release.zip

cp /home/root/apps/remux.service /etc/systemd/system/remux.service
systemctl enable --now remux
