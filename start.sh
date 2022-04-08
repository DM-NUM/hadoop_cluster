#!/bin/bash

case "$1" in "build")
    docker build -t test_spark -f ./Dockerfile . ;;
"run")    
    docker-compose up ;;
"start")
    docker-compose start ;;
*)
    echo "error: first argument must be up/start" ;;
esac
	
