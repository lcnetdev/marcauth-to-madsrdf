#!/bin/bash

MARCXMLFILE=$1
MODEL=$2
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#### 
# THESE VALUES WILL BE SPECIFIC TO YOUR ENVIRONMENT
####

JAVA_HOME=$DIR/../../rectoenv/opt/jdk-14.0.2
JAVA_BIN=$JAVA_HOME/bin/java.exe
SAXONHE=$DIR/../../rectoenv/opt/saxon/saxon-he-10.1.jar

if [ "$MARCXMLFILE" == "" ]
then
  echo "\MARCXML file not specified.  Please specify a MARCXML file."
  exit 0
fi

if [ -f "$DIR/../$MARCXMLFILE" ];
then
    MARCXMLFILE=$DIR/../$MARCXMLFILE
fi

if [ "$MODEL" == "" ]
then
  MODEL=madsrdf
fi