xquery version "1.0";

(:
:   Module Name: Shared Functions
:
:   Module Version: 1.0
:
:   Date: 2011 Jan 04
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Shared Functions
:
:)
   
(:~
:   Shared Functions
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since April 18, 2011
:   @version 1.0
:)

module namespace shared = 'info:lc/id-modules/shared#';

(:~
:   This function normalizes an authoritativeLabel to either be 
:   inserted into a BF resource or used by a MADS resource to find a related
:   BF resource. 
:
:   @param  $label      as xs:string is the label/string to be normalized
:   @return xs:string  label normalized
:)
declare function shared:normalize-label($label as xs:string) as xs:string {
    let $label-normalized := fn:replace(fn:normalize-space(fn:lower-case($label)), " ", "")
    let $label-normalized := fn:replace($label-normalized, "[ ,\-\.]+", "")
    return $label-normalized
};

(:~
:   This function validate URIs 
:   Regex was adapted from: https://stackoverflow.com/a/30910/10580173
:
:   @param  $uri      as xs:string is the URI
:   @return xs:boolean
:)
declare function shared:validate-uri($uri as xs:string)
    as xs:boolean
{
    let $basicmatch := "a-z0-9\-._~!$&amp;'\(\)\*+,;="
    let $hexmatch := "%[0-9A-F]{2}"
    let $regex := fn:concat(
            "^([a-z0-9+\.-]+):",
            "(//((([", $basicmatch, ":]|", $hexmatch, ")*)@)?(([", $basicmatch, "]|", $hexmatch, ")*)(:(\d*))?(/([", $basicmatch, ":@/]|", $hexmatch, ")*)?|(/?([", $basicmatch, ":@]|", $hexmatch, ")+([", $basicmatch, ":@/]|", $hexmatch, ")*)?)",
            "(\?(([", $basicmatch, ":/?@]|", $hexmatch, ")*))?",
            "(#(([", $basicmatch, ":/?@]|", $hexmatch, ")*))?$"    
    )
    return fn:matches($uri, $regex, "i")
};
