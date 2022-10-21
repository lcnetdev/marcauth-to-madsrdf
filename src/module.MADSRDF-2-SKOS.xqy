xquery version "1.0";

(:
:   Module Name: MADSRDF 2 SKOS
:
:   Module Version: 1.0
:
:   Date: 2011 May 04
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Transforms MADS/RDF/XML to SKOS/RDF/XML.  
:
:)
   
(:~
:   Transforms MADS/RDF/XML to SKOS/RDF/XML.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since May 04, 2011
:   @version 1.0
:)

module namespace madsrdf2skos = 'info:lc/id-modules/madsrdf2skos#';

declare namespace   rdf                 = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace   rdfs                = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace   madsrdf             = "http://www.loc.gov/mads/rdf/v1#";
declare namespace   ri                  = "http://id.loc.gov/ontologies/RecordInfo#";
declare namespace   skos                = "http://www.w3.org/2004/02/skos/core#";
declare namespace   skosxl              = "http://www.w3.org/2008/05/skos-xl#";
declare namespace   foaf                = "http://xmlns.com/foaf/0.1/";
declare namespace   dcterms             = "http://purl.org/dc/terms/";
declare namespace   cs                  = "http://purl.org/vocab/changeset/schema#";
declare namespace   vs                  = "http://www.w3.org/2003/06/sw-vocab-status/ns#";

import module namespace constants   = "info:lc/id-modules/constants#" at "constants.xqy";

(:~
:   This is the main function.  It converts MADS/RDF to 
:   SKOS/RDF.
:
:   @param  $rdfxml        node() is the MADS/RDF  
:   @return rdf:RDF node
:)
declare function madsrdf2skos:madsrdf2skos($rdfxml as element()) as element(rdf:RDF) {
    let $dtype := madsrdf2skos:determine-dtype($rdfxml)
    let $uri := xs:string($rdfxml/child::node()[1]/@rdf:about)
    
    let $skosprops :=                 
        for $r in $constants:MADS2SKOSMAP/relation
        let $props := $rdfxml/child::node()[fn:name()][1]/child::node()[fn:name() eq $r/@prop]
        where $r/@skos
        return madsrdf2skos:mads2skos-relation($props, xs:string($r/@skos))
        
    let $skospropsextra := 
        for $p in $skosprops
        where (fn:name($p) eq "skosxl:altLabel" and fn:exists($p/rdf:Description/skosxl:literalForm))
        return
            element skos:altLabel {
                $p/rdf:Description/skosxl:literalForm/@xml:lang,
                xs:string($p/rdf:Description/skosxl:literalForm)
            }

    let $rdf :=  
        element rdf:Description {
            attribute rdf:about { $uri },
            madsrdf2skos:skos-types($rdfxml , $dtype),
            madsrdf2skos:skos-labels($rdfxml , $dtype),
            $skosprops,
            $skospropsextra,
            for $ri in $rdfxml/child::node()/madsrdf:adminMetadata
                return 
                    element skos:changeNote {
                        madsrdf2skos:mads2skos-recordinfo($ri, $uri)
                    }
        }

    return <rdf:RDF 
				xmlns:skos			=	"http://www.w3.org/2004/02/skos/core#"
				xmlns:rdf           = 	"http://www.w3.org/1999/02/22-rdf-syntax-ns#"
				xmlns:rdfs          = 	"http://www.w3.org/1999/02/22-rdf-schema#"
                xmlns:cs            =   "http://purl.org/vocab/changeset/schema#"
                xmlns:skosxl        =   "http://www.w3.org/2008/05/skos-xl#"
	        >
	            {$rdf}
	        </rdf:RDF>
};

(:~
:   What is the MADS/RDF Description type.
:   There are four options: Authority, Variant, DeprecatedAuthority, ()
:
:   @param  $rdf        node() is the MADS/RDF  
:   @return rdf:RDF node
:)
declare function madsrdf2skos:determine-dtype($rdfxml) {
    let $mtype := fn:local-name($rdfxml/child::node()[fn:name()][1])
    let $dtype := 
        if ($mtype eq "Authority") then
            "Authority"
        else if ($mtype eq "Variant" or $mtype eq "IndexTerm") then
            "Variant"
        else if ($mtype eq "DeprecatedAuthority") then
            "DeprecatedAuthority"
        else if ($mtype eq "MADSScheme") then
            "MADSScheme"
        else if ($mtype eq "MADSCollection") then
            "MADSCollection"
        else ()
    let $dtype := 
        if ($dtype) then
            ($dtype)
        else
            for $t in $rdfxml/child::node()[fn:name()][1]/rdf:type
            let $mtype := fn:substring-after($t/@rdf:resource, "#")
            return
                if ($mtype eq "Authority") then
                    "Authority"
                else if ($mtype eq "Variant") then
                    "Variant"
                else if ($mtype eq "DeprecatedAuthority") then
                    "DeprecatedAuthority"
                else ()
    (: there should only be one :)
    let $dtype := 
        if (fn:index-of($dtype, "DeprecatedAuthority") and fn:index-of($dtype, "Variant")) then
            "Variant"
        else
            fn:normalize-space(fn:string-join($dtype, ""))
    let $dtype := 
        if ($dtype) then
            ($dtype)
        else
            if (fn:contains(fn:name($rdfxml) , "Authority")) then
                "Authority"
            else ""
    return $dtype
};

(:~
:   Transform RecordInfo to Changeset
:
:   @param  $ri     is the madsrdf:adminMetada  
:   @return rdf:Description node
:)
declare function madsrdf2skos:mads2skos-recordinfo($ri as element(madsrdf:adminMetadata), $uri as xs:string) {
    
    element cs:ChangeSet {
        <cs:subjectOfChange rdf:resource="{$uri}" />,
        if ($ri/ri:RecordInfo/ri:recordContentSource) then
            element cs:creatorName {
                if ($ri/ri:RecordInfo/ri:recordContentSource/@rdf:resource) then
                    $ri/ri:RecordInfo/ri:recordContentSource/@rdf:resource
                else
                    xs:string($ri/ri:RecordInfo/ri:recordContentSource)
            }
        else (),
        if ($ri/ri:RecordInfo/ri:recordChangeDate) then 
            for $dt in $ri/ri:RecordInfo/ri:recordChangeDate[1]
            return element cs:createdDate {
                $dt/@rdf:datatype,
                xs:string($dt)
            }
        else (),
        if ($ri/ri:RecordInfo/ri:recordStatus) then
            element cs:changeReason {
                $ri/ri:RecordInfo/ri:recordStatus/@rdf:datatype,
                $ri/ri:RecordInfo/ri:recordStatus/@xml:lang,
                xs:string($ri/ri:RecordInfo/ri:recordStatus)
            }
        else ()
    } 
    
};

(:~
:   Do MADS/RDF 2 SKOS relation
:
:   @param  $rdf        node() is the MADS/RDF  
:   @return rdf:RDF node
:)
declare function madsrdf2skos:mads2skos-relation($madsprop, $skosprop as xs:string) {
    
    for $mp in $madsprop                    
    let $dtype := madsrdf2skos:determine-dtype($mp)
    let $mprop := $mp/child::node()[fn:name()]
    return
       element {$skosprop} {
            if ($mp/@rdf:resource) then
                $mp/@rdf:resource
            
            else if ($dtype or $mprop/rdf:type) then
                element rdf:Description {
                    $mprop/@rdf:about,
                    madsrdf2skos:skos-types($mp , $dtype),
                    madsrdf2skos:skos-labels($mp , $dtype),
                    for $m in $mprop/child::node()[fn:name()=$constants:MADS2SKOSMAP/relation/@prop]
                        let $prop := $constants:MADS2SKOSMAP/relation[@prop eq $m/fn:name()]
                        where $prop/@skos
                        return madsrdf2skos:mads2skos-relation($m, fn:data($prop/@skos))
                }
            else
                (
                    $mp/@rdf:datatype,
                    $mp/@xml:lang,
                    fn:normalize-space(xs:string($mp))
                )
        }
};

(:~
:   What SKOS types are in play.
:
:   @param  $rdf        node() is the MADS/RDF  
:   @return rdf:RDF node
:)
declare function madsrdf2skos:skos-types($rdfxml as element() , $dtype as xs:string) {
    if ($dtype eq "Authority") then
        <rdf:type rdf:resource="{ fn:concat($constants:NSMAP/nsmap[. eq 'skos']/@test , '#Concept') }"/>
    else if ($dtype eq "Variant") then
        <rdf:type rdf:resource="{ fn:concat($constants:NSMAP/nsmap[. eq 'skosxl']/@test , '#Label') }"/>
    else if ($dtype eq "MADSScheme") then
        <rdf:type rdf:resource="{ fn:concat($constants:NSMAP/nsmap[. eq 'skos']/@test , '#ConceptScheme') }"/>
    else if ($dtype eq "MADSCollection") then
        <rdf:type rdf:resource="{ fn:concat($constants:NSMAP/nsmap[. eq 'skos']/@test , '#Collection') }"/>
    else ()
};

(:~
:   SKOS labels, based on MADS/RDF Description type
:
:   @param  $rdf        node() is the MADS/RDF  
:   @return rdf:RDF node
:)
declare function madsrdf2skos:skos-labels($rdfxml as element() , $dtype as xs:string) {
    (
        for $l in $rdfxml/child::node()/madsrdf:authoritativeLabel
        return
            element skos:prefLabel {
                $l/@xml:lang,
                fn:normalize-space(xs:string($l))
            },
        for $l in $rdfxml/child::node()/madsrdf:variantLabel
        return
            element skosxl:literalForm {
                $l/@xml:lang,
                fn:normalize-space(xs:string($l))
            },
        for $l in $rdfxml/child::node()/madsrdf:deprecatedLabel
        return
            element skos:hiddenLabel {
                $l/@xml:lang,
                fn:normalize-space(xs:string($l))
            },
        for $l in $rdfxml/child::node()/rdfs:label
        return
            element rdfs:label {
                $l/@xml:lang,
                fn:normalize-space(xs:string($l))
            }
    )
};
