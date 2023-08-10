#!/bin/bash

ICONSH=src/harmony/app/icons.h

echo "#ifndef ICONS_H" > ${ICONSH}
echo "#define ICONS_H" >> ${ICONSH}
echo "namespace icons {" >> ${ICONSH}

for ICON in $(ls src/vendor/icons/fa/*.png); do
  xxd -i ${ICON} | sed 's/src_//'>> ${ICONSH}
done

echo "};" >> ${ICONSH}
echo "#endif" >> ${ICONSH}
