xquery version "1.0";

(:
:   Module Name: View Authority
:
:   Module Version: 1.0
:
:   Date: 2010 Oct 18
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: xdmp (MarkLogic)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Displays authority records in a variety 
:       of formats and serializations, based on parameters passed 
:       to the xquery. 
:)

(:~
:   This module displays authority records in a variety of formats
:   and serializations, based on parameters passed to the XQuery.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since October 18, 2010
:   @version 1.0
:)

(: IMPORTED MODULES :)
import module namespace marcxml2madsrdf = "info:lc/id-modules/marcxml2madsrdf2#" at "modules/module.MARCXML-2-MADSRDF.xqy";
import module namespace madsrdf2skos    = "info:lc/id-modules/madsrdf2skos#" at "modules/module.MADSRDF-2-SKOS.xqy";

(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";

declare namespace marcxml   = "http://www.loc.gov/MARC21/slim";
declare namespace madsrdf   = "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdf       = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:output "indent-untyped=yes" ; 

(:~
:   This variable is for the base uri for your Authorites/Concepts.
:   It is the base URI for the rdf:about attribute.
:   
:)
declare variable $baseuri as xs:string := "http://base-uri/";

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string := xdmp:get-request-field("marcxmluri","");

(:~
:   This variable is for desired model.  Expected values are: madsrdf, skos, all
:)
declare variable $model as xs:string := xdmp:get-request-field("model","madsrdf");

let $marcxml := xdmp:document-get($marcxmluri)/marcxml:record
let $response := 
    if ($model eq "madsrdf") then
        marcxml2madsrdf:marcxml2madsrdf($marcxml,$baseuri)
    else if ($model eq "skos") then 
        let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($marcxml,$baseuri)
        return madsrdf2skos:madsrdf2skos($madsrdf)
    else
        let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($marcxml,$baseuri)
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
        
return $response



