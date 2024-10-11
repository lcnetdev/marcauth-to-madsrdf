xquery version "1.0";

module namespace constants-namespace = "info:lc/id-modules/constants-namespace#"; 

declare variable $constants-namespace:NSMAP as element() := 
    <nsmaps>
        <nsmap contexts="all" test="http://www.w3.org/2001/XMLSchema" display="XSD">xsd</nsmap>
        
        <nsmap contexts="all" test="http://www.w3.org/1999/02/22-rdf-syntax-ns" display="RDF">rdf</nsmap>
        <nsmap contexts="all" test="http://www.w3.org/2000/01/rdf-schema" display="RDFS">rdfs</nsmap>
        
        <nsmap contexts="all" test="http://purl.org/dc/terms/" display="DCTERMS">dcterms</nsmap>
        <nsmap contexts="authorities,vocabulary" test="http://www.w3.org/2002/07/owl" display="OWL">owl</nsmap>
        <nsmap contexts="authorities,resources" test="http://xmlns.com/foaf/0.1/" display="FOAF">foaf</nsmap>
        <nsmap test="http://www.openarchives.org/ore/terms/" display="ORE">ore</nsmap>  
        
        <nsmap contexts="authorities,vocabulary" test="http://id.loc.gov/ontologies/RecordInfo" display="RecordInfo">ri</nsmap>
        
        <nsmap contexts="all" test="http://www.loc.gov/mads/rdf/v1" display="MADS/RDF">madsrdf</nsmap>
        <nsmap contexts="all" test="http://www.w3.org/2004/02/skos/core" display="SKOS">skos</nsmap>
        <nsmap contexts="authorities" test="http://www.w3.org/2008/05/skos-xl" display="SKOSXL">skosxl</nsmap>
        
        <nsmap contexts="authorities,resources" test="http://id.loc.gov/ontologies/lcc" display="LCC">lcc</nsmap>
        
        <nsmap contexts="authorities,vocabulary" test="http://purl.org/vocab/changeset/schema" display="CS">cs</nsmap>
        <nsmap contexts="authorities" test="http://www.w3.org/2003/06/sw-vocab-status/ns" display="VS">vs</nsmap>
        
        <nsmap test="http://id.loc.gov/vocabulary/iso639-1/" display="ISO6391">iso6391</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/iso639-2/" display="ISO6392">iso6392</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/iso639-5/" display="ISO6395">iso6395</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/languages/" display="MARC">languages</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/countries/" display="MARC">countries</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/geographicAreas/" display="MARC">gacs</nsmap>
        
        <nsmap test="http://id.loc.gov/vocabulary/relators/" display="MARC">relators</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/classSchemes/" display="MARC">classchemes</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/subjectSchemes/" display="MARC">subjectschemes</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/genreFormSchemes/" display="MARC">genreformschemes</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/performanceMediums/" display="MARC">performancemediums</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/marcgt" display="MARC">genreterms</nsmap>

        <nsmap test="http://id.loc.gov/vocabulary/targetAudiences/" display="MARC">audiences</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/descriptionConventions/" display="MARC">descriptionconventions</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/resourceTypes/" display="MARC">resourcetypes</nsmap>
        <nsmap contexts="authorities" test="http://id.loc.gov/vocabulary/identifiers/" display="MARC">identifiers</nsmap>
        
        <nsmap test="http://www.loc.gov/premis/rdf/v1" display="PREMIS">premis</nsmap>
        <nsmap test="http://www.loc.gov/premis/rdf/v3/" display="PREMIS">premis</nsmap>
        
        <nsmap contexts="all" test="http://id.loc.gov/ontologies/bibframe/" display="BF">bf</nsmap>      
        <nsmap contexts="all" test="http://id.loc.gov/ontologies/bflc/" display="BFLC">bflc</nsmap>      
        <nsmap test="http://bibframe.org/vocab/" display="bibframe">bf1</nsmap>
        
        <nsmap contexts="resources" test="http://performedmusicontology.org/ontology/" display="PMO">pmo</nsmap>

        <nsmap test="http://id.loc.gov/resources" display="bibframe">bibframe Resources</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/" display="LCDGT">demographicterms</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/age" display="LCDGT">demographicTermsAge</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/edu" display="LCDGT">demographicTermsEdu</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/eth" display="LCDGT">demographicTermsEt</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/gdr" display="LCDGT">demographicTermsGdr</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/lng" display="LCDGT">demographicTermsLng</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/mpd" display="LCDGT">demographicTermsMpd</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/nat" display="LCDGT">demographicTermsNat</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/occ" display="LCDGT">demographicTermsOcc</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/rel" display="LCDGT">demographicTermsRe</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/sxo" display="LCDGT">demographicTermsSxo</nsmap>
        <nsmap test="http://id.loc.gov/authorities/demographicTerms/soc" display="LCDGT">demographicTermsSoc</nsmap>
        <nsmap test="http://id.loc.gov/vocabulary/ethnographicTerms/" display="AFS">ethnographicterms</nsmap>

        <nsmap test="http://id.loc.gov/vocabulary/rbms/" display="RBMS">RBMS</nsmap>
    </nsmaps>;
