#!/bin/bash

ICONSH=okp/ui/icons.h

echo "namespace icons {" > ${ICONSH}

for ICON in $(ls vendor/icons/fa); do
  xxd -i vendor/icons/fa/${ICON} >> ${ICONSH} 
done

echo "};" >> ${ICONSH}
