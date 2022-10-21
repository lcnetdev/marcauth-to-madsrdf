#!/bin/bash

# SETTINGS FOR THIS FILE ARE IN `config`
# CHANGE THIS FILE ONLY IF YOU ARE CHANGING THE LOGIC

##################################################################
# This protects against not being able to locate the `config` file.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/config.sh

$JAVA_BIN -cp $SAXONHE net.sf.saxon.Query -q:$DIR/../process/saxon.xqy marcxmluri=$MARCXMLFILE model=$MODEL

