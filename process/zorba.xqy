xquery version "3.0";

(:
:   Module Name: MARC/XML Auth 2 MADS RDF/XML using Zorba 
:
:   Module Version: 1.0
:
:   Date: 2012 Nov 30
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: file, http-client, parsexml, opt, output (Zorba)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Displays authority records in a variety 
:       of formats and serializations, based on parameters passed 
:       to the xquery. 
:
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="http://location/of/marcxml.xml" -e model:="all" -e baseuri:="http://base/"
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="../location/of/marcxml.xml" -e model:="all" -e baseuri:="http://base/"
:)

(:~
:   This module displays authority records in a variety of formats
:   and serializations, based on parameters passed to the XQuery.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since November 30, 2012
:   @version 1.0
:)

(: IMPORTED MODULES :)
import module namespace http            =   "http://www.zorba-xquery.com/modules/http-client";
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://www.zorba-xquery.com/modules/xml";
import schema namespace parseoptions    =   "http://www.zorba-xquery.com/modules/xml-options";

import module namespace marcxml2madsrdf = "info:lc/id-modules/marcxml2madsrdf2#" at "../modules/module.MARCXML-2-MADSRDF.xqy";
import module namespace madsrdf2skos    = "info:lc/id-modules/madsrdf2skos#" at "../modules/module.MADSRDF-2-SKOS.xqy";

(: NAMESPACES :)
declare namespace marcxml   = "http://www.loc.gov/MARC21/slim";
declare namespace madsrdf   = "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdf       = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:~
:   This variable is for the base uri for your Authorites/Concepts.
:   It is the base URI for the rdf:about attribute.
:   
:)
declare variable $baseuri as xs:string external;

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string external;

(:~
:   This variable is for desired model.  Expected values are: madsrdf, skos, all
:)
declare variable $model as xs:string external;

let $marcxml := 
    if ( fn:starts-with($marcxmluri, "http://" ) ) then
        let $http-response := http:get-node($marcxmluri) 
        return $http-response[2]
    else
        let $raw-data as xs:string := file:read-text($marcxmluri)
        let $mxml := parsexml:parse(
                    $raw-data, 
                    <parseoptions:options />
                )
        return $mxml
let $marcxml := $marcxml//marcxml:record

let $resources :=
    for $r in $marcxml
    let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($r,$baseuri)
    let $response :=  
        if ($model eq "madsrdf") then
            $madsrdf
        else if ($model eq "skos") then 
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($r,$baseuri)
            return madsrdf2skos:madsrdf2skos($madsrdf)
        else
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($r,$baseuri)
            let $skos := madsrdf2skos:madsrdf2skos($madsrdf)
            let $rdf := 
                if ($madsrdf/child::node()[fn:name()][1]) then
                    element rdf:RDF {
                        element {fn:name($madsrdf/child::node()[fn:name()][1])} {
                            $madsrdf/child::node()[fn:name()][1]/@rdf:about,
                            $madsrdf/child::node()[fn:name()][1]/child::node(),
                            $skos/rdf:Description/child::node()
                        }
                    }
                else
                    <rdf:RDF />
            return $rdf
    return $response/child::node()[fn:name()]
    
return
    element rdf:RDF {
        $resources
    }



