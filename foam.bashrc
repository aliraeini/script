#!/bin/bash
set -e

[ -n "$msBinDir" ] || echo source $(dirname "${BASH_SOURCE[0]}")/../bashrc
[ -n "$msBinDir" ] || source $(dirname "${BASH_SOURCE[0]}")/../bashrc
echo "msBinDir: $msBinDir"

if [ -z "$WM_PROJECT" ] ; then
	# Openfoam settings:
	# Change according to your openfoam installation directory
	#export WM_NCOMPPROCS=28
	#export FOAM_INST_DIR=$(cd $myUpperDIR/../pkgs && pwd)
	export FOAM_INST_DIR=$msRoot/pkgs
	source $FOAM_INST_DIR/foamx4m/etc/bashrc
elif [[ "$WM_PROJECT_DIR" != "$msRoot/"*"/foamx4m" ]]; then
	printf "\n *** Using OpenFOAM:  $WM_PROJECT_DIR"
	printf "\n *** If you meant to use foamx4m instead, deactivate this and re-source in a new terminal.\n\n"
fi


# directory of single-phase script and base cases:
SP_SCRIPTS=$msSrc/porefoam1f/script
export SP_SCRIPTS
# directory of two-phase script and base cases:
TWOPHASE_SCRIPTS=$msSrc/porefoam2f/script
export TWOPHASE_SCRIPTS


## run an app and redirect output to log file   -------------------------
runApp() {
    LOG_NAME=
    while getopts "l:" OPTFLAG ; do
        LOG_NAME=$OPTARG
        shift $((OPTIND-1)) ; OPTIND=1
    done

    APP_RUN=$1; shift
    APP_NAME=${APP_RUN##*/}

    if [ -z $LOG_NAME ] ; then
        LOG_NAME=log.$APP_NAME
    fi

    ErCd=127
    if [ -f $LOG_NAME ] ; then
        echo "$APP_NAME already run on $PWD: remove log file to run:"
        echo "  rm $PWD/$LOG_NAME"
    else
        echo "Running $APP_NAME $@  >  $PWD/$LOG_NAME"
        nice $APP_RUN "$@" > $LOG_NAME 2>&1
        ErCd=$?
        [[ $ErCd == 0 ]] || echo "Error: $APP_RUN  $@,  exit status: $ErCd, see $(pwd)/$LOG_NAME"
    fi
    sleep .1
    return $ErCd
}

# (Single-node) parallel run
runMPI() {
    LOG_NAME=
    while getopts "l:" OPTFLAG ; do
        LOG_NAME=$OPTARG
        shift $((OPTIND-1)) ; OPTIND=1
    done

    APP_RUN=$1; shift
    np=$1; shift
    APP_NAME=${APP_RUN##*/}

    if [ -z $LOG_NAME ] ; then
        LOG_NAME=log.$APP_NAME
    fi

    ErCd=127
    if [ -f $LOG_NAME ] ; then
        echo "$APP_NAME already run on $PWD: remove log file to run:"
        echo "  rm $PWD/$LOG_NAME"
    elif [ "$np" == "1" ] ; then
        echo "Running $APP_NAME $@  >  $PWD/$LOG_NAME"
        nice  $APP_RUN "$@" > $LOG_NAME 2>&1
    else
        echo "Running $APP_NAME $@  >  $PWD/$LOG_NAME , using $np processes"
        # --bind to none ( mpirun -x LD_LIBRARY_PATH -x PATH -x WM_PROJECT_DIR -x WM_PROJECT_INST_DIR -x MPI_BUFFER_SIZE         --mca btl_tcp_if_exclude lo --mca btl_tcp_if_exclude eth0:avahi  --hostfile  machines.txt -np $np $APP_RUN  -parallel "$@" < /dev/null > $LOG_NAME 2>&1 )
        nice mpirun.openmpi  -np $np $APP_RUN -parallel "$@" < /dev/null > $LOG_NAME 2>&1
        ErCd=$?
        [[ $ErCd == 0 ]] || echo "Error: $APP_RUN -parallel $@,  exit status: $ErCd, see $(pwd)/$LOG_NAME"
    fi
    sleep .1
    return $ErCd
}

# Multi-node parallel run with nodes set in machines.txt
runDistributed() {
    LOG_NAME=
    while getopts "l:" OPTFLAG ; do
        LOG_NAME=$OPTARG
        shift $((OPTIND-1)) ; OPTIND=1
    done

    APP_RUN=$1; shift
    np=$1; shift
    APP_NAME=${APP_RUN##*/}

    if [ -z $LOG_NAME ] ; then
        LOG_NAME=log.$APP_NAME
    fi

    ErCd=127
    if [ -f $LOG_NAME ] ; then
        echo "$APP_NAME already run on $PWD: remove log file to run:"
        echo "$PWD/$LOG_NAME"
    else
        echo "Running $APP_NAME $@  >  $PWD/$LOG_NAME , using $np processes"
        nice mpirun.openmpi -x LD_LIBRARY_PATH -x PATH -x WM_PROJECT_DIR -x WM_PROJECT_INST_DIR -x MPI_BUFFER_SIZE \
          --mca btl_tcp_if_exclude lo,eth0:avahi --hostfile $SP_SCRIPTS/machines.txt \
          -np $np $APP_RUN  -parallel "$@" < /dev/null > $LOG_NAME 2>&1
        ErCd=$?
        [[ $ErCd == 0 ]] || echo "Error: $APP_RUN -parallel $@,  exit status: $ErCd, see $(pwd)/$LOG_NAME  {" >&2
        [[ $ErCd == 0 ]] || (tail -20 $(pwd)/$LOG_NAME  >&2 ; printf ' } #: tail of log\n\n' >&2)
    fi
    sleep .1
    return $ErCd
}


### OpenFOAM dictionary helpers  ---------------------------------------


setKeywordValues()  {  sed -i 's:^[ \t]*'"$1"'[ \t:].*$:'"    $1   $2; "':g' $3;  }

addSetKeyValue() {
   ( grep -q -G "^[ \t]*$1" $3 && sed -i 's:^[ \t]*'"$1"'[ \t:].*$:'" $1     $2 ;"':g' $3 ) \
   || echo " $1     $2 ;"  >> $3
}

setSubKeywordValues()  {  sed -i '/'"$1"'/,/\}/s/^[ \t]*'"$2"'[ \t].*$/'"       $2   $3; "'/' $4 ; }
setBoundaryCondition() {  sed -i '/'"$1"'/,/\}/s/^[ \t]*'"$2"'[ \t].*$/'"       $2   $3; "'/' $4 ; }

setValues() {   sed -i 's/'"$1"'/'"$2"'/g' $3 ; }

deleteFromBC()  {  sed -i '/'"$1"'/,/\}/s/^'"$2"'.*$/\/\/'" $2   "'/' $3;  }


setfirstKeywordValue()  {  sed -i '0,/^[ \t]*'"$1"' .*$/s//'" $1  $2; "'/' $3 ;  }


setParallelBC()  {  sed -i '/'"$1"'/,/\}/s/'"$2"' .*$/'" $2      $3; "'/' $4 ;  }

replaceValues()  {  sed -i 's/'"$1"'/'"$2"'/g' $3 ;  }


deleteKeyword()  {  sed -i '/'"$1"'/,/\;/s/^/\/\//' $2;  }

calc()  {  awk "BEGIN {print $@}"; }

RunRemoveExtras() {
   sleep 0.1
   rm -f  0/ccx  0/ccy  0/ccz
   rm -f  0/cell*  0/point*  0/*Level

   rm -f  constant/polyMesh/*Level
   rm -f  constant/polyMesh/*Zones
   rm -f  constant/polyMesh/*History
   rm -f  constant/polyMesh/*Index
   rm -f  log.faceSet.*
   echo " " ;
}
