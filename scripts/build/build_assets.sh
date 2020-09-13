#!/bin/bash

DEST=${1}
ASSET_DIR="${2}"
SUB_ASSET_DIR=${ASSET_DIR/\//_}

ASSETSH=${DEST}
FILES=`find ${ASSET_DIR} -type f`

echo ${DEST}

echo "#pragma once" > ${ASSETSH}
echo "namespace assets {" >> ${ASSETSH}

for ASSET in ${FILES}; do
  echo "xxd -i ${ASSET} | sed 's/${SUB_ASSET_DIR}//'>> ${ASSETSH}"
  xxd -i ${ASSET} | sed 's/'${SUB_ASSET_DIR}'//g'>> ${ASSETSH}
done

echo "};" >> ${ASSETSH}
