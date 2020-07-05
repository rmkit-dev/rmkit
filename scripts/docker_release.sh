OUTDIR=artifacts
mkdir ${OUTDIR}
docker run -i --rm -v ${PWD}/${OUTDIR}:/mnt/artifacts rmharmony /bin/bash << COMMANDS
make compile_arm
make bundle
cp -r build/* /mnt/artifacts
ls -la > /mnt/artifacts/ls.txt
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

