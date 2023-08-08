echo "PWD: ${PWD}"
ls src/build/

for app in src/build/*; do
  app_base=`basename ${app}`
  file src/build/${app_base} | grep "ELF 64-bit LSB.* executable, x86-64" > /dev/null
  if [[ $? == 0 ]]; then
    echo "RUNNING ${app_base}..."

    src/build/${app_base} > src/build/${app_base}.out 2>&1 &
    pid=$!
    sleep 5
    kill ${pid} 2>/dev/null
    mv fb.pnm src/build/${app_base}.pnm 2>/dev/null
  fi

done
