#!/bin/bash


myUprDIR=$(cd "$(dirname ${BASH_SOURCE[0]})/.." && pwd)
if [  -n "$msInst" ] && [  "$PATH" == *"$msInst/bin"* ]; then
	echo "Info: msSrc(=$msSrc) is NOT reset from $myUprDIR"
	if [ "$msSrc" != "$myUprDIR" ]; then
		echo "Hint, try reseting your (terminal) session and its settings";
	fi
else

	export msSrc="$myUprDIR"
	export msRoot=$( cd "$msSrc/../" && pwd )
	export msInst=$( cd "$msSrc/../" && pwd )
	[ "$msInst" != "$HOME" ] || ! echo "Bad msInst: $msInst, put apps inside another subfolder and try again" || return
	export msBinDir=$msInst/bin
	export msLibDir=$msInst/lib
	export msIncDir=$msInst/include
	export msBilDir=$msInst/build
	export msTstDir=$msInst/test

	# maybe safer to prepend PATHs?
	export PATH=$PATH:$msSrc/script
	export PATH=$PATH:$msSrc/porefoam1f/script
	export PATH=$PATH:$msSrc/porefoam2f/script
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$msLibDir
	export PATH=$PATH:$msBinDir


	export PATH=$PATH:$msBinDir/foamx4m
	export FOAM_ABORT=1

	export PYTHONPATH=$msSrc/script:$msSrc/pylib:$PYTHONPATH

	if ! [ -d $msBinDir ]; then
		mkdir -p $msBinDir;
		mkdir -p $msLibDir;
		mkdir -p $msIncDir;
	fi

fi
