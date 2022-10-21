xquery version "1.0";

(:
:   Module Name: MARCXML to 2MADSRDF
:
:   Module Version: 1.0
:
:   Date: 2010 Oct 18
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
: Change Log:
	2012 Aug 28 Nate Trail added collection for undifferentiated names (008/32='b') 
	2012 Sep 12 Nate Trail added collection for FRBR Work and FRBR Expression, and changed the "may subdivide Geographically" label and name
	2012 Sep 20 Nate Trail added collection for FRBR Expression for musical arrangements
	2012 Oct 16 Nate Trail suppressed $6 from labels (880 mapping)
	
	2015 March 30 Nate Trail added useFor
	2015 April 22 Nate Trail added untracedReferences for subjects: sh93002523
	2015 July 27 Qi Tong added and modified madsrdf elements for RWO: 
	               birthdate, deathdate, birthplace, deathplace, entityDescriptor, honoraryTitle, associatedLocale, 
	               occupation, gender, prominentFamilyMember, assocatedLanguage, hasAffiliation
	2015 August 20 Qi Tong added madsrdf:fullerName
	
	2016 Dec 11 - Kevin Ford - Resource that is the object of hasEarlierEstablishedForm changed 
	            from being a Variant to an Authority.  I believe most - if not all - "hasEarlierEstablishedForm" 
	            relationships are in Names.  Those Name resources remain valid for assignment usually.
		
		NOTICE ! ALL CHANGES TO SUBJECTS SHOULD BE COPIED INTO THE VERSION IN MARCBIB2BIBFRAME,
:			WHICH USES IT TO CREATE BF:TOPIC etc.
:
:
:
:)
   
(:~
:   This module transforms a MARCXML authority to MADSRDF.  This
:   will result in a verbose MADS/RDF record, and one without any
:   linked relationships.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since October 18, 2010
:   @version 1.0
:)
module namespace  marcxml2madsrdf      = "info:lc/id-modules/marcxml2madsrdf#";


(: MODULES :)
import module namespace marcxml2recordinfo = "info:lc/id-modules/recordInfoRDF#" at "module.MARCXML-2-RecordInfoRDF.xqy";
import module namespace shared             = 'info:lc/id-modules/shared#' at "module.Shared.xqy";
 
(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace lcc       = "http://id.loc.gov/ontologies/lcc#";
declare namespace owl           = "http://www.w3.org/2002/07/owl#";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace skos          = "http://www.w3.org/2004/02/skos/core#";
declare namespace bf   			= "http://id.loc.gov/ontologies/bibframe/";
declare namespace geosparql     = "http://www.opengis.net/ont/geosparql";
declare namespace functx        = "http://www.functx.com";
declare namespace xdmp      = "http://marklogic.com/xdmp";


(: VARIABLES :)
declare variable $marcxml2madsrdf:authSchemeMap := (
        <authSchemeMaps>
            <authScheme abbrev="subjects">authorities/subjects/</authScheme>
            <authScheme abbrev="childrensSubjects">authorities/childrensSubjects/</authScheme>
            <authScheme abbrev="genreForms">authorities/genreForms/</authScheme>
            <authScheme abbrev="names">authorities/names/</authScheme>
            <authScheme abbrev="performanceMediums">authorities/performanceMediums/</authScheme>
			<authScheme abbrev="demographicTerms">authorities/demographicTerms/</authScheme>			
            <authScheme abbrev="empty">authorities/empty/</authScheme>
        </authSchemeMaps>
    ); 
(:http://www.loc.gov/standards/valuelist/lcdgt.html:)
declare variable $marcxml2madsrdf:dgtCategoryMap := (
        <dgtCategoryMaps>
            <dgtCategory code="age">collection_LCDGT_Age</dgtCategory>
            <dgtCategory code="edu">collection_LCDGT_Educational</dgtCategory>
            <dgtCategory code="eth">collection_LCDGT_Ethnic</dgtCategory>
            <dgtCategory code="gdr">collection_LCDGT_Gender</dgtCategory>
            <dgtCategory code="lng">collection_LCDGT_Language</dgtCategory> 
			<dgtCategory code="mpd">collection_LCDGT_Medical</dgtCategory>	
			<dgtCategory code="nat">collection_LCDGT_Nationality</dgtCategory>			
            <dgtCategory code="occ">collection_LCDGT_Occupational</dgtCategory>
            <dgtCategory code="rel">collection_LCDGT_Religion</dgtCategory>
            <dgtCategory code="sxo">collection_LCDGT_Sexual</dgtCategory>
            <dgtCategory code="soc">collection_LCDGT_Social</dgtCategory>            
        </dgtCategoryMaps>
    );
(:http://id.loc.gov/authorities/names/no2007025470.marcxml.xml:)
declare variable $marcxml2madsrdf:authTypeMap := (
    <authTypeMaps>
        <type tag="100" count="1" code="a" variant="madsrdf:PersonalName">madsrdf:PersonalName</type>
        <type tag="100" count="2" code="cdgq" variant="madsrdf:PersonalName">madsrdf:PersonalName</type>
        <type tag="100" count="2" code="t" variant="madsrdf:NameTitle">madsrdf:NameTitle</type> (: Would title ever not be in the second position?  Is it still an NT when there is a third term, a form subdivision? :)                  
        <type tag="100" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="110" count="1" code="a" variant="madsrdf:CorporateName">madsrdf:CorporateName</type>
        <type tag="110" count="2" code="bcdg" variant="madsrdf:CorporateName">madsrdf:CorporateName</type>
        <type tag="110" count="2" code="t" variant="madsrdf:NameTitle">madsrdf:NameTitle</type> (: this implies that t is the second component :)
        <type tag="110" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="111" count="1" code="a" variant="madsrdf:ConferenceName">madsrdf:ConferenceName</type>
        <type tag="111" count="2" code="cdgq" variant="madsrdf:ConferenceName">madsrdf:ConferenceName</type>
        <type tag="111" count="2" code="t" variant="madsrdf:NameTitle">madsrdf:NameTitle</type>
        <type tag="111" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="130" equivalent="t" count="1" code="a" variant="madsrdf:Title">madsrdf:Title</type> (: UniformTitle - this could have any number of code fields in it :)
        <type tag="130" count="2" code="d" variant="madsrdf:Title">madsrdf:Title</type> (: UniformTitle - this could have any number of code fields in it :)
        <type tag="130" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: UniformTitle - this could have any number of code fields in it :)
        
        <type tag="148" equivalent="y" count="1" code="a" variant="madsrdf:Temporal">madsrdf:Temporal</type>
        <type tag="148" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: loads of codes :)
        
        <type tag="150" equivalent="x" count="1" code="a" variant="madsrdf:Topic">madsrdf:Topic</type>
        <type tag="150" count="2" code="bvxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="151" equivalent="z" count="1" code="a" variant="madsrdf:Geographic">madsrdf:Geographic</type>
        <type tag="151" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="155" equivalent="v" count="1" code="a" variant="madsrdf:GenreForm">madsrdf:GenreForm</type>
        <type tag="155" equivalent="p" count="1" variant="madsrdf:GenreForm">madsrdf:GenreForm</type>
        <type tag="155" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="162" count="1" code="a" variant="madsrdf:Medium">madsrdf:Medium</type>
        
        <type tag="180" count="1" code="x" variant="madsrdf:Topic">madsrdf:Topic</type>
        <type tag="180" count="2" code="vyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>

        <type tag="181" count="1" code="z" variant="madsrdf:Geographic">madsrdf:Geographic</type>
        <type tag="181" count="2" code="z" variant="madsrdf:HierarchicalGeographic">madsrdf:HierarchicalGeographic</type>
        <type tag="181" count="2" code="vxy" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="182" count="1" code="y" variant="madsrdf:Temporal">madsrdf:Temporal</type>
        <type tag="182" count="2" code="vxz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="185" count="1" code="v" variant="madsrdf:GenreForm">madsrdf:GenreForm</type>
        <type tag="185" count="2" code="xyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
    </authTypeMaps>);
    
declare variable $marcxml2madsrdf:elementTypeMap := (
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
        <elementType tag_suffix="30" code="a" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="s">madsrdf:SubTitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="k">madsrdf:GenreFormElement</elementType>
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
        
        <elementType tag_suffix="62" code="a">madsrdf:MediumElement</elementType>
        
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
    </elementTypeMaps>);

declare variable $marcxml2madsrdf:marc2madsMap := (<marc2madsMap>
        <map tag_suffix="00" count="1" subfield="a">
            <authority>madsrdf:PersonalName</authority>
            <variant>madsrdf:PersonalName</variant>
        </map>
        <map tag_suffix="00" count="2" subfield="cdgq">
            <authority>madsrdf:PersonalName</authority>
            <variant>madsrdf:PersonalName</variant>
        </map>
        <map tag_suffix="00" count="2" subfield="t">
            <authority>madsrdf:NameTitle</authority>
            <variant>madsrdf:NameTitle</variant>
        </map>
        <map tag_suffix="00" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="10" count="1" subfield="a">
            <authority>madsrdf:CorporateName</authority>
            <variant>madsrdf:CorporateName</variant>
        </map>
        <map tag_suffix="10" count="2" subfield="bcdg">
            <authority>madsrdf:CorporateName</authority>
            <variant>madsrdf:CorporateName</variant>
        </map>
        <map tag_suffix="10" count="2" subfield="t">
            <authority>madsrdf:NameTitle</authority>
            <variant>madsrdf:NameTitle</variant>
        </map>
        <map tag_suffix="10" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="11" count="1" subfield="a">
            <authority>madsrdf:ConferenceName</authority>
            <variant>madsrdf:ConferenceName</variant>
        </map>
        <map tag_suffix="11" count="2" subfield="cdgq">
            <authority>madsrdf:ConferenceName</authority>
            <variant>madsrdf:ConferenceName</variant>
        </map>
        <map tag_suffix="11" count="2" subfield="t">
            <authority>madsrdf:NameTitle</authority>
            <variant>madsrdf:NameTitle</variant>
        </map>
        <map tag_suffix="11" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="30" count="1" subfield="a" variant_subfield="t"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:Title</authority>
            <variant>madsrdf:Title</variant>
        </map>
        <map tag_suffix="30" count="2" subfield="d"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:Title</authority>
            <variant>madsrdf:Title</variant>
        </map>
        <map tag_suffix="30" count="2" subfield="t"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:Title</authority>
            <variant>madsrdf:Title</variant>
        </map>
        <map tag_suffix="30" count="2" subfield="vxyz"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="48" count="1" subfield="a" variant_subfield="y">
            <authority>madsrdf:Temporal</authority>
            <variant>madsrdf:Temporal</variant>
        </map>
        <map tag_suffix="48" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="50" count="1" subfield="a" variant_subfield="x">
            <authority>madsrdf:Topic</authority>
            <variant>madsrdf:Topic</variant>
        </map>
        <map tag_suffix="50" count="2" subfield="bvxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="51" count="1" subfield="a" variant_subfield="z">
            <authority>madsrdf:Geographic</authority>
            <variant>madsrdf:Geographic</variant>
        </map>
        <map tag_suffix="51" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="55" count="1" subfield="a" variant_subfield="vpk">
            <authority>madsrdf:GenreForm</authority>
            <variant>madsrdf:GenreForm</variant>
        </map>
        <map tag_suffix="55" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="62" count="1" subfield="a">
            <authority>madsrdf:Medium</authority>
            <variant>madsrdf:Medium</variant>
        </map>
        
        <map tag_suffix="80" count="1" subfield="x">
            <authority>madsrdf:Topic</authority>
            <variant>madsrdf:Topic</variant>
        </map>
        <map tag_suffix="80" count="2" subfield="vyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="81" count="1" subfield="z">
            <authority>madsrdf:Geographic</authority>
            <variant>madsrdf:Geographic</variant>
        </map>
        <map tag_suffix="81" count="2" subfield="z">
            <authority>madsrdf:HierarchicalGeographic</authority>
            <variant>madsrdf:HierarchicalGeographic</variant>
        </map>
        <!--
        kefo note - 2021 Nov 4
        This commented out pattern doesn't appear in the system, but we want 
        to allow the preceding (new) pattern for the 781s.
        <map tag_suffix="81" count="2" subfield="vxy">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        -->
        
        <map tag_suffix="82" count="1" subfield="y">
            <authority>madsrdf:Temporal</authority>
            <variant>madsrdf:Temporal</variant>
        </map>
        <map tag_suffix="82" count="2" subfield="vxz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="85" count="1" subfield="v">
            <authority>madsrdf:GenreForm</authority>
            <variant>madsrdf:GenreForm</variant>
        </map>
        <map tag_suffix="85" count="2" subfield="yxz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
    </marc2madsMap>);    
    
declare variable $marcxml2madsrdf:noteTypeMap := (
    <noteTypeMaps>
        <type tag="667">madsrdf:editorialNote</type>
        <type tag="678">madsrdf:note</type>
        <type tag="680">madsrdf:note</type>
        <type tag="681">madsrdf:exampleNote</type>
        <type tag="682">madsrdf:changeNote</type>
        <type tag="688">madsrdf:historyNote</type>  
		<type tag="260">madsrdf:editorialNote</type>   
		<type tag="360">madsrdf:editorialNote</type>   
    </noteTypeMaps>);
    
    
declare variable $marcxml2madsrdf:relationTypeMap := (
    <relationTypeMaps>
        <type tag_prefix="5" pos="1" w="a">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_prefix="5" pos="1" w="b">madsrdf:hasLaterEstablishedForm</type>
        <type tag_prefix="5" pos="1" w="d">madsrdf:hasAcronymVariant</type>
        <type tag_suffix="5" pos="1" w="g">madsrdf:hasBroaderAuthority</type>
        <type tag_suffix="5" pos="1" w="h">madsrdf:hasNarrowerAuthority</type>
        <type tag_suffix="5" pos="1" w="r">madsrdf:hasRelatedAuthority</type>
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
       
    </relationTypeMaps>);
    
declare variable $marcxml2madsrdf:variantTypeMap := (
    <variantTypeMaps>        
        <type tag="400" count="1">madsrdf:PersonalName</type>
        <type tag="400" count="2" code="cdgq">madsrdf:PersonalName</type>
        <type tag="400" count="2" code="t">madsrdf:NameTitle</type> (: Would title ever not be in the second position?  Is it still an NT when there is a third term, a form subdivision? :) :)
        <type tag="400" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="410" count="1">madsrdf:CorporateName</type>
        <type tag="410" count="2" code="t">madsrdf:NameTitle</type> (: this implies that t is the second component :)
        <type tag="410" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="411" count="1">madsrdf:ConferenceName</type>
        <type tag="411" count="2" code="t">madsrdf:NameTitle</type>
        <type tag="411" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="430" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: UniformTitle - this could have any number of code fields in it :)
        
        <type tag="448" equivalent="y" count="1" code="a">madsrdf:Temporal</type>
        <type tag="448" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: loads of codes :)
        
        <type tag="450" equivalent="x" count="1" code="a">madsrdf:Topic</type>
        <type tag="450" count="2" code="vxyz">madsrdf:ComplexSubject</type>
       
        <type tag="451" equivalent="z" count="1" code="a">madsrdf:Geographic</type>
        <type tag="451" count="2" code="vxyz">madsrdf:ComplexSubject</type>
        
        <type tag="455" equivalent="v" count="1" code="a">madsrdf:GenreForm</type>
        <type tag="455" count="2" code="vxyz">madsrdf:ComplexSubject</type>
        
        <type tag="462" count="1" code="a">madsrdf:Medium</type>
        
        <type tag="480" count="1" code="a">madsrdf:Topic</type>
        <type tag="480" count="2" code="vxyz">madsrdf:ComplexSubject</type>
    </variantTypeMaps>);
 

(:~
:   This is the main function.  It converts MARCXML to MADSRDF.
:   It takes the MARCXML as the first argument.
:
:   @param  $marcxml        node() is the MARC XML
:   @return rdf:RDF element of MADS RDF/XML
:)
declare function marcxml2madsrdf:marcxml2madsrdf($marcxml)
as element(rdf:RDF)
{
    let $marc001 := fn:replace( $marcxml/marcxml:controlfield[@tag='001'] , ' ', '')
    (: LC Specific :)
    let $scheme :=
        if (fn:substring($marc001, 1, 1) eq 's') then
            "subjects"
        else if (fn:substring($marc001, 1, 1) eq 'n') then
            "names"
        else if (fn:substring($marc001, 1, 2) eq 'gf') then
            "genreForms"
        else if (fn:substring($marc001, 1, 1) eq 'm') then
            "performanceMediums"
		else if (fn:substring($marc001, 1, 2) eq 'dg') then
            "demographicTerms"
        else
            "empty"
    let $owlSameAs := 
        if ($scheme eq "subjects") then
            (
                element owl:sameAs {
                    attribute rdf:resource { fn:concat("info:lc/authorities/" , $marc001) }
                },
                element owl:sameAs {
                    attribute rdf:resource { fn:concat("http://id.loc.gov/authorities/" , $marc001 , "#concept") }
                }
            )
        else ()
    (: LC Specific :)         
    let $df682 := $marcxml/marcxml:datafield[@tag='682'][1] (: can there every be more than one? :)
    let $leader_pos05 := fn:substring($marcxml/marcxml:leader, 6 ,1)
    let $deleted := 
        if ($leader_pos05 eq "d") then
            fn:true()
        else
            fn:false()
    let $df1xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'1')] (: should only be one? :)
    let $df1xx_suffix := fn:substring($df1xx/@tag, 2, 2)
    let $df1xx_sf_counts := fn:count($df1xx/marcxml:subfield)
    let $df1xx_sf_two_code := $df1xx/marcxml:subfield[2]/@code
    let $authoritativeLabel := marcxml2madsrdf:generate-label($df1xx,$df1xx_suffix)
                
    let $authorityType := 
			if ($scheme="demographicTerms") then
				"madsrdf:Authority"
			else
				marcxml2madsrdf:get-authority-type($df1xx, fn:true(), $scheme)
    let $useFor := 
       for $sf in  $marcxml/marcxml:datafield[@tag='010']/marcxml:subfield[@code="z"]
            return marcxml2madsrdf:create-useFor-relation($sf, $authorityType)
              
    let $components := 
        if ($deleted) then
            marcxml2madsrdf:create-components-from-DFxx($df1xx, fn:false(), $scheme)
        else
            marcxml2madsrdf:create-components-from-DFxx($df1xx, fn:true(), $scheme)
    let $componentList := 
        if ($components and $deleted) then marcxml2madsrdf:create-component-list($components, fn:false()) 
        else if ($components) then marcxml2madsrdf:create-component-list($components, fn:true())
        else ()
        
    let $elements := marcxml2madsrdf:create-elements-from-DFxx($df1xx, $scheme)
    let $elementList := 
        if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
        else ()

    let $classification := 
        for $df in $marcxml/marcxml:datafield[@tag='053']
        return marcxml2madsrdf:create-classifications($df)
    
    let $fullerName := 
        if ($marcxml/marcxml:datafield[@tag='378']/marcxml:subfield[@code='q']) then
           element madsrdf:fullerName {
               element madsrdf:PersonalName{
                element rdfs:label {$marcxml/marcxml:datafield[@tag='378']/marcxml:subfield[@code='q']/text()},
                for $sf in $marcxml/marcxml:datafield[@tag='378']/marcxml:subfield[fn:matches(@code, '(u|v)')]
                return 
                   element madsrdf:hasSource {
                     element madsrdf:Source{
                        element rdfs:label {$sf/text()}
                   }}
            }}
         else()
             
    let $creationDate :=        
        for $cd in $marcxml/marcxml:datafield[@tag='046']
        let $source:=if ($cd/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($cd/marcxml:subfield[@code='2']),") ") else ("")
        return
            (if ($cd/marcxml:subfield[@code='k']) then
                 element madsrdf:creationDateStart {
                    element skos:Concept {
                       element rdfs:label{fn:concat($source, $cd/marcxml:subfield[@code='k']/text())},
                       for $sf in $cd/marcxml:subfield[fn:matches(@code, '(u|v)')]
                       return 
                          element madsrdf:hasSource {
                             element madsrdf:Source{
                                element rdfs:label {$sf/text()}
                           }}
                   }}
               else (),
             if ($cd/marcxml:subfield[@code='l']) then
                 element madsrdf:creationDateEnd {
                    element skos:Concept {
                       element rdfs:label{fn:concat($source, $cd/marcxml:subfield[@code='l']/text())},
                       for $sf in $cd/marcxml:subfield[fn:matches(@code, '(u|v)')]
                       return 
                          element madsrdf:hasSource {
                             element madsrdf:Source{
                                element rdfs:label {$sf/text()}
                           }}
                   }}
             else ()
             )
             
(:    let $formOfWork :=        
        for $ev in $marcxml/marcxml:datafield[@tag='380']
	    let $source:=if ($ev/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($ev/marcxml:subfield[@code='2']),") ") else ("")
        return 
            (for $sf in $ev/marcxml:subfield[@code='a']
             return 
                element madsrdf:elementValue {
                  element madsrdf:GenreFormElement {
                    element rdfs:label {fn:concat($source,$sf/text())},
                    for $sf in $ev/marcxml:subfield[@code='0']
                    return 
                       element madsrdf:hasSource {
                         element madsrdf:Source{
                            element rdfs:label {$sf/text()}
                       }}
                }}
            ) :)
    let $formOfWork :=        
        for $ev in $marcxml/marcxml:datafield[@tag='380']
	    let $source:=if ($ev/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($ev/marcxml:subfield[@code='2']),") ") else ("")
         return element madsrdf:elementList {
            attribute rdf:parseType {"Collection"},
            for $sf in $ev/marcxml:subfield[@code='a']
             return element madsrdf:GenreFormElement {
                element madsrdf:elementValue {fn:concat($source,$sf/text())}
                },
            for $sf in $ev/marcxml:subfield[@code='0']
            return 
              element madsrdf:hasSource {
               element madsrdf:Source{
                 element rdfs:label {$sf/text()}
                }}                
            } 
         
     let $workOrigin :=        
        for $wo in $marcxml/marcxml:datafield[@tag='370']
        let $source:=if ($wo/marcxml:subfield[@code='2'][1]) then fn:concat("(", fn:string($wo/marcxml:subfield[@code='2'][1]),") ") else ("")
        return        
            (for $sf in $wo/marcxml:subfield[@code='g']
              return element madsrdf:workOrigin { 
                     element madsrdf:Geographic {
                       element rdfs:label {fn:concat($source,$sf/text())},
                       for $sf in $wo/marcxml:subfield[fn:matches(@code,'(v|u|0)')]
                       return 
                             element madsrdf:hasSource {
                               element madsrdf:Source{
                                 element rdfs:label {$sf/text()}
                             }}
                     }}
             )
            
    let $hasCharacteristic :=        
        for $hc in $marcxml/marcxml:datafield[@tag='381']
        let $source:=if ($hc/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($hc/marcxml:subfield[@code='2']),") ") else ("")
        return
           (for $sf in $hc/marcxml:subfield[@code='a']
            return 
                element madsrdf:hasCharacteristic {
                    element skos:Concept {
                       element rdfs:label{fn:concat($source, $sf/text())},
                       for $sf in $hc/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                       return 
                          element madsrdf:hasSource {
                             element madsrdf:Source{
                                element rdfs:label {$sf/text()}
                           }}
                   }}
            )

    let $df4xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'4')]
    let $variants := 

        for $df in $df4xx
        return element madsrdf:hasVariant { marcxml2madsrdf:create-variant($df, $scheme) }


    let $df4xx_w := $marcxml/marcxml:datafield[fn:starts-with(@tag,'4') and marcxml:subfield[1]/@code="w"]
    let $relations_df4xx := 
        if ($df4xx_w) then
            for $df in $df4xx_w
                return marcxml2madsrdf:create-relation($df, $scheme)
        else ()
                
    let $df5xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'5')]
    let $relations := 
        if ($df5xx) then
            for $df in $df5xx
                return marcxml2madsrdf:create-relation($df, $scheme)
        else ()
    let $hasLater_relation := 
         if ($deleted and $df682) then
            marcxml2madsrdf:create-hasLaterForm-relation($df682, $authorityType, $scheme)
        else 
            ()
    
    let $hasExactMatchViaf := 
        if ($scheme eq "names" and fn:not(fn:contains($marc001, '-781'))) then 
           (: let $viaf_uri := fn:concat("http://viaf.org/viaf/sourceID/LC%7C", xs:string($marcxml/marcxml:controlfield[@tag='001']), "#skos:Concept"):)
           let $df010a := xs:string($marcxml/marcxml:datafield[@tag='010']/marcxml:subfield[@code='a'])
           let $df010a := fn:replace($df010a, "^[ ]+|[ ]+$", "")
           let $df010a := fn:replace($df010a, "[ ]", "+")
           let $viaf_uri := fn:concat("http://viaf.org/viaf/sourceID/LC%7C", $df010a, "#skos:Concept")
            return <madsrdf:hasExactExternalAuthority rdf:resource="{$viaf_uri}"/>
        else
            ()
            
    let $standardIdentifierRelations := 
        (
            for $i in $marcxml/marcxml:datafield[@tag eq '024']/marcxml:subfield[@code eq '0']
            let $i_uri := xs:string($i)
            where shared:validate-uri($i_uri)
            return <madsrdf:hasExactExternalAuthority rdf:resource="{$i_uri}" />,
            
            for $i in $marcxml/marcxml:datafield[@tag eq '024']/marcxml:subfield[@code eq '1']
            let $i_uri := xs:string($i)
            where shared:validate-uri($i_uri)
            return <madsrdf:identifiesRWO rdf:resource="{$i_uri}" />
        )
    
    let $dfSources := $marcxml/marcxml:datafield[fn:matches(@tag , '670|675')]
    let $sources := 
        if ($dfSources) then
            for $df in $dfSources
                return element madsrdf:hasSource { marcxml2madsrdf:create-source($df, $scheme) }
        else ()
        
    let $dfNotes := ( $marcxml/marcxml:datafield[fn:matches(@tag , '667|678|680|681|688')],
			 			if ($scheme eq "subjects") then
							$marcxml/marcxml:datafield[@tag ='260']
						else (),
						if ($scheme eq "subjects") then
							$marcxml/marcxml:datafield[@tag ='360']
						else ()
				)
    let $notes := 
        if ($dfNotes) then
            for $df in $dfNotes
                return marcxml2madsrdf:create-notes($df,$scheme)
        else ()
        
    let $delNote :=
        if ($deleted and $df682) then
             marcxml2madsrdf:create-deletion-note($df682, $scheme)
        else ()
        
    let $rwoClass := 
        if ($scheme eq "names") then
            marcxml2madsrdf:create-rwoClass( $marcxml, $marc001 )
        else
            ()

    let $identifiers :=
        (
            if ( fn:not(fn:contains($marc001, '-781')) ) then
                element identifiers:lccn { fn:normalize-space($marcxml/marcxml:datafield[@tag eq "010"][1]/marcxml:subfield[@code eq "a"][1]) }
            else
                (),
            
            for $i in $marcxml/marcxml:datafield[@tag eq "020"]
            let $code := fn:normalize-space($i/marcxml:subfield[@code eq "2"])
            let $iStr := fn:normalize-space(xs:string($i/marcxml:subfield[@code eq "a"]))
            where $iStr ne ""
            return
                if ( $code ne "" ) then
                    element { fn:concat("identifiers:" , $code) } { $iStr }
                else 
                    element identifiers:local { $iStr },
                    
            for $i in $marcxml/marcxml:datafield[@tag eq "035"]/marcxml:subfield[@code eq "a"][fn:not( fn:contains(. , "DLC") )]
            let $iStr := xs:string($i)
            return
                if ( fn:contains($iStr, "(OCoLC)" ) ) then
                    (: element identifiers:oclcnum { fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) } :)
					element identifiers:local { fn:normalize-space($iStr) }
                else 
                    element identifiers:local { fn:normalize-space($iStr) }
        )
        
    let $ri := marcxml2recordinfo:recordInfoFromMARCXML($marcxml)
    let $adminMetadata := 
        for $r in $ri
        return element madsrdf:adminMetadata { $r }
    
    let $marc008_pos6 := fn:substring($marcxml/marcxml:controlfield[@tag='008'], 7 ,1)
    let $geo_sub := 
        if ($marc008_pos6 eq "d" or $marc008_pos6 eq "i") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_SubdivideGeographically'}
                
            }        
        else ()
        
    let $marc008_pos9 := fn:substring($marcxml/marcxml:controlfield[@tag='008'], 10 ,1)
    let $kind_of_record := 
        if ($marc008_pos9 eq 'a' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesAuthorizedHeadings'}
        }
        else if ($marc008_pos9 eq 'a' and $scheme eq "subjects" and fn:substring($marc001,1, 2) eq "sh") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSHAuthorizedHeadings'}
            }
        else if ($marc008_pos9 eq 'a' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesAuthorizedHeadings'}
            }
        else if ($marc008_pos9 eq 'd') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_Subdivisions'}
            }
        else if ($marc008_pos9 eq 'f') then
            (: this does not seem to apply to names :)
            (
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSHAuthorizedHeadings'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_Subdivisions'}
                }
            )		
            
        else if ($marc008_pos9 eq 'b' and $scheme eq "subjects") then
                (element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_UntracedReference'}
                }    ,
				
                element madsrdf:editorialNote {"Reference record only; not a valid heading."}				
				)
        else ()
        
    let $marc008_pos17 := fn:substring($marcxml/marcxml:controlfield[@tag='008'], 18 ,1)
    let $subdivision_type := 
        if ($marc008_pos17 eq 'a') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_TopicSubdivisions'}
            }
        else if ($marc008_pos17 eq 'b') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GenreFormSubdivisions'}
            }
        else if ($marc008_pos17 eq 'c') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_TemporalSubdivisions'}
            }
        else if ($marc008_pos17 eq 'd') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GeographicSubdivisions'}
            }
        else if ($marc008_pos17 eq 'e') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LanguageSubdivisions'}
            }
        else ()
        
     let $frbr_kind:= (:100, 110, 100 with $t is a title or nametitle 130 with anything is a title. if it has a language or arrangement, it's an expression, otherwise, it's a work:)
            if ($authorityType="madsrdf:Title" or $authorityType="madsrdf:NameTitle") then (:its at least a work:)         	    	
                ( (:$l=language, $o=arrangment for music:) 
                    if ($df1xx/marcxml:subfield[@code="l" or @code="o"]) then (:expression:)
                        element madsrdf:isMemberOfMADSCollection { 
			                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_FRBRExpression'}
			            }
			        else
			        	element madsrdf:isMemberOfMADSCollection { 
			                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_FRBRWork'}
			            }
                )
            else () 
    (: commenting out for the time being :)
    (:
    let $df100_subdivision_type := 
        if ($df1xx_suffix='80') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_TopicalSubdivisions'}
            }
        else if ($df1xx_suffix='85') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GenreSubdivisions'}
            }
        else if ($df1xx_suffix='82') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_ChronologicalSubdivisions'}
            }
        else if ($df1xx_suffix='81') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GeographicSubdivisions'}
            }
        else ()
    :)
    let $undiff :=
        if ( fn:substring($marcxml/marcxml:controlfield[@tag='008'], 33 ,1) eq 'b' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesUndifferentiated'}
        }
        else ()
        
    let $jurisdiction := 
        if ($marcxml/marcxml:datafield[@tag="110"][@ind1="1"] and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_Jurisdictions'}      
            }        
        else ()
	
    let $marc001_prefix := fn:substring( $marc001 , 1 , 2 )        
    let $marc001_prefix_type := 
        if ($marc001_prefix='sh') then
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSH_General'}
                }
            )
        else if ($marc001_prefix='sj') then
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/childrensSubjects'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSH_Childrens'}
                }
            )
        else if ( fn:contains($marc001_prefix, "n") ) then
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/names'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_LCNAF'}
                }
            )
        else if ($marc001_prefix='gf' ) then
            (: should this also be a part of genreForm concept scheme.  Yes.  But it will break something. :)
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/genreForms'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/genreForms/collection_LCGFT_General'}
                }
            )
        else if ( fn:contains($marc001_prefix, "mp") ) then
            (: should this also be a part of genreForm concept scheme.  Yes.  But it will break something. :)
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/performanceMediums'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/performanceMediums/collection_LCMPT_General'}
                }
            )
			 else if ( fn:contains($marc001_prefix, "dg") ) then
            (: should this also be a part of demographicTerms concept scheme.  Yes.  But it will break something. :)
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/demographicTerms'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/demographicTerms/collection_LCDGT_General'}
                }
            )
        else ()
        
    let $pattern_headings := 
        (
		for $ph in $marcxml/marcxml:datafield[@tag='073' and marcxml:subfield[@code='z']='lcsh']/marcxml:subfield[@code='a']
            return
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {fn:concat('http://id.loc.gov/authorities/subjects/collection_PatternHeading' , fn:replace($ph , ' ' , ''))}
                },
		for $ph in $marcxml/marcxml:datafield[@tag='072' and marcxml:subfield[@code='2']='lcsh']/marcxml:subfield[@code='a']
            return
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {fn:concat('http://id.loc.gov/authorities/subjects/collection_PatternHeading' , fn:replace($ph , ' ' , ''))}
                }
		)
                
    let $use_pattern_collection := 
        for $ph in $marcxml/marcxml:datafield[@tag='072' and marcxml:subfield[@code='2']='lcsh']/marcxml:subfield[@code='a']
        return
            element madsrdf:usePatternCollection { 
                attribute rdf:resource {fn:concat('http://id.loc.gov/authorities/subjects/collection_PatternHeading' , fn:replace($ph , ' ' , ''))}
        }

   let $dgtCategory_collection := 
        for $ph in $marcxml/marcxml:datafield[@tag='072' and marcxml:subfield[@code='2']='lcdgt']/marcxml:subfield[@code='a']
        return
            if($ph) then
              (  element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource { fn:concat("http://id.loc.gov/authorities/demographicTerms/" , fn:replace($ph, ' ', '')) }   
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource { fn:concat("http://id.loc.gov/authorities/demographicTerms/" , $marcxml2madsrdf:dgtCategoryMap/dgtCategory[@code=$ph]/text()) }
                } )
             else ()
             
                
    let $scheme := 
        if ($marc001_prefix='sj') then
            "childrensSubjects"
        else
            $scheme
    
    let $rdf := 
        if ($deleted) then
            let $variant := 
                element {$authorityType} {
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $marcxml2madsrdf:authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Variant") }
                    },
                    (: all "deleted" or "cancelled" records are Variants AND DeprecatedAuthorities :) 
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "DeprecatedAuthority") }
                    },
                (:
                This makes Variant the root element, and the MADSType part of rdf:type
                element {"Variant"} {
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($authorityType, "madsrdf:", "") ) }
                    },
                :)
                    element madsrdf:variantLabel {
                      if ($scheme eq "names") then
                        text {$authoritativeLabel}
                      else 
                       ( attribute xml:lang {"en"},
                        text {$authoritativeLabel} )
                    }, 
                    $componentList,
                    $elementList,
                    $hasLater_relation,
                    $delNote,
                    $notes,
                    (: $marc001_prefix_type, :) (: Scheme and membership associations.  Not desirable for "cancelled" authorities :)
                    $owlSameAs,
                    $rwoClass,
                    $adminMetadata
                }
            return $variant
        else 
            let $authority := 
                element {$authorityType} {
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $marcxml2madsrdf:authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Authority" ) }
                    },
                (:
                    This makes Authority the root element, and the MADSType part of rdf:type
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($authorityType, "madsrdf:", "") ) }
                    },
                :)    
                    element madsrdf:authoritativeLabel {
                    if ($scheme eq "names") then
                        text {$authoritativeLabel}
                    else (
                        attribute xml:lang {"en"},
                        text {$authoritativeLabel}
                     )
                    },			
					
                    $componentList,
                    $elementList,
                    $classification,
                    $kind_of_record,
                    $subdivision_type,
                    (: $df100_subdivision_type, :)
                    $marc001_prefix_type,
                    $geo_sub,
                    $pattern_headings,
                    $use_pattern_collection,
                    $dgtCategory_collection,
                    $undiff,
                    $frbr_kind,
                    $rwoClass,
                    $jurisdiction,
                    $fullerName,
                    $creationDate,
                    $formOfWork,
                    $workOrigin,
                    $hasCharacteristic,
                    $variants,
                    $useFor,        
                    $relations_df4xx,
                    $relations, 
                    $hasExactMatchViaf,
                    $standardIdentifierRelations,
                    $sources,
                    $notes,
                    $identifiers,
                    $owlSameAs,
                    $adminMetadata
                }
            return $authority

    return <rdf:RDF 
				xmlns:marcxml       = 	"http://www.loc.gov/MARC21/slim"
				xmlns:skos			=	"http://www.w3.org/2004/02/skos/core#"
				xmlns:madsrdf       =	"http://www.loc.gov/mads/rdf/v1#"
				xmlns:rdf           = 	"http://www.w3.org/1999/02/22-rdf-syntax-ns#"
				xmlns:rdfs          = 	"http://www.w3.org/1999/02/22-rdf-schema#"
				xmlns:owl           = 	"http://www.w3.org/2002/07/owl#"
				xmlns:identifiers   = 	"http://id.loc.gov/vocabulary/identifiers/"

	>{$rdf}</rdf:RDF>

};




(:
-------------------------

    Creates Classification Properties:
    
        $marc053 as element() is the marc 053 datafield 

-------------------------
:)
declare function marcxml2madsrdf:create-classifications($marc053 as element()) as element() {
    let $assignedByLC := 
        if ($marc053/@ind2 eq '0') then
            (: LC assigned means LC Classification :)
            xs:boolean(1)
        else 
            xs:boolean(0)
    let $assignedByOther := 
        if ($marc053/@ind2 eq '4') then
            (: LC assigned means LC Classification :)
            xs:boolean(1)
        else 
            xs:boolean(0)
        
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

    return
        element madsrdf:classification { 
            element lcc:ClassNumber {
                element madsrdf:code {$text},
                if ($assignedByLC) then
                    <bf:assigner rdf:resource="http://id.loc.gov/vocabulary/organizations/dlc" />
                else if ($assignedByOther and fn:exists($marc053/marcxml:subfield[@code = '5'])) then
                    for $sf in $marc053/marcxml:subfield[@code eq '5']
                    return <bf:assigner rdf:resource="http://id.loc.gov/vocabulary/organizations/{fn:replace(fn:lower-case(xs:string($sf)), ' ', '')}" />
                else
                    ()
            }
       }

};



(:~
:   Creates a Component, aka an Authority.
:
:   @param  $sf        element() is the subfield
:   @param  $pos       as xs:integer is the position in the loop
:   @param  $authority as xs:boolean denotes whether this is an Authority or Variant    
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-component(
        $sf as element(), 
        $pos as xs:integer, 
        $authority as xs:boolean,
        $scheme) as element()*
{
    let $c := $sf/@code
    let $df_suffix := fn:substring($sf/../@tag , 2 , 2)
	let $df_ind1 := fn:string($sf/../@ind1)
    let $aORv := 
        if ($authority) then
            "Authority"
        else
            "Variant"
    let $type :=
        if ($authority) then
            if ($pos lt 2) then
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1']/authority
            else
                $marcxml2madsrdf:marc2madsMap/map[fn:contains(@variant_subfield , $c) and @count='1']/authority
        else
            if ($pos lt 2) then
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1']/variant
            else
                $marcxml2madsrdf:marc2madsMap/map[fn:contains(@variant_subfield , $c) and @count='1']/variant

    
	(: let $label := $sf/text() :)
	            
    let $labelProperty := 
        if ($authority) then
            "madsrdf:authoritativeLabel"
        else
            "madsrdf:variantLabel"
    
    let $elements := marcxml2madsrdf:create-element($sf, 1, $scheme)
    let $elementList := 
        if ($elements) then marcxml2madsrdf:create-element-list($elements) 
        else ()
      
    let $label := fn:string-join($elements, ' ')
    let $label := 
        if ( fn:ends-with($label, ".") and fn:not(fn:contains($type, "Name")) ) then
            fn:substring($label, 1, (fn:string-length($label) - 1))
        else 
            $label
    (: let $nodeID := marcxml2madsrdf:generate-nodeID($label,$authority) :)
    
        
    (:
    let $elements := marcxml2madsrdf:create-elements-from-DFxx($sf/parent::node()[1])
    let $elementList := 
        if ($elements) then marcxml2madsrdf:create-element-list($elements) 
        else ()
    :)
    
    (: fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($type, "madsrdf:", "") ) :)
            
    let $component := 
        if ($type ne "") then
            element {$type} {
                (: attribute rdf:nodeID {$nodeID}, :)
                element rdf:type {
                    attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                }, 
                element {$labelProperty} {
                  if ($scheme eq "names") then
                    text {$label}
                  else (
                    attribute xml:lang {"en"},
                    text {$label} 
                   )
                },
                $elementList
            }
        else ()
    return $component
};


(:~
:   Creates a componentList
:
:   @param  $component_elementlist  as element() holds the component
:   @param  $counts                 as xs:integer is the number of subfields
:   @param  $authority              as xs:boolean denotes whether this is an Authority or Variant    
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-component-list($component_elementlist, $authority as xs:boolean) {
    let $component_list :=   
        element {"madsrdf:componentList"} {
            attribute rdf:parseType {"Collection"},
            $component_elementlist
        }
    return $component_list
};



(:
-------------------------

    Returns Component from a 1xx or 4xx marcxml:datafield
    
        $df as element() is the relevant marcxml:datafield
        $counts as is the number of subfields
        $authority as xs:boolean denotes whether this is an Authority or Variant

-------------------------
:)
declare function marcxml2madsrdf:create-components-from-DFxx($df as element(), $authority as xs:boolean, $scheme) {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $components := 
        if ( 
                ( $df/marcxml:subfield[@code eq 'a'] 
                and ($df/marcxml:subfield[fn:matches(@code , "t|v|x|y|z")]) 
                and ($df_suffix ne "30") )
                or
                ( fn:matches($df/@tag , '80|81|82|85') and
                fn:count($df/marcxml:subfield[@code ne "w"]) gt 1 ) 
            ) then
            for $f at $pos in $df/marcxml:subfield[fn:matches(@code , "a|t|v|x|y|z")]
                let $component := marcxml2madsrdf:create-component($f, $pos, $authority, $scheme)
                return $component
        else ()
    return $components
};




(:
-------------------------

    Creates MADS Deletion Note:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:create-deletion-note($df as element(), $scheme) as element() {
    
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
          if ($scheme eq "names") then
            text {$text}
          else (
            attribute xml:lang {"en"},
            text {$text} 
          )
        }
        
    return $note
};





(:
-------------------------

    Creates Element:
    
        $sf as element() is the subfield
        $pos as xs:integer is the position in the loop

-------------------------
:)
declare function marcxml2madsrdf:create-element($sf, $pos, $scheme) {
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
                      if ($scheme eq "names") then
                        $label
                      else (
                        attribute xml:lang {"en"},
                        $label ) 
                    }
                }
        else ()
    let $extras := 
        if ($pos=1) then
            for $dfc in $sf/following-sibling::node()
                let $el := $marcxml2madsrdf:elementTypeMap/elementType[@tag_suffix=$tag_suffix and @code=$sf/@code and @ancillary=$dfc/@code]/text()
                return 
                    if ($el and $tag_suffix eq "30") then
                        element {$el} {
                            element madsrdf:elementValue {
                              if ($scheme eq "names") then
                                text {$dfc}
                              else (
                                attribute xml:lang {"en"},
                                text {$dfc} )
                            }
                        }
                    else if ($el and ($sf/@code="t" or ($dfc/@code!="t" and fn:not($dfc/preceding-sibling::node()[@code="t"])))) then
                        (: this seems a little forced, but we need to seperate the the name and title parts :) 
                        element {$el} {
                            element madsrdf:elementValue {
                              if ($scheme eq "names") then
                                text {$dfc}
                              else (
                                attribute xml:lang {"en"},
                                text {$dfc} )
                            }
                        }
                    else ()
        else ()

    return ($element , $extras)
};



(:
-------------------------

    Creates ElementList:
    
        $component_elementlist as element() holds the component
        $counts as is the number of subfields
        $authority as xs:boolean denotes whether this is an Authority or Variant

-------------------------
:)
declare function marcxml2madsrdf:create-element-list($elementlist) {
    let $e_list :=
            element madsrdf:elementList {
                attribute rdf:parseType {"Collection"},
                $elementlist
            }
    return $e_list
};



(:
-------------------------

    Returns Element from a 1xx or 5xx marcxml:datafield
    
        $df as element() is the relevant marcxml:datafield
        $counts as is the number of subfields
        $authority as xs:boolean denotes whether this is an Authority or Variant

-------------------------
:)
declare function marcxml2madsrdf:create-elements-from-DFxx($df as element(), $scheme) {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $elements := 
        if ( 
                ($df/marcxml:subfield[@code eq 'a'] or fn:matches($df_suffix , '80|81|82|85'))
            ) then
            for $f at $pos in $df/marcxml:subfield[fn:matches(@code , "a|v|x|y|z")]
                let $element := marcxml2madsrdf:create-element($f, $pos, $scheme)
                return $element
        else ()
    return $elements
};
(:~
:   Returns Elements for madsrdf:useFor relationships (probably names, but some subjects)
:   This, rightly or wrongly, assumes that the later Authority
:   is of the same MADSType as this Variant
:
:   @param  $sf             element() is the 010 $z subfield, cancelled lccn
:   @param  $authorityType  xs:string of MADSType
:   @return zero or more madsrdf:useFor elements
:)
declare function marcxml2madsrdf:create-useFor-relation(
    $sf as element(), 
    $authorityType as xs:string
    ) as element()* 
{

    let $cancelledlccn := fn:replace( fn:string($sf), " ","")
    let $relatedscheme := 
        if ( fn:starts-with($cancelledlccn, "sh") ) then
            (: presume this is LCSH :)
            "subjects"
        else if ( fn:starts-with($cancelledlccn, "sj") ) then
            (: presume this is LCSH :)
            "childrensSubjects"
        else if ( fn:starts-with($cancelledlccn, "gf") ) then                                        
            "genreForms"
		else if ( fn:starts-with($cancelledlccn, "mp") ) then                                        
            "performanceMediums"
        else if ( fn:starts-with($cancelledlccn, "dg") ) then                                        
            "demographicTerms"
        else if ( fn:starts-with($cancelledlccn, "n") ) then
            "names"
        else
            ""

    let $docuri := fn:concat("/authorities/", $relatedscheme , "/" , $cancelledlccn, ".xml")
    let $docexists := 
        if ($relatedscheme ne "") then
            fn:doc-available($docuri)
        else
            fn:false()

    return
        if ($cancelledlccn ne "" and $docexists) then
            element madsrdf:useFor {
                attribute rdf:resource { fn:concat( "http://id.loc.gov/authorities/" , $relatedscheme , "/" , $cancelledlccn ) }
            }
        else 
            ()
};

(:~
:   Returns Elements for hasLaterEstablishedForm relationships
:   This, rightly or wrongly, assumes that the later Authority
:   is of the same MADSType as this Variant
:
:   @param  $df             element() is the 682 datafield for parsing
:   @param  $authorityType  xs:string of MADSType
:   @return zero or more madsrdf:hasLaterEstablishedForm elements
:)
declare function marcxml2madsrdf:create-hasLaterForm-relation(
    $df as element(), 
    $authorityType as xs:string,
    $scheme
    ) as element()* 
{
    (:any subfield has covered by: :)
    let $objprop := 
            if ( fn:matches( xs:string($df) , 'covered by|will be issued' ) ) then
                "madsrdf:useInstead"
            else
                "madsrdf:hasLaterEstablishedForm"
    let $found_lccns := 
        for $sf in $df/marcxml:subfield
        let $found := fn:analyze-string(xs:string($sf), "(sh|sj|gf|no|nb|nr|ns|n|mp|dg)( )*([0-9]+)")
        return 
            for $f in $found/fn:match
                
            return fn:replace(fn:normalize-space(fn:string-join($f/fn:group, ""))," ","")
    
    let $properties := 
        for $relatedlccn in $found_lccns
        let $relatedscheme := 
            if ( fn:starts-with($relatedlccn, "sh") ) then
                (: presume this is LCSH :)
                "subjects"
            else if ( fn:starts-with($relatedlccn, "sj") ) then
                (: presume this is LCSH :)
                "childrensSubjects"
            else if ( fn:starts-with($relatedlccn, "gf") ) then                                        
                "genreForms"
            else if ( fn:starts-with($relatedlccn, "n") ) then
                "names"
            else if ( fn:starts-with($relatedlccn, "dg") ) then
                "demographicTerms"
            else if ( fn:starts-with($relatedlccn, "mp") ) then
                "demographicTerms"
            else
                ""
        return
            element {$objprop} {
                attribute rdf:resource { 
                    fn:concat( "http://id.loc.gov/authorities/" , $relatedscheme , "/" , $relatedlccn )
                }
            }
    return $properties
    
};


(:
-------------------------

    Creates MADS Notes:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:create-notes($df as element(), $scheme as xs:string) as element() {
    
    let $tag := $df/@tag
    let $type := $marcxml2madsrdf:noteTypeMap/type[@tag=$tag]/text()
    
    let $textparts :=
        for $sf in $df/marcxml:subfield
            let $str := 
                if ($sf/@code eq 'a') then
                     (: must have had a spectacularly good reason for this :)
                     (: too bad I cannot remember :)
                    fn:concat('[' , $sf/text() , ']')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
	let $note := element {$type} {$text}
        
    return $note
};



(:~
:   Creates MADS Relation
:
:   @param  $df        element() the relevant marcxml:datafield 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-relation($df as element(), $scheme) as element()* {
    
    let $tag := $df/@tag
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_counts := fn:count($df/marcxml:subfield[@code ne 'w'])
    let $df_sf_two_code := $df/marcxml:subfield[2]/@code
    let $label := marcxml2madsrdf:generate-label($df,$df_suffix)
    
    let $rdfabout := 
        if ( fn:exists($df/marcxml:subfield[@code='0']) ) then
            let $u := xs:string($df/marcxml:subfield[@code='0'][1])
            return
                if (shared:validate-uri($u)) then
                    attribute rdf:about {$u}
                else if ( fn:contains($u, "(DLC)") ) then
                    attribute rdf:about { fn:concat("http://id.loc.gov/authorities/names/", fn:replace($u, ' |\(DLC\)', '')) }
                else 
                    ()
        else
            ()
        
    let $relatedRWOs := 
        for $i in $df/marcxml:subfield[@code='1']
        return <madsrdf:identifiesRWO rdf:resource="{$i}" />
    
    let $wstr := xs:string($df/marcxml:subfield[@code='w'][1]/text())
    let $ws := fn:tokenize($wstr , "[a-z]")
    return
        if (fn:normalize-space($wstr) eq "" and $df/marcxml:subfield[@code='a']) then
            (: reciprocal relations :)
            let $type := "madsrdf:hasReciprocalAuthority"
            let $auth := fn:true()
            let $aORv := "Authority"
            let $authorityType := marcxml2madsrdf:get-authority-type($df,$auth, $scheme)
            let $labelProp := "madsrdf:authoritativeLabel" 
            let $components := marcxml2madsrdf:create-components-from-DFxx($df, $auth, $scheme)
            let $componentList := 
                if ($components) then marcxml2madsrdf:create-component-list($components, $auth) 
                else ()
            
            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df, $scheme)
            let $elementList := 
                if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
                else ()
        
            let $relation := 
                element {$type} {
                    element {$authorityType} {
                        $rdfabout,
                        element rdf:type {
                            attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                        },
                        element {$labelProp} { 
                          if ($scheme eq "names") then
                            text {$label}
                          else (
                            attribute xml:lang {"en"},
                            text {$label}
                          )
                        },
                        $componentList,
                        $elementList,
                        $relatedRWOs
                    }                    
                }
            return $relation
        else 
            for $c at $pos in fn:string-to-codepoints($wstr)
                let $w := fn:codepoints-to-string($c)
                return 
                if ($w ne "n" and $pos != 4) then
                    let $type := $marcxml2madsrdf:relationTypeMap/type[@pos eq xs:string($pos) and @w eq $w]/text()
                    return
                        if ($type ne "INVALID") then
                            let $auth :=
                                if ($type eq "madsrdf:hasEarlierEstablishedForm" or  $type eq "madsrdf:hasAcronymVariant") then
                                    fn:false()
                                else
                                    fn:true()
                            let $aORv :=
                                if ($auth) then
                                    "Authority"
                                else
                                    "Variant"     
                    
                            let $authorityType := marcxml2madsrdf:get-authority-type($df,$auth, $scheme)
                            let $labelProp := 
                                if ($auth) then
                                    "madsrdf:authoritativeLabel"
                                else
                                    "madsrdf:variantLabel"
                        
                            let $components := marcxml2madsrdf:create-components-from-DFxx($df, $auth, $scheme)
                            let $componentList := 
                                if ($components) then marcxml2madsrdf:create-component-list($components, $auth) 
                                else ()
                    
                            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df, $scheme)
                            let $elementList := 
                                if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
                                else ()
        
                            let $relation := 
                                    element {$type} {
                                        element {$authorityType} {
                                            $rdfabout,
                                            element rdf:type {
                                                attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                                            },
                                            element {$labelProp} {
                                              if ($scheme eq "names") then
                                                text {$label}
                                              else (
                                                attribute xml:lang {"en"},
                                                text {$label}
                                              )
                                            },
                                            $componentList,
                                            $elementList,
                                            $relatedRWOs
                                        }                    
                                    }
                            return $relation
                        else 
                            ()
                else if ($w ne "n" and $pos = 4) then
                    let $type := $marcxml2madsrdf:relationTypeMap/type[@pos eq xs:string($pos) and @w eq $w]/text()
                    return
                        if ($type ne "INVALID") then
                            let $auth :=
                                if ($type eq "madsrdf:hasAcronymVariant") then
                                    fn:false()
                                else
                                    fn:true()
                            let $aORv :=
                                if ($auth) then
                                    "Authority"
                                else
                                    "Variant"     
                    
                            let $authorityType := marcxml2madsrdf:get-authority-type($df,$auth,$scheme)
                            let $labelProp := 
                                if ($auth) then
                                    "madsrdf:authoritativeLabel"
                                else
                                    "madsrdf:variantLabel"
                        
                            let $components := marcxml2madsrdf:create-components-from-DFxx($df, $auth, $scheme)
                            let $componentList := 
                                if ($components) then marcxml2madsrdf:create-component-list($components, $auth) 
                                else ()
                    
                            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df, $scheme)
                            let $elementList := 
                                if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
                                else ()
        
                            let $relation := 
                                    element {$type} {
                                        element {$authorityType} {
                                            $rdfabout,
                                            element rdf:type {
                                                attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                                            },
                                            element {$labelProp} {
                                              if ($scheme eq "names") then
                                                text {$label}
                                              else (
                                                attribute xml:lang {"en"},
                                                text {$label} ) 
                                            },
                                            $componentList,
                                            $elementList,
                                            $relatedRWOs
                                        }                    
                                    }
                            return $relation
                        else 
                            ()
                else ()
};

(:~
:   Creates MADS RWO Class
:
:   @param  $df        	element() the relevant marcxml:datafield 
:   @param  $identifier        string of the marc001 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-rwoClass($record as element(), $identifier as xs:string) as element()* {
    let $df034 := $record/marcxml:datafield[@tag='034']
    let $df046 := $record/marcxml:datafield[@tag='046']
    let $df368 := $record/marcxml:datafield[@tag='368'] 
    let $df370 := $record/marcxml:datafield[@tag='370']    
    let $df371 := $record/marcxml:datafield[@tag='371'] 
    let $df372 := $record/marcxml:datafield[@tag='372'] 
    let $df373 := $record/marcxml:datafield[@tag='373'] 
    let $df374 := $record/marcxml:datafield[@tag='374'] 
    let $df375 := $record/marcxml:datafield[@tag='375']  
    let $df376 := $record/marcxml:datafield[@tag='376'] 
    let $df377 := $record/marcxml:datafield[@tag='377'] 
    let $df380 := $record/marcxml:datafield[@tag='380'] 
    
    let $types := (
            if ($record/marcxml:datafield[@tag='100'] and fn:string($record/marcxml:datafield[@tag='100']/@ind1)!="3" and 
                fn:not($record/marcxml:datafield[@tag='100']/marcxml:subfield[fn:matches(@code , '[efhklmnoprstvxyz]')])
                ) then
                (<rdf:type rdf:resource="http://id.loc.gov/ontologies/bibframe/Person"/>,
					<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>)
            else if ($record/marcxml:datafield[@tag='100'] and fn:string($record/marcxml:datafield[@tag='100']/@ind1)="3"                 
                ) then
                (<rdf:type rdf:resource="http://id.loc.gov/ontologies/bibframe/Family"/>,
				<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Group"/>)
					 
            else (),
            if ($record/marcxml:datafield[@tag='110']
                (:and fn:not($record/marcxml:datafield[@tag='110']/marcxml:subfield[fn:matches(@code , '[efhklmnoprstvxyz]')]):)
                ) then
                (<rdf:type rdf:resource="http://id.loc.gov/ontologies/bibframe/Organization"/>,
				<rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>)
				
            else (),
			if ($record/marcxml:datafield[@tag='111']               ) then
                ( <rdf:type rdf:resource="http://id.loc.gov/ontologies/bibframe/Meeting"/>
					(:, <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>:)
				)
				
            else (),
            if ($record/marcxml:datafield[@tag='151']) then
                <rdf:type rdf:resource="http://www.loc.gov/standards/mads/rdf/v1#Geographic"/>
            else ()
            )

    let $properties := 
        ( 	
            element rdfs:label { fn:normalize-space(fn:string($record/marcxml:datafield[@tag='100' or @tag='110' or @tag='111'  or @tag='151'])) },
         (:  for $df in $record/marcxml:datafield[@tag="034"]
             let $polygon := 
              marcxml2madsrdf:generate-polygon(
                fn:string($df/marcxml:subfield[@code="d"]), 
                fn:string($df/marcxml:subfield[@code="e"]),
                fn:string($df/marcxml:subfield[@code="f"]),
                fn:string($df/marcxml:subfield[@code="g"])
              )
             let $source:= if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
             return
               element madsrdf:associatedLocale {
                 element geosparql:Geographic {
                   element rdftype {
                    attribute rdf:resource {"http://www.opengis.net/ont/geosparql#Geometry"}
                  },
                   element geosparql:asWKT {
                     attribute rdf:datatype {"http://www.opengis.net/ont/geosparql#wktLiteral"},
                     $polygon
                   },
                  },
                element madsrdf:hasSource {
                     element madsrdf:Source{
                        element rdfs:label {$source}
                   }
                }
               },:)
            for $df in $df046
                let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
                return
                   (if ($df/marcxml:subfield[@code='f']) then
                         element madsrdf:birthDate{
                            element skos:Concept {
                                element rdfs:label{fn:concat($source, $df/marcxml:subfield[@code='f'][1]/text())},
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v)')]
                                return 
                                    element madsrdf:hasSource {
                                        element madsrdf:Source{
                                            element rdfs:label {$sf/text()}
                                    }}
                            }}
                    else (), 
                    if ($df/marcxml:subfield[@code='g']) then
                        element madsrdf:deathDate{
                            element skos:Concept {
                                element rdfs:label{fn:concat($source, $df/marcxml:subfield[@code='g']/text())},
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v)')]
                                return 
                                    element madsrdf:hasSource {
                                        element madsrdf:Source{
                                            element rdfs:label {$sf/text()}
                                    }}
                            }}
                    else (),
                    if ($df/marcxml:subfield[@code='s']) then
                        element madsrdf:activityStartDate {
                           element skos:Concept {
                                element rdfs:label{fn:concat($source, $df/marcxml:subfield[@code='s']/text())},
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v)')]
                                return 
                                    element madsrdf:hasSource {
                                        element madsrdf:Source{
                                            element rdfs:label {$sf/text()}
                                    }}
                            }}
                    else (),
                    if ($df/marcxml:subfield[@code='t']) then
                        element madsrdf:activityEndDate {
                            element skos:Concept {
                                element rdfs:label{fn:concat($source, $df/marcxml:subfield[@code='t']/text())},
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v)')]
                                return 
                                    element madsrdf:hasSource {
                                        element madsrdf:Source{
                                            element rdfs:label {$sf/text()}
                                    }}
                            }}
                    else (),
                    if ($df/marcxml:subfield[@code='q']) then
                        element madsrdf:establishDate {
                            element skos:Concept {
                                element rdfs:label{fn:concat($source, $df/marcxml:subfield[@code='q']/text())},
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v)')]
                                return 
                                    element madsrdf:hasSource {
                                        element madsrdf:Source{
                                            element rdfs:label {$sf/text()}
                                    }}
                            }}
                    else (),
                    if ($df/marcxml:subfield[@code='r']) then
                        element madsrdf:terminateDate{
                            element skos:Concept {
                                element rdfs:label{fn:concat($source, $df/marcxml:subfield[@code='r']/text())},
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v)')]
                                return 
                                    element madsrdf:hasSource {
                                        element madsrdf:Source{
                                            element rdfs:label {$sf/text()}
                                    }}
                            }}
                    else ()
                    ),
            for $df in $df368 
		   	  let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
              return
                ( for $sf in $df/marcxml:subfield[fn:matches(@code,'(a|b|c)')]
                    return element madsrdf:entityDescriptor {
                             element skos:Concept {
                                element rdfs:label {fn:concat($source,$sf/text())},  
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                return 
                                   element madsrdf:hasSource {
                                     element madsrdf:Source{
                                       element rdfs:label {$sf/text()}
                                   }}
                              }},                      
                  for $sf in $df/marcxml:subfield[@code='d']
                    return element madsrdf:honoraryTitle {
                             element skos:Concept {
                                element rdfs:label {fn:concat($source,$sf/text())},  
                                for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                return 
                                   element madsrdf:hasSource {
                                     element madsrdf:Source{
                                       element rdfs:label {$sf/text()}
                                   }}
                              }}
                ),
            for $df in $df370
            let $source:=if ($df/marcxml:subfield[@code='2'][1]) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2'][1]),") ") else ("")
                return
    				(for $sf in $df/marcxml:subfield[@code='a']
                        return element madsrdf:birthPlace { 
                            element madsrdf:Geographic {
                                    element rdfs:label {fn:concat($source,$sf/text())},
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                        element madsrdf:hasSource {
                                            element madsrdf:Source{
                                                element rdfs:label {$sf/text()}
                                        }}
                            }},
                     for $sf in $df/marcxml:subfield[@code='b']
                        return element madsrdf:deathPlace { 
                            element madsrdf:Geographic {
                                    element rdfs:label {fn:concat($source,$sf/text())},
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                        element madsrdf:hasSource {
                                            element madsrdf:Source{
                                                element rdfs:label {$sf/text()}
                                        }}
                            }},
     				for $sf in $df/marcxml:subfield[fn:matches(@code,'(c|e|f)')]
                         return element madsrdf:associatedLocale { 
                            element madsrdf:Geographic {
                                    element rdfs:label {fn:concat($source,$sf/text())},
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                        element madsrdf:hasSource {
                                            element madsrdf:Source{
                                                element rdfs:label {$sf/text()}
                                        }}
                            }}
                    ),
            for $sf in $df371
             return
                   element madsrdf:hasAffiliation {
                   element madsrdf:Affiliation {
                   element madsrdf:hasAffiliationAddress {
                       element madsrdf:Address {
                         for $sfa at $i in $sf/marcxml:subfield[@code='a']
                            return
                                 ( if ($i =1)  then
                                           element madsrdf:streetAddress {$sfa[1]/text()}
                                   else element madsrdf:extendedAddress {$sfa/text()}
                                  ),
                         if ($sf/marcxml:subfield[@code='b']) then
                              element madsrdf:city {$sf/marcxml:subfield[@code='b']/text()}
                         else (),
                         if ($sf/marcxml:subfield[@code='c']) then
                              element madsrdf:state {$sf/marcxml:subfield[@code='c']/text()}
                         else (),
                         if ($sf/marcxml:subfield[@code='d']) then
                              element madsrdf:country {$sf/marcxml:subfield[@code='d']/text()}
                         else (),    
                         if ($sf/marcxml:subfield[@code='e']) then
                              element madsrdf:postcode{$sf/marcxml:subfield[@code='e']/text()}
                         else ()
                       }},
                       for $esf in $sf/marcxml:subfield[@code='m']
                         return
                             element madsrdf:email {$esf/text()},
                       for $so in $sf/marcxml:subfield[fn:matches(@code,'(v|u)')]
                         return 
                            element madsrdf:hasSource {
                              element madsrdf:Source{
                                element rdfs:label {$so/text()}
                            }}
                }},
            for $df in $df372
			 	let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
                return 
                  (for $sf in $df/marcxml:subfield[fn:matches(@code, '(a|s|t)')]
                        return element madsrdf:fieldOfActivity {
                                   element skos:Concept {
                                    element rdfs:label {fn:concat($source, $sf/text())},
                                    for $sf in $df/marcxml:subfield[fn:matches(@code,'(v|u|0)')]
                                      return 
                                        element madsrdf:hasSource {
                                            element madsrdf:Source{
                                               element rdfs:label {$sf/text()}
                                        }}
                                  }}
                  ),
            for $df in $df373
             let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
             return
                      element madsrdf:hasAffiliation {
                           element madsrdf:Affiliation {
                            for $a in $df/marcxml:subfield[@code='a']
                                return
                                   element madsrdf:organization {
                                    element madsrdf:Organization{
                                        element rdfs:label {fn:concat($source, $a/text())}
                                   }},
                             if ($df/marcxml:subfield[@code='s']) then
                                   element madsrdf:affiliationStart {
                                    $df/marcxml:subfield[@code='s']/text()}
                             else (),
                             if ($df/marcxml:subfield[@code='t']) then
                                   element madsrdf:affiliationEnd {
                                    $df/marcxml:subfield[@code='t']/text()}
                             else (),
                             for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                return 
                                   element madsrdf:hasSource {
                                     element madsrdf:Source{
                                       element rdfs:label {$sf/text()}
                                   }}
                           }}, 
            for $df in $df374
				let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
                return 
                   ( for $sf in $df/marcxml:subfield[@code='a']
                        return element madsrdf:occupation {
                                element madsrdf:Occupation {
                                    element rdfs:label {fn:concat($source,$sf/text())},
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                        return 
                                           element madsrdf:hasSource {
                                             element madsrdf:Source{
                                               element rdfs:label {$sf/text()}
                                           }}
                                    
                                }}
                    ),	
            for $df in $df375
				let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
                return 
                   ( for $sf in $df/marcxml:subfield[@code='a']
                        return element madsrdf:gender {
                                 element skos:Concept {
                                    element rdfs:label {fn:concat($source,$sf/text())},  
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                       element madsrdf:hasSource {
                                         element madsrdf:Source{
                                           element rdfs:label {$sf/text()}
                                       }}
                              }}
                    ),	
            for $df in $df376
				let $source:=if ($df/marcxml:subfield[@code='2']) then fn:concat("(", fn:string($df/marcxml:subfield[@code='2']),") ") else ("")
                return 
                   ( for $sf in $df/marcxml:subfield[@code='a']
                        return element madsrdf:entityDescriptor {
                                 element skos:Concept {
                                    element rdfs:label {fn:concat($source,$sf/text())},  
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                       element madsrdf:hasSource {
                                         element madsrdf:Source{
                                           element rdfs:label {$sf/text()}
                                       }}
                              }},	
                    for $sf in $df/marcxml:subfield[@code='b']
                        return element madsrdf:prominentFamilyMember {
                                 element skos:Concept {
                                    element rdfs:label {fn:concat($source,$sf/text())},  
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                       element madsrdf:hasSource {
                                         element madsrdf:Source{
                                           element rdfs:label {$sf/text()}
                                       }}
                              }},	
                    for $sf in $df/marcxml:subfield[@code='c']
                        return element madsrdf:honoraryTitle {
                                 element skos:Concept {
                                    element rdfs:label {fn:concat($source,$sf/text())},  
                                    for $sf in $df/marcxml:subfield[fn:matches(@code, '(u|v|0)')]
                                    return 
                                       element madsrdf:hasSource {
                                         element madsrdf:Source{
                                           element rdfs:label {$sf/text()}
                                       }}
                              }}
                   ),
            
            for $sfa in $df377/marcxml:subfield[@code = "a"]
            let $df := $sfa/parent::node()
            let $source := xs:string($df/marcxml:subfield[@code='2'][1])
            let $source := 
                if ( $source ne "" ) then
                    if ( fn:contains($source, "iso639-1") ) then
                        "iso639-1"
                    else if ( fn:contains($source, "iso639-2") ) then
                        "iso639-2"
                    else if ( fn:contains($source, "iso639-3") ) then
                        "iso639-3"
                    else 
                        "languages"
                else 
                    "languages"
            let $sfa_str := fn:normalize-space(xs:string($sfa))
            let $codes := 
                if ( fn:matches($sfa_str, ', | ') ) then
                    for $c in fn:tokenize($sfa_str, ', | ')
                    let $c_str := fn:normalize-space($c)
                    where 
                        fn:matches($c_str, "[a-z]+") and $c_str ne "rda" and 
                        (fn:string-length($c_str) eq 2 or fn:string-length($c_str) eq 3)
                    return $c_str
                else
                    $sfa_str
            return
                for $code in $codes
                return
                    element madsrdf:associatedLanguage {
                        attribute rdf:resource { fn:concat( "http://id.loc.gov/vocabulary/", $source, "/", $code ) }
                    }
            ,
            
            for $sfl in $df377/marcxml:subfield[@code = "l"]
            where fn:not(fn:contains($sfl, "language term"))
            return 
                element madsrdf:associatedLanguage {
                    element madsrdf:Language {
                        element rdfs:label { xs:string($sfl) }
                    }
                }
       )
	   (:<!-- if ($types/rdf:type/@rdf:resource!='http://www.loc.gov/standards/mads/rdf/v1.html#Geographic') then -->
					<!-- attribute rdf:resource {"http://id.loc.gov/rwo/agents/"}, -->
					           
				<!-- else () -->:)
				
    let $rwo := 
        (if ($types) then
            element madsrdf:identifiesRWO {  
                element madsrdf:RWO {attribute rdf:about {fn:concat("http://id.loc.gov/rwo/agents/",fn:normalize-space($identifier))},
					$types,$properties				
				}
            }
        else ()
		)
    return $rwo
};




(:
-------------------------

    Creates MADS Sources:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:create-source($df as element(), $scheme) as element() {
    
    let $tag := $df/@tag
        
    let $citation_source_element := 
        (
            if ($df/marcxml:subfield[@code eq 'a']/text()) then
                <madsrdf:citationSource>{$df/marcxml:subfield[@code eq 'a']/text()}</madsrdf:citationSource>
            else (),
            
            for $u in $df/marcxml:subfield[@code eq 'u']
            let $uo := xs:string($u)
            let $u := fn:normalize-space(xs:string($u)) 
            let $u := fn:replace($u, "\\", "%5C") 
            return 
                if (shared:validate-uri($u)) then
                    <madsrdf:citationSource rdf:resource="{xs:string($u)}" />
                else (
                    <madsrdf:citationSource>{$uo}</madsrdf:citationSource>
                )
        )
    let $status_element := 
        if ($tag eq '670') then
            <madsrdf:citationStatus>found</madsrdf:citationStatus>
        else 
            <madsrdf:citationStatus>notfound</madsrdf:citationStatus>    
    let $textparts :=
        for $sf in $df/marcxml:subfield[fn:not(fn:matches(@code,'(a|u)'))]
            let $str := 
                if ($sf/@code eq 'u') then
                    fn:concat('{' , $sf/text() , '}')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
    let $text_element := 
        if (fn:normalize-space($text)) then
          if ($scheme eq "names") then
            <madsrdf:citationNote>{$text}</madsrdf:citationNote>
          else
            <madsrdf:citationNote xml:lang="en">{$text}</madsrdf:citationNote>
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
declare function marcxml2madsrdf:create-variant($df as element(), $scheme) as element() {
    
    let $tag := $df/@tag
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_counts := fn:count($df/marcxml:subfield[@code ne 'w'])
    let $df_sf_two_code := $df/marcxml:subfield[2]/@code
    let $label := marcxml2madsrdf:generate-label($df,$df_suffix)
            
    let $type := marcxml2madsrdf:get-authority-type($df, fn:false(), "" )
            
    let $components := marcxml2madsrdf:create-components-from-DFxx($df, fn:false(), $scheme)
    let $componentList := 
        if ($components) then marcxml2madsrdf:create-component-list($components, fn:false()) 
        else ()
        
    let $elements := marcxml2madsrdf:create-elements-from-DFxx($df, $scheme)
    let $elementList := 
        if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
        else ()
        
    let $nodeID := marcxml2madsrdf:generate-nodeID($label,fn:false())
            
    let $variant := 
            element {$type} {
                (: attribute rdf:nodeID {$nodeID}, :)
                element rdf:type {
                    attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Variant" ) }
                },
            (:
            This makes the MADSType the parent element; Variant is part of rdf:type
            element {"Variant"} {
                attribute rdf:nodeID {$nodeID},
                element rdf:type {
                    attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($type, "madsrdf:", "") ) }
                },
            :)
                element madsrdf:variantLabel {
                  if ($scheme eq "names") then
                    text {$label}
                  else
                   ( attribute xml:lang {"en"},
                    text {$label}) 
                },
                $componentList,
                $elementList     
            }
        
    return $variant
};


(:
-------------------------

    Determines, and returns, the appropriate MADS Authority or Variant type:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:get-authority-type($df as element(), $authority as xs:boolean, $scheme as xs:string) as xs:string {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_two_code := $df/marcxml:subfield[fn:matches(@code , "[tvxyz]")][1]/@code
	let $df_ind1 := fn:string($df/@ind1)
    let $df682 := $df/parent::node()/marcxml:datafield[@tag='682'][1] (: only one, no? :)
    let $authority_test :=
        if ($df682) then
            fn:false()
        else 
            $authority
            
    let $union := 
        if (
            $df/marcxml:subfield[@code='a'] and 
            fn:matches( fn:string-join($df/marcxml:subfield[@code!="a"]/@code, ''), '[tvxyz]')
            ) then
                fn:true()
        else if (
                fn:matches($df_suffix , '80|81|82|85') and
                $df/marcxml:subfield[1][fn:matches(@code, 'v|x|y|z')] and
                $df/marcxml:subfield[2][fn:matches(@code, 'v|x|y|z')]
            ) then
            fn:true()
        else 
            fn:false()
            
    let $t := $df/marcxml:subfield[@code="t"]
    let $not_hg := fn:matches( fn:string-join($df/marcxml:subfield/@code , ''), '[a-f|h-z]')
    let $type_element := 
        if ($union) then
            if (fn:matches($df_suffix , '00|10|11') and $t) then
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

    let $type := 
        if ($authority_test) then
            $type_element/authority/text()
        else
            $type_element/variant/text()

 	let $type:= if ($type= "madsrdf:PersonalName" and $df_ind1="3") then
	 			"madsrdf:FamilyName"
	 			else if ($type= "madsrdf:Topic" and $scheme="demographicTerms") then
					"madsrdf:Authority"
				else
	 				$type
            
    return $type

};

(:~
:   This function creates a proper nodeID value
:
:   @param  $df         marcxml datafield element
:   @param  $df_suffix  last two characters of marc/datafield tag value 
:   @return specially formatted string for use as lexical label
:)
declare function marcxml2madsrdf:generate-label($df as element(), $df_suffix as xs:string) as xs:string {
    let $label := 
        if (fn:matches($df_suffix, ("00|10|11|30"))) then
            fn:concat(
                fn:string-join(
                    $df/marcxml:subfield[
                        @code ne 'w' and 
                        @code!='v' and @code!='x' and @code!='y' and @code!='z' and 
                        @code!='6' and @code!='i' and @code!='0' and @code!='1'
                    ], 
                    ' '
                ),
                if ( $df/marcxml:subfield[@code='v' or @code='x' or @code='y' or @code='z'] ) then
                    fn:concat("--",fn:string-join($df/marcxml:subfield[@code='v' or @code='x' or @code='y' or @code='z'] , '--'))
                else ""
            )   
        else
            fn:string-join($df/marcxml:subfield[@code ne 'w'  and @code ne '6'  and @code ne '8' and @code ne '0' and @code ne '1'] , '--')
            (:      let $label := fn:string-join($df/marcxml:subfield[@code ne 'w' and @code ne '6'] , '--')
              let $label := 
                if ( fn:ends-with($label, ".") ) then
                    fn:substring($label, 1, (fn:string-length($label) - 1))
                else 
                    $label
            
            return $label  :)

    return fn:normalize-space($label)
};

(:~
:   This function creates a proper nodeID value
:
:   @param  $label       lexical authority or variant label 
:   @param  $authority   boolean, true if authority, false if variant
:   @return specially formatted string for use as an RDF/XML nodeID/bnode
:)
declare function marcxml2madsrdf:generate-nodeID($label as xs:string, 
                                      $authority as xs:boolean) 
as xs:string
{
    let $firstLetter := if ($authority) then "a" else "v"
    let $str := fn:replace( $label ,' ','-')
    let $str := fn:replace( $str ,'(,|\.|\s|\(|\)|"|&apos;|&amp;|;|:)','')
    let $str_codepoints := fn:string-to-codepoints($str)
    let $str := fn:string-join(
            for $x in $str_codepoints
            return
                if ($x gt 122) then "X" else fn:codepoints-to-string($x),
            '')
    let $nodeID := fn:concat($firstLetter,$str)
    return $nodeID
};

declare function marcxml2madsrdf:coordinates-DMStoDD($DMS as xs:string) as xs:string
{
  let $DMS := 
        if (fn:matches(fn:substring($DMS, 1, 1), '[a-zA-Z]')) then 
            fn:substring($DMS, 2) 
        else $DMS
  let $deg := fn:number(fn:substring($DMS, 1, 2))
  let $min := fn:number(fn:substring($DMS, 3, 2))
  let $sec := fn:number(fn:substring($DMS, 5))
  let $DD := $deg + ($min div 60) + ($sec div 3600)
  
  return 
    fn:string($DD)
  
};


declare function marcxml2madsrdf:generate-polygon($dwest as xs:string, $eeast as xs:string, $fnorth as xs:string, $gsouth as xs:string) as xs:string
{
  let $westbc  := marcxml2madsrdf:coordinates-DMStoDD($dwest)
  let $eastbc  := marcxml2madsrdf:coordinates-DMStoDD($eeast)
  let $northbc := marcxml2madsrdf:coordinates-DMStoDD($fnorth)
  let $southbc := marcxml2madsrdf:coordinates-DMStoDD($gsouth )
  
  let $wn := fn:string-join(($westbc, $northbc), " ")
  let $en := fn:string-join(($eastbc, $northbc), " ")
  let $es := fn:string-join(($eastbc, $southbc), " ")
  let $ws := fn:string-join(($westbc, $southbc), " ")
  
  let $points := fn:string-join(($wn, $en,$es, $ws, $wn), ", ")
  let $polygon := fn:concat("POLYGON((", $points)
  let $polygon := fn:concat($polygon, "))")
  
  return 
    $polygon
};
(: Stylus Studio meta-information - (c) 2004-2005. Progress Software Corporation. All rights reserved.
<metaInformation>
<scenarios/><MapperMetaTag><MapperInfo srcSchemaPathIsRelative="yes" srcSchemaInterpretAsXML="no" destSchemaPath="" destSchemaRoot="" destSchemaPathIsRelative="yes" destSchemaInterpretAsXML="no"/><MapperBlockPosition></MapperBlockPosition><TemplateContext></TemplateContext></MapperMetaTag>
</metaInformation>
:)