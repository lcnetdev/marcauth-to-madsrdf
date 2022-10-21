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

Generically, the commands take the following form:

`./bin/{executable}.sh {marcxml-file} {model}`

`marcxml-file` is required.  It can be an absolute path, relative path, or HTTP 
location.

`model` is optional.  Possible values are 'madsrdf' or 'skos' or 'all'. Default is
'madsrdf'.

### Examples

Saxon 
`./bin/saxon.sh https://id.loc.gov/authorities/names/n94033669.marcxml.xml`
`./bin/saxon.sh https://id.loc.gov/authorities/names/n94033669.marcxml.xml skos`


ml.xqy - can be used with the MarkLogic Database and Application Server (http://community.marklogic.com/docs).  This expects an HTTP application server.  Set up an application server with the location of this package as the root and (purely as an example) go to 
	http://hostname:port/ml.xqy?marcxmluri=http://location/of/marcxml.xml&model=both&baseuri=http://base-uri/



Parameters (HTTP for ml.xqy; external for saxon.xqy; external for zorba.xqy):

	marcxmluri - Path to MARC/XML file.  File can be retrieved over HTTP (begin http://) or from the filesystem.
	model - expected values are: madsrdf, skos, all
	baseuri - Base URI for generated resources. (For saxon, set within file
	

## Changes

    Oct 21 2022
        Wholesale refactored repository.
        Copied, in all LC-specific glory, actual conversion files used behind ID.LOC.GOV.
        Zorba support discontinued. RIP Zorba.

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
