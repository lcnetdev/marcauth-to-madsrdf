#!/bin/bash

MARCXMLFILE=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#### 
# THESE VALUES WILL BE SPECIFIC TO YOUR ENVIRONMENT
####

JAVA_HOME=$DIR/../../rectoenv/opt/jdk-14.0.2
JAVA_BIN=$JAVA_HOME/bin/java.exe
SAXONHE=$DIR/../../rectoenv/opt/saxon/saxon-he-10.1.jar

