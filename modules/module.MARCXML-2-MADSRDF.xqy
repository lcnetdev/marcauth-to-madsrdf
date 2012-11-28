xquery version "1.0";

(:
:   Module Name: MARCXML to MADSRDF
:
:   Module Version: 1.0
:
:   Date: 2012 April 16
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: None
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Primary purpose is to transform MARCXML 
:       authority to MADSRDF.  This will result in a verbose 
:       MADS/RDF record, and one without any linked relationships.
:
:)
   
(:~
:   This module transforms a MARCXML authority to MADSRDF.  This
:   will result in a verbose MADS/RDF record, and one without any
:   linked relationships.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since April 16, 2012
:   @version 1.0
:)

(:

    Note (kefo - 28 Nov 2012) - did not incorporate logic to create FRBRWork or FRBRExpression
    collection relationships.
:)


module namespace marcxml2madsrdf = 'info:lc/id-modules/marcxml2madsrdf2#';

(: MODULES :)
import module namespace marcxml2recordinfo = "info:lc/id-modules/recordInfoRDF#" at "module.MARCXML-2-RecordInfoRDF.xqy";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace owl           = "http://www.w3.org/2002/07/owl#";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";

(: Mapping of yXX to element types :)
declare variable $marcxml2madsrdf:elementTypeMap :=
    <elementTypeMaps>
        <elementType tag_suffix="00" code="a">madsrdf:FullNameElement</elementType>
        <elementType tag_suffix="00" code="a" ancillary="d">madsrdf:DateNameElement</elementType>
        <elementType tag_suffix="00" code="a" ancillary="c">madsrdf:TermsOfAddressNameElement</elementType>
        <elementType tag_suffix="00" code="a" ancillary="q">madsrdf:FullNameElement</elementType>
        <elementType tag_suffix="00" code="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="r">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="g">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="f">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="m">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="o">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="00" code="p">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="00" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="00" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="10" code="a">madsrdf:NameElement</elementType>
        <elementType tag_suffix="10" code="a" ancillary="b">madsrdf:NameElement</elementType>
        <elementType tag_suffix="10" code="a" ancillary="d">madsrdf:DateNameElement</elementType>
        <elementType tag_suffix="10" code="a" ancillary="k">madsrdf:NamePartElement</elementType>
        <elementType tag_suffix="10" code="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="r">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="g">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="10" code="p">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="10" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="10" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="10" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="10" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="11" code="a">madsrdf:NameElement</elementType>
        <elementType tag_suffix="11" code="a" ancillary="c">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="11" code="a" ancillary="d">madsrdf:DateNameElement</elementType>
        <elementType tag_suffix="11" code="a" ancillary="e">madsrdf:NameElement</elementType>
        <elementType tag_suffix="11" code="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="c">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="11" code="p">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="11" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="11" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="30" code="a">madsrdf:MainTitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="f">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="s">madsrdf:SubTitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="30" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="30" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="30" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="30" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="48" code="a">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="48" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="48" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="48" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="48" code="z">madsrdf:GeographicElement</elementType>
                
        <elementType tag_suffix="50" code="a">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="50" code="a" ancillary="b">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="50" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="50" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="50" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="50" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="51" code="a">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="51" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="51" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="51" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="51" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="55" code="a">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="55" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="55" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="55" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="55" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="80" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="80" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="80" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="80" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="81" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="81" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="81" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="81" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="82" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="82" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="82" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="82" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="85" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="85" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="85" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="85" code="z">madsrdf:GeographicElement</elementType>      
    </elementTypeMaps>;

(: Mapping of MARC Auth 1XX subfields (and combinations) to appropriate MADS/RDF types :)
declare variable $marcxml2madsrdf:marc2madsMap := 
    <marc2madsMap>
        <map tag_suffix="00" count="1" subfield="a">madsrdf:PersonalName</map>
        <map tag_suffix="00" count="2" subfield="cdgq">madsrdf:PersonalName</map>
        <map tag_suffix="00" count="2" subfield="t">madsrdf:NameTitle</map>
        <map tag_suffix="00" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="10" count="1" subfield="a">madsrdf:CorporateName</map>
        <map tag_suffix="10" count="2" subfield="bcdg">madsrdf:CorporateName</map>
        <map tag_suffix="10" count="2" subfield="t">madsrdf:NameTitle</map>
        <map tag_suffix="10" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="11" count="1" subfield="a">madsrdf:ConferenceName</map>
        <map tag_suffix="11" count="2" subfield="cdgq">madsrdf:ConferenceName</map>
        <map tag_suffix="11" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="30" count="1" subfield="a" variant_subfield="t">madsrdf:Title</map>
        <map tag_suffix="30" count="2" subfield="d">madsrdf:Title</map>
        <map tag_suffix="30" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="48" count="1" subfield="a" variant_subfield="y">madsrdf:Temporal</map>
        <map tag_suffix="48" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="50" count="1" subfield="a" variant_subfield="x">madsrdf:Topic</map>
        <map tag_suffix="50" count="2" subfield="bvxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="51" count="1" subfield="a" variant_subfield="z">madsrdf:Geographic</map>
        <map tag_suffix="51" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="55" count="1" subfield="a" variant_subfield="vpk">madsrdf:GenreForm</map>
        <map tag_suffix="55" count="2" subfield="vxyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="80" count="1" subfield="x">madsrdf:Topic</map>
        <map tag_suffix="80" count="2" subfield="vyz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="81" count="1" subfield="z">madsrdf:Geographic</map>
        <map tag_suffix="81" count="2" subfield="vxy">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="82" count="1" subfield="y">madsrdf:Temporal</map>
        <map tag_suffix="82" count="2" subfield="vxz">madsrdf:ComplexSubject</map>
        
        <map tag_suffix="85" count="1" subfield="v">madsrdf:GenreForm</map>
        <map tag_suffix="85" count="2" subfield="yxz">madsrdf:ComplexSubject</map>
    </marc2madsMap>;
  
(: Mapping of MARC Auth Notes to MADS note types :)    
declare variable $marcxml2madsrdf:noteTypeMap :=
    <noteTypeMaps>
        <type tag="667">madsrdf:editorialNote</type>
        <type tag="678">madsrdf:note</type>
        <type tag="680">madsrdf:note</type>
        <type tag="681">madsrdf:exampleNote</type>
        <type tag="682">madsrdf:changeNote</type>
        <type tag="688">madsrdf:historyNote</type>     
    </noteTypeMaps>;

(: Mapping of MARC Auth relations to MADS relations :)    
declare variable $marcxml2madsrdf:relationTypeMap :=
    <relationTypeMaps>
        <type tag_prefix="5" pos="1" w="a">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_prefix="5" pos="1" w="b">madsrdf:hasLaterEstablishedForm</type>
        <type tag_prefix="5" pos="1" w="d">madsrdf:hasAcronymVariant</type>
        <type tag_suffix="5" pos="1" w="g">madsrdf:hasBroaderAuthority</type>
        <type tag_suffix="5" pos="1" w="h">madsrdf:hasNarrowerAuthority</type>
        <type tag_prefix="5" pos="1" w="_">madsrdf:hasRelation</type>
        
        <type tag_prefix="5" pos="2" w="a">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="b">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="c">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="d">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="e">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="f">madsrdf:hasRelatedAuthority</type>
        <type tag_suffix="5" pos="2" w="g">madsrdf:hasRelatedAuthority</type>
        <type tag_suffix="5" pos="2" w="h">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="1" w="_">madsrdf:hasRelatedAuthority</type>
        
        <type tag_suffix="5" pos="3" w="a">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_suffix="5" pos="3" w="e">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_suffix="5" pos="3" w="o">madsrdf:hasEarlierEstablishedForm</type>
        
        <type tag_suffix="5" pos="3" w="b">INVALID</type>
        
        <type tag_prefix="5" pos="4" w="b">madsrdf:see</type>
        <type tag_prefix="5" pos="4" w="c">madsrdf:see</type>
        <type tag_prefix="5" pos="4" w="d">madsrdf:see</type>
       
    </relationTypeMaps>;

(:~
:   This is the main function.  It converts MARCXML to MADSRDF.
:   It takes the MARCXML as the first argument.
:
:   @param  $marcxml        node() is the MARC XML
:   @return rdf:RDF element of MADS RDF/XML
:)
declare function marcxml2madsrdf:marcxml2madsrdf(
    $marcxml as element(marcxml:record), 
    $baseuri as xs:string)
    as element(rdf:RDF)
{

    let $marc001 := fn:replace( $marcxml/marcxml:controlfield[@tag='001'] , ' ', '')
    
    (: LC Specific :)
    let $scheme :=
        if (fn:substring($marc001, 1, 1) eq 's') then
            "subjects"
        else if (fn:substring($marc001, 1, 1) eq 'n') then
            "names"
        else if (fn:substring($marc001, 1, 1) eq 'g') then
            "genreForms"
        else
            "empty"

    (: LC Specific :) 
    let $leader_pos05 := fn:substring($marcxml/marcxml:leader, 6 ,1)
    let $deleted := 
        if ($leader_pos05 eq "d") then
            fn:true()
        else
            fn:false()
            
    let $df1xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'1')]
    let $df1xx_suffix := fn:substring($df1xx/@tag, 2, 2)
    let $df1xx_sf_counts := fn:count($df1xx/marcxml:subfield)
    let $df1xx_sf_two_code := $df1xx/marcxml:subfield[2]/@code
    
    let $label := marcxml2madsrdf:generate-label($df1xx, $df1xx_suffix)
    let $madstype := marcxml2madsrdf:get-madstype($df1xx)
    
    let $components := 
        if ($deleted) then
            marcxml2madsrdf:create-components-from-DFxx($df1xx, fn:false())
        else
            marcxml2madsrdf:create-components-from-DFxx($df1xx, fn:true())
    let $componentList := 
        if ($components and $deleted) then marcxml2madsrdf:create-component-list($components) 
        else if ($components) then marcxml2madsrdf:create-component-list($components)
        else ()
        
    let $elementList := 
        if (fn:not($componentList)) then 
            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df1xx)
            return marcxml2madsrdf:create-element-list($elements) 
        else ()
        
    let $variants :=
        for $df in $marcxml/marcxml:datafield[fn:starts-with(@tag,'4')]
        return element madsrdf:hasVariant { marcxml2madsrdf:create-variant($df) }
        
    let $relations := 
        for $df in $marcxml/marcxml:datafield[fn:starts-with(@tag,'5')]|$marcxml/marcxml:datafield[fn:starts-with(@tag,'4') and marcxml:subfield[1]/@code="w"]
        return marcxml2madsrdf:create-relation($df)
        
    let $undiff :=
        if ( fn:substring($marcxml/marcxml:controlfield[@tag='008'], 33 ,1) eq 'b' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection {
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesUndifferentiated'}
        }
        else ()

    (: Note - this could be LC specific :)
    let $df682 := $marcxml/marcxml:datafield[@tag='682'][1] (: can there ever be more than one? :)
    let $hasLater_relation := 
        if ($deleted and $df682) then
            marcxml2madsrdf:create-hasLaterForm-relation($df682, $madstype, $baseuri)
        else ()
        
    let $sources := 
        for $df in $marcxml/marcxml:datafield[fn:matches(@tag , '670|675')]
        return element madsrdf:hasSource { marcxml2madsrdf:create-source($df) }
        
    let $notes := 
        for $df in $marcxml/marcxml:datafield[fn:matches(@tag , '667|678|680|681|688')]
        return marcxml2madsrdf:create-note($df)
        
    let $delNote :=
        if ($deleted and $df682) then
             marcxml2madsrdf:create-note-deleted($df682)
        else ()
        
    let $identifiers :=
        (
            element identifiers:lccn { fn:normalize-space($marcxml/marcxml:datafield[@tag eq "010"]/marcxml:subfield[@code eq "a"]) },
            
            for $i in $marcxml/marcxml:datafield[@tag eq "020"]
            let $code := fn:normalize-space($i/marcxml:subfield[@code eq "2"])
            let $iStr := fn:normalize-space(xs:string($i/marcxml:subfield[@code eq "a"]))
            where $iStr ne ""
            return
                if ( $code ne "" ) then
                    element { fn:concat("identifiers:" , $code) } { $iStr }
                else
                    element identifiers:id { $iStr },
                    
            for $i in $marcxml/marcxml:datafield[@tag eq "035"]/marcxml:subfield[@code eq "a"][fn:not( fn:contains(. , "DLC") )]
            let $iStr := xs:string($i)
            return
                if ( fn:contains($iStr, "(OCoLC)" ) ) then
                    element identifiers:oclcnum { fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) }
                else
                    element identifiers:id { fn:normalize-space($iStr) }
        )
         
    let $classification := 
        for $df in $marcxml/marcxml:datafield[@tag='053']
        return marcxml2madsrdf:create-classifications($df)
        
    let $ri := marcxml2recordinfo:recordInfoFromMARCXML($marcxml)
    let $adminMetadata := 
        for $r in $ri
        return element madsrdf:adminMetadata { $r }
    
    let $rdf := 
        if ($deleted) then
            let $variant := 
                element {$madstype} {
                    attribute rdf:about { fn:concat($baseuri , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , "Variant" ) }
                    },
                    (: all "deleted" or "cancelled" records are Variants AND DeprecatedAuthorities :) 
                    element rdf:type {
                        attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , "DeprecatedAuthority" ) }
                    },
                    element madsrdf:variantLabel {
                        attribute xml:lang {"en"},
                        text {$label} 
                    },
                    $componentList,
                    $elementList,
                    $hasLater_relation,
                    $delNote,
                    $notes,
                    $adminMetadata
                }
            return $variant
        else 
            let $authority := 
                element {$madstype} {
                    attribute rdf:about { fn:concat($baseuri , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , "Authority" ) }
                    },
                    element madsrdf:authoritativeLabel {
                        attribute xml:lang {"en"},
                        text {$label} 
                    },
                    $componentList,
                    $elementList,
                    $variants,
                    $undiff,
                    $relations,
                    $sources,
                    $notes,
                    $classification,
                    $identifiers,
                    $adminMetadata
                }
            return $authority

    return <rdf:RDF>{$rdf}</rdf:RDF>
};


(:
-------------------------

    Creates Classification Properties:
    
        $marc053 as element() is the marc 053 datafield 

-------------------------
:)
(:~
:   Classification element
:
:   @param  $df         marcxml datafield element
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-classifications(
    $marc053 as element(marcxml:datafield)
    ) as element(madsrdf:classification) {
        
    let $textparts :=
        for $sf at $pos in $marc053/marcxml:subfield
            let $class_str := 
                if ($sf/@code eq 'a') then
                    $sf
                else if ($sf/@code eq 'b') then
                    fn:concat('- ',$sf)
                else ""
            return $class_str
    let $text := fn:replace( fn:string-join($textparts , '') , ' ' , '' )

    let $classification := 
        element madsrdf:classification { 
            text { $text }
       }
        
    return $classification
};

(:~
:   Creates a Component
:
:   @param  $sf        element() is the subfield
:   @param  $pos       as xs:integer is the position in the loop
:   @param  $authority as xs:boolean denotes whether this is an Authority or Variant    
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-component(
        $sf as element(), 
        $df_suffix as xs:string,
        $pos as xs:integer, 
        $authority as xs:boolean) as element()*
{
    let $c := xs:string($sf/@code)
    let $aORv := 
        if ($authority) then
            "Authority"
        else
            "Variant"
            
    let $type :=
        if ($pos lt 2) then
            xs:string($marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1'])
        else
            xs:string($marcxml2madsrdf:marc2madsMap/map[fn:contains(@variant_subfield , $c) and @count='1'])
            
    let $labelProperty := 
        if ($authority) then
            "madsrdf:authoritativeLabel"
        else
            "madsrdf:variantLabel"
    
    let $elements := marcxml2madsrdf:create-element($sf, 1)
    let $elementList := 
        if ($elements) then marcxml2madsrdf:create-element-list($elements) 
        else ()
      
    let $label := fn:string-join($elements, ' ')
    let $label := 
        if ( fn:ends-with($label, ".") and fn:not(fn:contains($type, "Name")) ) then
            fn:substring($label, 1, (fn:string-length($label) - 1))
        else 
            $label
    
    let $component := 
        if ($type ne "") then
            element {$type} {
                (: attribute rdf:nodeID {$nodeID}, :)
                element rdf:type {
                    attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , $aORv ) }
                }, 
                element {$labelProperty} { 
                    (: attribute xml:lang {"en"}, :)
                    text {$label} 
                },
                $elementList
            }
        else ()
    return $component
};

(:~
:   Creates a componentList
:
:   @param  $components  as element()*
:   @param  $counts                 as xs:integer is the number of subfields    
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-component-list($components) {
    let $component_list :=   
        element {"madsrdf:componentList"} {
            attribute rdf:parseType {"Collection"},
            $components
        }
    return $component_list
};

(:~
:   This function creates a componentList from a 1xx or 4xx datafield.
:
:   @param  $df         marcxml datafield element
:   @param $authority as xs:boolean, denotes whether this is an Authority or Variant
:   @return specially formatted string for use as lexical label
:)
declare function marcxml2madsrdf:create-components-from-DFxx(
    $df as element(marcxml:datafield), 
    $authority as xs:boolean) {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $components := 
        if (
            (fn:count($df/marcxml:subfield[fn:matches(@code , "a|t|v|x|y|z")]) > 1)
                or
            ( fn:matches($df_suffix , '80|81|82|85') and
              $df/marcxml:subfield[@code ne "w"] ) 
            ) then
            for $f at $pos in $df/marcxml:subfield[fn:matches(@code , "a|t|v|x|y|z")]
                let $component := marcxml2madsrdf:create-component($f, $df_suffix, $pos, $authority)
                return $component
        else ()
        
    return $components
};


(:~
:   This function creates label elements, for the elementList.
:
:   @param  $sf         marcxml subfield element
:   @param  $pos        as xs:integer is the position in the loop
:   @return a sequence
:)
declare function marcxml2madsrdf:create-element(
    $sf as element(marcxml:subfield), 
    $pos as xs:integer
    ) {
    let $tag_suffix := fn:substring($sf/../@tag , 2 , 2)
    let $tag_prefix := fn:substring($sf/../@tag , 1 , 1)
    let $label := $sf/../text()
    let $code := xs:string($sf/@code)
    let $element :=
        if ($sf/@code ne 'w') then
            let $el := $marcxml2madsrdf:elementTypeMap/elementType[@tag_suffix=$tag_suffix and @code=$sf/@code and fn:not(@ancillary)]/text()
            let $label := xs:string($sf)
            return
                element {$el} {
                    element madsrdf:elementValue { 
                        attribute xml:lang {"en"},
                        $label
                    }
                }
        else ()
    let $extras := 
        if ($pos=1) then
            for $dfc in $sf/following-sibling::node()
                let $el := $marcxml2madsrdf:elementTypeMap/elementType[@tag_suffix=$tag_suffix and @code=$sf/@code and @ancillary=$dfc/@code]/text()
                return 
                    if ($el and ($sf/@code="t" or ($dfc/@code!="t" and fn:not($dfc/preceding-sibling::node()[@code="t"])))) then
                        (: this seems a little forced, but we need to seperate the the name and title parts :) 
                        element {$el} {
                            element madsrdf:elementValue { 
                                attribute xml:lang {"en"},
                                text {$dfc} 
                            }
                        }
                    else ()
        else ()

    return ($element , $extras)
};


(:~
:   This function creates an element list from elements.
:
:   @param  $elements         elements
:   @return a sequence
:)
declare function marcxml2madsrdf:create-element-list($elements) as element(madsrdf:elementList) {
    let $e_list :=
            element madsrdf:elementList {
                attribute rdf:parseType {"Collection"},
                $elements
            }
    return $e_list
};


(:~
:   This function creates elements from a 1xx or 4xx datafield.
:
:   @param  $df         marcxml datafield element
:   @return specially formatted string for use as lexical label
:)
declare function marcxml2madsrdf:create-elements-from-DFxx(
    $df as element(marcxml:datafield)
    ) {
    
    let $df_suffix := fn:substring($df/@tag, 2, 2)
        
    let $elements := 
        if ( 
                ($df/marcxml:subfield[@code eq 'a'] or fn:matches($df_suffix , '80|81|82|85'))
            ) then
            for $f at $pos in $df/marcxml:subfield[fn:matches(@code , "a|v|x|y|z")]
                let $element := marcxml2madsrdf:create-element($f, $pos)
                return $element
        else ()
    return $elements
};

(:~
:   Returns relations for items embedded within MARC Auth 682
:   This, rightly or wrongly, assumes that the later Authority
:   is of the same MADSType
:
:   @param  $df             element() is the 682 datafield for parsing
:   @param  $authorityType  xs:string of MADSType
:   @return zero or more madsrdf:hasLaterEstablishedForm elements
:)
declare function marcxml2madsrdf:create-hasLaterForm-relation(
    $df as element(marcxml:datafield), 
    $madstype as xs:string,
    $baseuri as xs:string
    ) as element()* 
{
    let $elements := 
        for $s in $df/marcxml:subfield
        return
            if ($s/@code eq "a") then
            (:  
                if code eq "a" then it is a replacement heading, but 
                what type of replacement is it?
            :)
                let $objprop := 
                    if ( fn:matches( xs:string($df) , 'covered by' ) ) then
                        "madsrdf:useInstead"
                    else
                        "madsrdf:hasLaterEstablishedForm"
                return
                    element {$objprop} {
                        element {$madstype} {
                            if ($s/following-sibling::node()[@code!=""][1]/@code eq "i") then
                                let $relatedlccn := fn:replace( $s/following-sibling::node()[@code!=""][1]/text(), "\(|\)| |\.|and|,", "")
                                return 
                                    attribute rdf:about { 
                                        fn:concat( $baseuri , "/" , $relatedlccn )
                                    }
                            else (),
                            element rdf:type { 
                                attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , "Authority" ) }
                            },
                            element madsrdf:authoritativeLabel {
                                $s/text()
                                }
                            }
                        }
                else ()
    return $elements
};

(:~
:   Creates MADS Note (see deletionNote, which 
:   is handled differently.
:
:   @param  $df        element() the relevant marcxml:datafield 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-note(
    $df as element(marcxml:datafield)
    ) as element() {
    
    let $tag := $df/@tag
    let $type := $marcxml2madsrdf:noteTypeMap/type[@tag=$tag]/text()
    let $text := fn:string-join($df/marcxml:subfield, ' ')
            
    let $note := element {$type} {$text}
        
    return $note
};


(:~
:   Creates MADS Deletion Note
:   This demarks a "replaced by" heading
:
:   @param  $df        element() the relevant marcxml:datafield 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-note-deleted(
    $df as element(marcxml:datafield)
    ) as element() {
    let $textparts :=
        for $sf in $df/marcxml:subfield
            let $str := 
                if ($sf/@code eq 'a') then
                    fn:concat('{' , $sf/text() , '}')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
            
    let $note := element madsrdf:deletionNote { 
            attribute xml:lang {"en"},
            text {$text} 
        }
        
    return $note
};

(:~
:   Creates MADS Relation
:
:   @param  $df        element() the relevant marcxml:datafield 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-relation(
    $df as element(marcxml:datafield)) 
    as element()* {         
    
    let $wstr := xs:string($df/marcxml:subfield[@code='w']/text())
    let $ws := fn:tokenize($wstr , "[a-z]")
    return
        if (fn:normalize-space($wstr) eq "" and $df/marcxml:subfield[@code='a']) then
            (: reciprocal relations :)
            let $reltype := "madsrdf:hasReciprocalAuthority"
            let $auth := fn:true()
            
            return marcxml2madsrdf:create-relation-body($reltype,$df,$auth)
        else 
            for $c at $pos in fn:string-to-codepoints($wstr)
                let $w := fn:codepoints-to-string($c)
                return 
                if ($w ne "n" and $pos != 4) then
                    let $reltype := $marcxml2madsrdf:relationTypeMap/type[@w=$w and @pos=$pos]/text()
                    return
                        if ($reltype ne "INVALID") then
                            let $auth :=
                                if ($reltype eq "madsrdf:hasEarlierEstablishedForm" or 
                                    $reltype eq "madsrdf:hasAcronymVariant") then
                                    fn:false()
                                else
                                    fn:true()
                            return marcxml2madsrdf:create-relation-body($reltype,$df,$auth)
                        else 
                            ()
                else if ($w ne "n" and $pos = 4) then
                    let $reltype := $marcxml2madsrdf:relationTypeMap/type[@w=$w and @pos=$pos]/text()
                    return
                        if ($reltype ne "INVALID") then
                            let $auth :=
                                if ($reltype eq "madsrdf:hasEarlierEstablishedForm" or 
                                    $reltype eq "madsrdf:hasAcronymVariant") then
                                    fn:false()
                                else
                                    fn:true()
                            return marcxml2madsrdf:create-relation-body($reltype,$df,$auth)
                        else 
                            ()
                else ()
};

(:~
:   Creates the MADS Relation body
:
:   @param $reltype as xs:string is the type of relation
:   @param  $df        element() the relevant marcxml:datafield 
:   @param $authority as xs:boolean, denotes whether this is an Authority or Variant
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-relation-body(
    $reltype as xs:string,
    $df as element(marcxml:datafield),
    $authority as xs:boolean
    ) as element() {
    
    let $aORv :=
        if ($authority) then
            "Authority"
        else
            "Variant"
            
    let $labelProp := 
        if ($authority) then
            "madsrdf:authoritativeLabel"
        else
            "madsrdf:variantLabel"
    
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $label := marcxml2madsrdf:generate-label($df,$df_suffix)                          
    let $madstype := marcxml2madsrdf:get-madstype($df)
                                        
    let $components := marcxml2madsrdf:create-components-from-DFxx($df, $authority)
    let $componentList := 
        if ($components) then marcxml2madsrdf:create-component-list($components) 
        else ()
            
    let $elementList := 
        if (fn:not($componentList)) then 
            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df)
            return marcxml2madsrdf:create-element-list($elements) 
        else ()
        
    let $relation := 
        element {$reltype} {
            element {$madstype} {
                element rdf:type {
                    attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , $aORv ) }
                },
                element {$labelProp} { 
                    attribute xml:lang {"en"},
                    text {$label} 
                },
                $componentList,
                $elementList
            }                    
        }
    
    return $relation
};


(:~
:   Creates a source.
:
:   @param  $df        element() is the subfield   
:   @return madsrdf:Source as element()
:)
declare function marcxml2madsrdf:create-source(
    $df as element(marcxml:datafield)
    ) as element(madsrdf:Source) {
    
    let $tag := $df/@tag
        
    let $citation_source_element := 
        if ($df/marcxml:subfield[@code eq 'a']/text()) then
            <madsrdf:citation-source>{$df/marcxml:subfield[@code eq 'a']/text()}</madsrdf:citation-source>
        else ()
    let $status_element := 
        if ($tag eq '670') then
            <madsrdf:citation-status>found</madsrdf:citation-status>
        else 
            <madsrdf:citation-status>notfound</madsrdf:citation-status>    
    let $textparts :=
        for $sf in $df/marcxml:subfield[@code ne 'a']
            let $str := 
                if ($sf/@code eq 'u') then
                    fn:concat('{' , $sf/text() , '}')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
    let $text_element := 
        if (fn:normalize-space($text)) then
            <madsrdf:citation-note xml:lang="en">{$text}</madsrdf:citation-note>
        else ()
               
    let $source := 
            element madsrdf:Source {
                $citation_source_element,
                $text_element,
                $status_element
            }
    return $source
};

(:~
:   Creates a Variant.
:
:   @param  $df        element() is the subfield   
:   @return madsrdf:hasVariant/child::node()[1] as element()
:)
declare function marcxml2madsrdf:create-variant(
    $df as element(marcxml:datafield)
    ) as element() {
    
    let $tag := $df/@tag
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_counts := fn:count($df/marcxml:subfield[@code ne 'w'])
    let $df_sf_two_code := $df/marcxml:subfield[2]/@code
    
    let $label := marcxml2madsrdf:generate-label($df, $df_suffix)
    let $madstype := marcxml2madsrdf:get-madstype($df)
    
    let $components := marcxml2madsrdf:create-components-from-DFxx($df, fn:false())
    let $componentList := 
        if ($components) then marcxml2madsrdf:create-component-list($components) 
        else ()
        
    let $elementList := 
        if (fn:not($componentList)) then 
            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df)
            return marcxml2madsrdf:create-element-list($elements) 
        else ()
            
    let $variant := 
            element {$madstype} {
                element rdf:type {
                    attribute rdf:resource { fn:concat( "http://www.loc.gov/mads/rdf/v1#" , "Variant" ) }
                },
                element madsrdf:variantLabel { 
                    text {$label} 
                },
                $componentList,
                $elementList     
            }
        
    return $variant
};



(:~
:   This function creates a authoritative, variant, or deprecated label
:   from the 1XX.
:
:   @param  $df         marcxml datafield element
:   @param  $df_suffix  last two characters of marc/datafield tag value 
:   @return specially formatted string for use as lexical label
:)
declare function marcxml2madsrdf:generate-label(
    $df as element(marcxml:datafield), 
    $df_suffix as xs:string) 
    as xs:string {
    
    let $label := 
        if (fn:matches($df_suffix, ("00|10|11|30"))) then
            (: we have a name :)
            fn:concat(
                fn:string-join($df/marcxml:subfield[@code ne 'w' and @code!='v' and @code!='x' and @code!='y' and @code!='z' and @code!='6'] , ' '),
                if ( $df/marcxml:subfield[@code='v' or @code='x' or @code='y' or @code='z'] ) then
                    fn:concat("--",fn:string-join($df/marcxml:subfield[@code='v' or @code='x' or @code='y' or @code='z'] , '--'))
                else ""
            )   
        else
            let $label := fn:string-join($df/marcxml:subfield[@code ne 'w' and @code ne '6'] , '--')
            let $label := 
                if ( fn:ends-with($label, ".") ) then
                    fn:substring($label, 1, (fn:string-length($label) - 1))
                else 
                    $label
            return $label
            
    return fn:normalize-space($label)
};


(:~
:   This function determines the type of entity, be it
:   a Geographic, PersonalName, etc. from the 1XX.
:
:   @param  $df         marcxml datafield element
:   @return specially formatted string for use as lexical label
:)
declare function marcxml2madsrdf:get-madstype(
    $df as element(marcxml:datafield)
    ) as xs:string {
    
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_two_code := xs:string($df/marcxml:subfield[fn:matches(@code , "[tvxyz]")][1]/@code)
            
    let $complex := 
        if (
            $df/marcxml:subfield[@code='a'] and 
            fn:matches( fn:string-join($df/marcxml:subfield[@code!="a"]/@code, ''), '[tvxyz]')
            ) then
            (: $a follwed by $t,v,x,y,z - so this is a complex heading :)
                fn:true()
        else if (
                fn:matches($df_suffix , '80|81|82|85') and
                $df/marcxml:subfield[1][fn:matches(@code, 'v|x|y|z')] and
                $df/marcxml:subfield[2][fn:matches(@code, 'v|x|y|z')]
            ) then
            (: a subdivision with two appropriate subfields - so this is a complex heading :)
            fn:true()
        else 
            fn:false()

    let $type_element := 
        if ($complex) then
            if (
                fn:matches($df_suffix , '00|10|11') and 
                $df/marcxml:subfield[@code="t"]
                ) then
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='2' and fn:contains(@subfield , 't') ] 
                
            else if (
                fn:matches($df_suffix , '80|81|82|85') and
                $df/marcxml:subfield[2][fn:matches(@code, 'v|x|y|z')]
                ) then
                 $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='2']
            else 
            
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='2' and fn:contains(@subfield , $df_sf_two_code) ]
        else
            $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1']
            
    return xs:string($type_element)

};