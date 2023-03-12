while true; do
  app="
button 50 50 200 50 option 1
button 250 50 200 50 option 2
label 500 500 200 50 you pressed: ${option}
[paragraph 500 600 500 500 ${output}]
"
  echo "APP IS"
  echo "${app}"
  option=`echo "${app}" | src/build/simple | grep 'selected:' | sed 's/selected: //'`
  output=`cat /etc/os-release`

  sleep 0.1
done
