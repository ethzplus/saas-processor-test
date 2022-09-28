#!/bin/bash

if [ "$1" == "default" ]; then
	echo "Run processor.r on $2"
	Rscript MainScript.R $2

else
	exit 1
fi


