xquery version "1.0";

module namespace constants-mads2skosmap = "info:lc/id-modules/constants-mads2skosmap#"; 



   
(:~
:   This variable records the MADS 2 SKOS mapping.
:)
    declare variable $constants-mads2skosmap:MADS2SKOSMAP :=
        <relations>
            <relation prop="madsrdf:hasVariant" skos="skosxl:altLabel">Variants</relation>
            <relation prop="madsrdf:hasBroaderAuthority" skos="skos:broader">Broader Terms</relation>
            <relation prop="madsrdf:hasNarrowerAuthority" skos="skos:narrower">Narrower Terms</relation>
            <relation prop="madsrdf:hasLaterEstablishedForm" skos="rdfs:seeAlso">Later Established Forms</relation>
            <relation prop="madsrdf:useInstead" skos="rdfs:seeAlso">Use Instead</relation>
            <relation prop="madsrdf:hasDemonym" skos="rdfs:related">Has Demonym</relation>
            <relation prop="madsrdf:isDemonymFor" skos="rdfs:related">Demonym For</relation>
            <relation prop="madsrdf:hasReciprocalAuthority" skos="skos:related">Related Terms</relation>
            <relation prop="madsrdf:hasRelatedAuthority" skos="skos:semanticRelation">Additional Related Forms</relation>
            <relation prop="madsrdf:see" skos="rdfs:seeAlso">See Also</relation>
            <relation prop="madsrdf:hasExactExternalAuthority" skos="skos:exactMatch">Exact Matching Concepts from Other Schemes</relation>
            <relation prop="madsrdf:hasCloseExternalAuthority" skos="skos:closeMatch">Closely Matching Concepts from Other Schemes</relation>
            <relation prop="madsrdf:hasReciprocalExternalAuthority" skos="skos:relatedMatch">Closely Matching Concepts from Other Schemes</relation>
            <relation prop="madsrdf:hasBroaderExternalAuthority" skos="skos:broadMatch">Broader Concepts from Other Schemes</relation>
            <relation prop="madsrdf:hasNarrowerExternalAuthority" skos="skos:narrowMatch">Narrower Concepts from Other Schemes</relation>            
            <relation prop="madsrdf:note" skos="skos:note">General Notes</relation>
            <relation prop="madsrdf:scopeNote" skos="skos:scopeNote">Scope Notes</relation>
            <relation prop="madsrdf:definitionNote" skos="skos:definition">Definition Notes</relation>
            <relation prop="madsrdf:changeNote" skos="skos:changeNote">Change Notes</relation>
            <relation prop="madsrdf:deletionNote" skos="skos:changeNote">Deletion Notes</relation>
            <relation prop="madsrdf:editorialNote" skos="skos:editorial">Editorial Notes</relation>
            <relation prop="madsrdf:exampleNote" skos="skos:example">Example Notes</relation>
            <relation prop="madsrdf:historyNote" skos="skos:historyNote">History Notes</relation>
            <relation prop="madsrdf:MADSCollection" skos="skos:Collection">Collection memberships</relation>
            <relation prop="madsrdf:MADSSCheme" skos="skos:ConceptScheme">Scheme memberships</relation>
            <!-- <relation prop="madsrdf:classification" skos="skos:semanticRelation">Classification</relation> -->
            <relation prop="madsrdf:code" skos="skos:notation">Codes</relation>
            <relation prop="madsrdf:hasMADSCollectionMember" skos="skos:member">Collection Members</relation>
            <relation prop="madsrdf:hasTopMemberOfMADSScheme" skos="skos:hasTopConcept">Top Scheme Members</relation>
            <relation prop="madsrdf:isTopMemberOfMADSScheme" skos="skos:topConceptOf">Top Scheme Member Of</relation>
            <relation prop="madsrdf:isMemberOfMADSScheme" skos="skos:inScheme">Top Scheme Members</relation>
            <relation prop="madsrdf:hasMADSSchemeMember">Scheme Members</relation>
            <relation prop="rdfs:subClassOf">Subclass Of</relation>
            <relation prop="rdfs:subPropertyOf">SubProperty Of</relation>
            
            <relation prop="owl:imports">Imports</relation>
            
            <relation prop="lcc:synthesizedFromSchedule">Synthesized From Schedule</relation>
            <relation prop="lcc:synthesizedFromTable">Synthesized From Table</relation>
            <relation prop="lcc:useGuideTable">Use With Guide Table(s)</relation>
            <relation prop="lcc:isGuideTableFor">Is Guide Table For</relation>
            <relation prop="lcc:useTable">Use With Table(s)</relation>
            <relation prop="lcc:isTableFor">Is Table For</relation>
            <relation prop="lcc:useWithSchedule">Use With Schedule(s)</relation>
            
            <relation prop="bf:creator">Creator(s)</relation>
            <relation prop="relators:cre">Creator(s)</relation>
            <relation prop="relators:aut">Author(s)</relation>
            
            <relation prop="bf:contributor">Contributor(s)</relation>
            <relation prop="relators:lyr">Lyricist(s)</relation>
            <relation prop="relators:prf">Performer(s)</relation>
            <relation prop="relators:ive">Interviewee(s)</relation>
            <relation prop="relators:ivr">Interviewer(s)</relation>
            
            <relation prop="bf:name">Name(s)</relation>
            <relation prop="bf:provider">Provider(s)</relation>
            <relation prop="bf:place">Place(s)</relation>
            <relation prop="bf:providerPlace">Place(s) of Publication</relation>
            <relation prop="bf:subject">Subject(s)</relation>
            <relation prop="bf:classification">Classification</relation>
           <!-- <relation prop="bf:classificationLcc">LC Classification</relation> -->
           <!-- <relation prop="bf:classificationNlm">NLM Classification</relation> -->
            <relation prop="bf:instance">Instance(s)</relation>
            <relation prop="bf:hasInstance">Instance(s)</relation>
            <relation prop="bf:instanceOf">Instance of Work</relation>
            <relation prop="bf:hasAnnotation">Annotation(s)</relation>
        <!--    <relation prop="bf:annotation">Annotation(s)</relation> -->
            <relation prop="bf:annotates">Annotates Work</relation>
            <relation prop="bf:hasIllustration">Cover Art</relation>
            <relation prop="bf:hasHoldings">Holdings</relation>
            <relation prop="bf:link">Link(s)</relation>
            <relation prop="bf:annotation-service">Annotation Service</relation>
            <relation prop="bf:derivedFrom">Derives from MARC21 Record</relation>
            <relation prop="bf:consolidates">Consolidates MARC21 Record(s)</relation>
            <relation prop="bf2:consolidates">Consolidates MARC21 Record(s)</relation>
            <relation prop="bf:isTranslationOf">Is Translation Of</relation>
            <relation prop="bf:translationOf">Is Translation Of</relation>
            <relation prop="bf:isVersionOf">Is Version Of</relation>
            <relation prop="bf:relatedWork">Related Work(s)</relation>
            <relation prop="bf:includes">Includes Work(s)</relation>
            <relation prop="bf:intendedAudience">Intended Audience</relation>
        <!--    <relation prop="bf:language">Language</relation> -->
            <relation prop="bf:descriptionConventions">Description Conventions</relation>
            <relation prop="bf:descriptionLanguage">DescriptionLanguage</relation>
            <relation prop="bf:descriptionSource">Description Source</relation>
            <relation prop="bf:workTitle">Work Title</relation>
            <relation prop="bf:continues">Continues</relation>
            <relation prop="bf:continuedBy">Continued by</relation>                        
        </relations>;         