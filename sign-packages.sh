#!/bin/bash

for f in *.deb; do 
#	echo "Processing $f file.."; 
	dpkg-sig --sign builder ${f}
done
