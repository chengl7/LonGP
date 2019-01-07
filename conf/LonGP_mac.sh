#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MATLAB Runtime environment for the current $ARCH and executes 
# the specified command.
#
exe_name=$0
exe_dir=`dirname "$0"`
echo "------------------------------------------"
if [ "x$1" = "x" ]; then
  echo Usage:
  echo    $0 LonGP_CMD args
else
  echo LonGP directory:  $exe_dir
  echo Setting up environment variables
  MCRROOT="/Applications/MATLAB_R2018a.app"   #set your MCR installation directory here.
  echo ------------------------------------------
  DYLD_LIBRARY_PATH=.:${MCRROOT}/runtime/maci64 ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/bin/maci64 ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/sys/os/maci64;
  export DYLD_LIBRARY_PATH;
  echo DYLD_LIBRARY_PATH is ${DYLD_LIBRARY_PATH};
  echo ------------Finish------------------------
  echo ""

  cmd=$1
  shift 1
  args=
  while [ $# -gt 0 ]; do
      token=$1
      args="${args} \"${token}\"" 
      shift
  done
  eval "\"${exe_dir}/lonGP.app/Contents/MacOS/${cmd}\"" $args
fi
exit

