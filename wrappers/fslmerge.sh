 #! /bin/bash

 FSLDIR="/usr/local/fsl-4.1.0_64bit"
 PATH=${FSLDIR}/bin:${PATH}
 export FSLDIR PATH
 source $FSLDIR/etc/fslconf/fsl.sh
 export LD_LIBRARY_PATH="/usr/local/gcc-4.2.2_64bit/lib64:/usr/local/gcc-4.2.2_64bit/lib"
 $FSLDIR/bin/fslmerge  $@

 exit $?
