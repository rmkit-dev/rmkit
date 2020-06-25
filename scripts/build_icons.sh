#!/bin/bash

ICONSH=okp/ui/icons.h

echo "namespace icons {" > ${ICONSH}
echo "struct Icon { unsigned char* data; unsigned int len; };" >> ${ICONSH}

for ICON in $(ls vendor/icons/fa/*.png); do
  xxd -i ${ICON} >> ${ICONSH}
done

echo "};" >> ${ICONSH}
