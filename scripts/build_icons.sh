#!/bin/bash

ICONSH=okp/ui/icons.h

echo "#ifndef ICONS_H" > ${ICONSH}
echo "#define ICONS_H" >> ${ICONSH}
echo "namespace icons {" >> ${ICONSH}
echo "struct Icon { unsigned char* data = NULL; unsigned int len = 0; const char* name = NULL;};" >> ${ICONSH}

for ICON in $(ls vendor/icons/fa/*.png); do
  xxd -i ${ICON} >> ${ICONSH}
done

echo "};" >> ${ICONSH}
echo "#endif" >> ${ICONSH}
