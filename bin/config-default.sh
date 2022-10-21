#!/bin/bash

#### 
# THESE VALUES WILL BE SPECIFIC TO YOUR ENVIRONMENT
# MODIFY THEM AS NEEDED.
####

JAVA_HOME=/path/to/java/directory
JAVA_BIN=$JAVA_HOME/bin/java
SAXONHE=/path/to/saxon/jar

BASEX_EXEC=/path/to/basex/executable

MLHOSTPORT=http://localhost:8000
MLUSER=user
MLPASS=pass

#### 
# THE FOLLOWING CAN BE IGNORED.  THEY ARE COMMON TO ALL THE EXECUTABLES.
####

MARCXMLFILE=$1
MODEL=$2

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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