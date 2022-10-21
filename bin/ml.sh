#!/bin/bash

# SETTINGS FOR THIS FILE ARE IN `config`
# CHANGE THIS FILE ONLY IF YOU ARE CHANGING THE LOGIC

##################################################################
# This protects against not being able to locate the `config` file.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/config.sh

EXT=marcauth-to-madsrdf

# Load files to REST API modules datbase.
for FILE in $DIR/../src/*/*.xqy; 
do 
    extPath=${FILE/$DIR\/..\/src//$EXT}
    curl --anyauth --user $MLUSER:$MLPASS -X PUT -s -d @$FILE -H "Content-type: application/xquery" $MLHOSTPORT/v1/ext$extPath
done
curl --anyauth --user $MLUSER:$MLPASS -X PUT -s -d @$DIR/../src/constants.xqy -H "Content-type: application/xquery" $MLHOSTPORT/v1/ext/$EXT/constants.xqy
curl --anyauth --user $MLUSER:$MLPASS -X PUT -s -d @$DIR/../process/ml-rest-eval.xqy -H "Content-type: application/xquery" $MLHOSTPORT/v1/config/resources/$EXT

# Execute conversion
curl --anyauth --user $MLUSER:$MLPASS -X GET "$MLHOSTPORT/v1/resources/$EXT?rs:marcxmluri=$MARCXMLFILE"

# Tear down ext stuff.
curl --anyauth --user $MLUSER:$MLPASS -X DELETE -s $MLHOSTPORT/v1/config/resources/$EXT
curl --anyauth --user $MLUSER:$MLPASS -X DELETE -s $MLHOSTPORT/v1/ext/$EXT/
