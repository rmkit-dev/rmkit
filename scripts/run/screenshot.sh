ssh root@10.11.99.1 "cat /dev/fb0" > fb.raw
./scripts/dev/iraw2png.pl < fb.raw > fb.png
