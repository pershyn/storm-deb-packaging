#!/bin/bash
#find . -type f -name '*.deb' | sed 's@.*/.*\.@.@' | sort | uniq

for f in *.deb; do 
#	echo "Processing $f file.."; 
	dpkg-sig --sign builder ${f}
done
