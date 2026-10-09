
for file in * ; do echo $file ; mv "${file}" `echo $file | sed -e 's/ /_/g'` ; done

