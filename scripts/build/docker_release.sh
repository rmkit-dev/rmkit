OUTDIR=artifacts
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmharmony /bin/bash << COMMANDS
mkdir -p src/build
make
cp -r src/build/* /mnt/artifacts
sha256sum src/build/*.exe > /mnt/artifacts/sha256sum.txt
ls -la src/build/ > /mnt/artifacts/ls.txt
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

