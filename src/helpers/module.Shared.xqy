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
