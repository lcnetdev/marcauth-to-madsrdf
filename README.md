# MARC Authorities to MADS/RDF RDF/XML 

This is an xquery utility to convert MARC/XML Authority records to MADS/RDF and 
SKOS resources.

The principle elements of this repository are the XQuery modules for converting
MARC Authority MARC/XML to MADS/RDF and MADS/RDF to SKOS.  Or both.

Additionally, it comes with a few helper executables to use this code with 
Saxon, BaseX, or MarkLogic.

Warning:  The conversion modules themselves are direct/exact copies of the
code running behind ID.LOC.GOV.  As such, the conversions are specific to 
our (LC's) needs and the specific application into which the resulting transforms
are loaded.  It should be relatively easy to take the output from the conversions 
and remove unwanted information or swap out URIs.

## Running

First, set up 'config.sh':

```bash
cp bin/config-default.sh bin/config.sh
```

Modify `config.sh` to add location of JAVA_HOME and details about chosen
executable.  For Saxon, this is the location of the Saxon Jar.  For MarkLogic,
the HTTP end point.

Next, generically, the commands take the following form:

```bash
./bin/{executable}.sh {marcxml-file} {model}
```

`marcxml-file` is required.  It can be an absolute path, relative path, or HTTP 
location.

`model` is optional.  Possible values are 'madsrdf' or 'skos' or 'all'. Default is
'madsrdf'.

### Examples

**Saxon**

```bash
./bin/saxon.sh https://id.loc.gov/authorities/names/n94033669.marcxml.xml
./bin/saxon.sh https://id.loc.gov/authorities/names/n94033669.marcxml.xml skos
```

**BaseX**

```bash
./bin/basex.sh data/no2021084916.marcxml.xml skos
```

**MarkLogic**

*Warning*: The MarkLogic bash script in this package will write to a REST API modules 
database. Each time it is run, it will add xquery files to the REST API modules
database and delete them afterwards. This is a write/read/delete operation to a 
database; bear this in mind.

Correct MarkLogic connection information needs to be defined in `config.sh`.  

```bash
./bin/ml.sh https://id.loc.gov/authorities/subjects/sh94003571.marcxml.xml
```

It is also possible to load the modules under `src` and the `process/ml-appserver.xqy` 
to a modules database of your choosing. After which it can be accessed via a URL 
like: http://hostname:port/ml-appserver.xqy?marcxmluri=http://location/of/marcxml.xml&model=both

## Changes

    Oct 21 2022
        Wholesale refactored repository.
        Copied, in all LC-specific glory, actual conversion files used behind ID.LOC.GOV.
        Zorba support discontinued. RIP Zorba.
        baseuri no longer supported.

    Nov 30 2012
        Added missed subfields for Title output
        Added support for Zorba
        baseuri must be set externally for Saxon (and Zorba).
        Small modification to MARCXML-2-MADSRDF to work with Zorba (original code caused seg fault)
	
    April 2012
        Initial publication.  Support for MarkLogic and Saxon

## License
As a work of the United States government, this project is in the
public domain within the United States.

Additionally, we waive copyright and related rights in the work
worldwide through the CC0 1.0 Universal public domain dedication. 

[Legal Code (read the full text)](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

You can copy, modify, distribute and perform the work, even for commercial
purposes, all without asking permission.
