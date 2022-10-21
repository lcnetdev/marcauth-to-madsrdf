xquery version "1.0";

(:
:   Module Name: MARC/XML Auth 2 MADS RDF/XML using Saxon 
:
:   Module Version: 1.0
:
:   Date: 2012 April 20
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
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
import module namespace marcxml2madsrdf = "info:lc/id-modules/marcxml2madsrdf#" at "../src/modules/module.MARCXML-2-MADSRDF.xqy";
import module namespace madsrdf2skos    = "info:lc/id-modules/madsrdf2skos#" at "../src/modules/module.MADSRDF-2-SKOS.xqy";

(: NAMESPACES :)
declare namespace saxon = "http://saxon.sf.net/";

declare namespace marcxml   = "http://www.loc.gov/MARC21/slim";
declare namespace madsrdf   = "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdf       = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option saxon:output "indent=yes";

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string external;

(:~
:   This variable is for desired model.  Expected values are: madsrdf, skos, all
:)
declare variable $model as xs:string external;

let $marcxml := fn:doc($marcxmluri)//marcxml:record
let $resources :=
    for $r in $marcxml
    let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($r)
    let $response :=  
        if ($model eq "madsrdf") then
            $madsrdf
        else if ($model eq "skos") then 
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($r)
            return madsrdf2skos:madsrdf2skos($madsrdf)
        else
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($r)
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




