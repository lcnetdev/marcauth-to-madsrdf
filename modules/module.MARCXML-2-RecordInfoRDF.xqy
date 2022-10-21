xquery version "1.0";

(:
:   Module Name: MARCXML to RecordInfo
:
:   Module Version: 1.0
:
:   Date: 2010 Feb 17
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: xdmp
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Primary purpose is to derive
:       administrative metadata from MARCXML for RDF.  
:
:)
   
(:~
:   Primary purpose is to derive
:   administrative metadata from MARCXML for RDF.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since February 14, 2011
:   @version 1.0
:)
        

(: NAMESPACES :)
module namespace  marcxml2recordinfo    = "info:lc/id-modules/recordInfoRDF#";
declare namespace xdmp      = "http://marklogic.com/xdmp";
declare namespace marcxml               = "http://www.loc.gov/MARC21/slim";
declare namespace rdf                   = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace ri                    = "http://id.loc.gov/ontologies/RecordInfo#";
declare namespace madsrdf				= "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdfs					= "http://www.w3.org/2000/01/rdf-schema#";

(: FUNCTIONS :)
(:
-------------------------

    Dervives admin metadata from MARCXML, returns RecordInfo RDF:
    
        $marcxml as element() is the MARCXML
100630|| anannbabn          |n ana      </marcxml:controlfield>
00390nz  a2200133n  4500

-------------------------
:)

(:~
:   This is the main function, which expects a boolean 
:   parameter set.  It takes MARCXML and 
:   generates RecordInfo RDF.
:
:   @param  $marcxml        element is the MARCXML  
:   @return ri:RecordInfo node
:)
declare function marcxml2recordinfo:recordInfoFromMARCXML(
        $marcxml as element(marcxml:record), 
        $all as xs:boolean
        ) as element(ri:RecordInfo)* {
    marcxml2recordinfo:marcxml2ri($marcxml, $all)
};

(:~
:   This is the alternate main function, without 
:   a boolean parameter set.  It defaults to "true."
:   It will output a RecordInfo block for every administrative
:   date present in the MARCXMLfor "all".
:
:   @param  $marcxml        element is the MARCXML  
:   @return ri:RecordInfo node
:)
declare function marcxml2recordinfo:recordInfoFromMARCXML(
        $marcxml as element(marcxml:record)
        ) as element(ri:RecordInfo)* {
    marcxml2recordinfo:marcxml2ri($marcxml, fn:true())
};


declare function marcxml2recordinfo:marcxml2ri(
        $marcxml as element(marcxml:record), 
        $all as xs:boolean
        ) as element(ri:RecordInfo)* {

    let $marc001 := fn:replace( $marcxml/marcxml:controlfield[@tag='001'] , ' ', '')
    
    let $marc005 := $marcxml/marcxml:controlfield[@tag='005']
    let $mDate:= fn:concat(
                    fn:substring($marc005, 1 , 4),"-",
                    fn:substring($marc005, 5 , 2),"-",
                    fn:substring($marc005, 7 , 2)
					)
	let $modifiedDT := fn:concat(
                   	$mDate,
                    "T",
                    fn:substring($marc005, 9 , 2),":",
                    fn:substring($marc005, 11 , 2),":",
                    fn:substring($marc005, 13 , 2),""
                    )
    let $modifiedDT_element :=
        element ri:recordChangeDate { 
            attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#dateTime'},
            text {$modifiedDT}
        }
            
    let $marc008 := $marcxml/marcxml:controlfield[@tag='008']
    let $first2digits := fn:substring($marc008 , 1 , 2)
    (: What is the oldest date entered on file date? :)
    let $createdYear := 
		if (fn:matches($first2digits,"[a-zA-Z ]")) then  (: error  :)
			"1900"
        else if (xs:integer($first2digits) gt 74) then  
            fn:concat('19' , $first2digits)
        else
            fn:concat('20' , $first2digits)
    let $cDate:=fn:concat(
                    $createdYear,"-",
                    fn:substring($marc008, 3 , 2),"-",
                    fn:substring($marc008, 5 , 2)
					)
	let $createdDT := fn:concat(
                    $cDate,
					"T00:00:00"
                    )

    let $createdDT_element :=
            element ri:recordChangeDate { 
                attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#dateTime'},
                text {$createdDT}
            }
            
    let $createdRecordStatus := "new"  
    let $createdRSElement :=  
        element ri:recordStatus { 
            attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#string'},
            text {$createdRecordStatus}
        }
            
    let $leader_pos5 := fn:substring($marcxml/marcxml:leader, 6 , 1)
    let $record_status :=  
        if ($leader_pos5 eq 'd') then
            "deprecated" (: was "deleted" :)
        else if ($leader_pos5 eq 'a') then
            "revised"
        else if ($leader_pos5 eq 'c') then
            "revised"
        else if ($leader_pos5 eq 'n') then
            "new"
        else if ($leader_pos5 eq 'o') then
            "obsolete"
        else if ($leader_pos5 eq 's') then
            "deleted, replaced by two or more headings"
        else if ($leader_pos5 eq 'x') then
            "deleted, replaced by another"
        else ()
	let $record_status:= 
	    if ($record_status eq "revised" and ($mDate eq $cDate)) then
		    "new"
		else if ($record_status="new" and ($mDate ne $cDate)) then
		    "revised"
		else 
		    $record_status
    let $rs_element :=  
        element ri:recordStatus { 
            attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#string'},
            text {$record_status}
        }
	
	let $marc040a := fn:lower-case(fn:normalize-space(fn:string($marcxml/marcxml:datafield[@tag='040']/marcxml:subfield[@code='a'])))
	let $marc040a := fn:replace($marc040a,"(<|>|-| )","")
	let $marc040a_clean := fn:replace($marc040a,"([^A-Za-z])","")
    let $content_source_creator := 
        if ($marc040a) then
            if (fn:starts-with($marc040a, "Ca")) then				
                element ri:recordContentSource { 
                    element madsrdf:CorporateName {
                        element rdfs:label {$marc040a} 
                    }
				}
		    else
			    element ri:recordContentSource { 
	                attribute rdf:resource {fn:concat('http://id.loc.gov/vocabulary/organizations/' , fn:lower-case($marc040a_clean))}
	            }
        else ()
        
	let $marc040d := fn:lower-case(fn:normalize-space(fn:string($marcxml/marcxml:datafield[@tag='040']/marcxml:subfield[@code='c' or @code='d'][fn:last()])))
	let $marc040d := fn:replace($marc040d,"(<|>|-| )","")
	let $marc040d_clean := fn:replace($marc040d,"([^A-Za-z])","")
    let $content_source_modifier := 
        if ($marc040d) then
            if (fn:starts-with($marc040d, "Ca")) then				
                element ri:recordContentSource { 
                    element madsrdf:CorporateName {
                        element rdfs:label {$marc040d} 
                    }
				}
		    else
			    element ri:recordContentSource { 
	                attribute rdf:resource {fn:concat('http://id.loc.gov/vocabulary/organizations/' , fn:lower-case($marc040d_clean))}
	            }
        else ()


    let $marc040b := $marcxml/marcxml:datafield[@tag='040']/marcxml:subfield[@code='b']
    let $language_of_cataloging := 
        if ($marc040b) then
            element ri:languageOfCataloging { 
                attribute rdf:resource {fn:concat('http://id.loc.gov/vocabulary/iso639-2/' , fn:replace(fn:lower-case($marc040b), ' ', ''))}
            }
        else ()

    let $rdf :=
        ( 
            element ri:RecordInfo {
                    $createdDT_element,
                    $createdRSElement,
                    $content_source_creator,
                    $language_of_cataloging					
                },
            if ($record_status ne "new" and $marc040d_clean ne "") then
                element ri:RecordInfo {
                    $modifiedDT_element,
                    $rs_element,
                    $content_source_modifier,
                    $language_of_cataloging
                }
            else 
                ()
        )

    return $rdf

};

