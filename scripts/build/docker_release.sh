OUTDIR=artifacts
mkdir ${OUTDIR}
docker run -i --rm -v ${PWD}/${OUTDIR}:/mnt/artifacts rmharmony /bin/bash << COMMANDS
mkdir -p src/build
make rmkit.h
make bundle
cp -r src/build/* /mnt/artifacts
ls -la artifacts/ > /mnt/artifacts/ls.txt
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

