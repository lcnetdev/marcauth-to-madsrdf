xquery version "1.0";

(:
:   Module Name: Application Constants
:
:   Module Version: 1.0
:
:   Date: 2011 Jan 04
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: xdmp (MarkLogic)
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Application constants.
:       No functions, just variables.
:
:)


(:~
:   Application constants.
:   No functions, just vars.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since January 04, 2011
:   @version 1.0
:)

module namespace constants = 'info:lc/id-modules/constants#'; 

import module namespace constants-namespace = "info:lc/id-modules/constants-namespace#" at "constants/constants-namespace.xqy";
import module namespace constants-mads2skosmap = "info:lc/id-modules/constants-mads2skosmap#" at "constants/constants-mads2skosmap.xqy";

(: Namespace mapping :)
declare variable $constants:NSMAP := $constants-namespace:NSMAP;

(:~
:   This variable records the MADS 2 SKOS mapping.
:)
declare variable $constants:MADS2SKOSMAP := $constants-mads2skosmap:MADS2SKOSMAP;
