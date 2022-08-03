#!/bin/bash

if [ "$1" == "default" ]; then
	echo "Install R dependencies"
	Rscript ./install_dep.R

	exit 0

else
	exit 1
fi


