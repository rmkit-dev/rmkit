OUTDIR=artifacts
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmharmony /bin/bash << COMMANDS
mkdir -p src/build
make
sha256sum src/build/*.exe > src/build/sha256sum.txt
ls -la src/build/ > src/build/ls.txt
make bundle
cp -r src/build/* /mnt/artifacts
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

