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
:   This function converts a YYYYMMDD or YYYYMM or YYYY date to 
:   an EDTF date if possible.  It returns the newly formatted date if 
:   successful or an empty string otherwise.
:
:   @param  $d      as xs:string is the date to convert
:   @return xs:boolean
:)
declare function shared:convert-YYYYMMDD-to-EDTF($d as xs:string) as xs:string
{
  if (fn:matches($d, "^[0-9]{8}$")) then
    let $newD := fn:concat( fn:substring($d, 1, 4), '-', fn:substring($d, 5, 2), '-', fn:substring($d, 7, 2) )
    return
      if ( shared:valid-edtf-date($newD) ) then
        $newD
      else
        ""

  else if (fn:matches($d, "^[0-9]{6}$")) then
    let $newD := fn:concat( fn:substring($d, 1, 4), '-', fn:substring($d, 5, 2) )
    return
      if ( shared:valid-edtf-date($newD) ) then
        $newD
      else
        ""

  else if (fn:matches($d, "^[0-9]{4}$")) then
    $d
  
  else
    ""
};


(:~
:   This function takes a string and attempts to return the most appropriate
:   script code.
:
:   @return iso-script-code as string
:)
declare function shared:get-script($label) as xs:string {

    let $label-codepoints := fn:string-to-codepoints($label)
    let $script-chars := 
        for $cp in $label-codepoints
        return
            if ($cp > 55215 and $cp < 55296) then
                "Hang"
            
            else if ($cp > 44031 and $cp < 55204) then
                "Hang"
            
            else if ($cp > 43359 and $cp < 43391) then
                "Hang"
                
            else if ($cp > 19967 and $cp < 40960) then
                "Hani"

            else if ($cp > 12591 and $cp < 12688) then
                "Hang"
            
            else if ($cp > 12447 and $cp < 12544 ) then
                "Kana"

            else if ($cp > 12351 and $cp < 12448 ) then
                "Hira"

            (: Support greek extended? :)
            else if ($cp > 7935 and $cp < 8192) then
                "Grek"
            
            else if ($cp > 4351 and $cp < 4608) then
                "Hang"
            
            else if ($cp > 1535 and $cp < 1791) then
                "Arab"
            
            else if ($cp > 1423 and $cp < 1536) then
                "Hebr"
            
            else if ($cp > 1023 and $cp < 1280) then
                "Cyrl"
            
            else if ($cp > 879 and $cp < 1024) then
                "Grek"
            
            else if ($cp > 64 and $cp < 521) then
                "Latn"
        
            else if ($cp > 65) then
                "Zyyy"
        
            else
                (: Periods, spaces, other punctuation, numbers :)
                (: They don't count. :)
                ()

            
            
    let $otherscripts :=
        <scripts>
            {
                for $k in ("Arab", "Cyrl", "Grek", "Hani", "Hang", "Hebr", "Hira")
                let $c := fn:count($script-chars[. = $k])
                where $c > 1
                order by $c descending
                return <script count="{$c}">{$k}</script>
            }
        </scripts>
            
    return 
        if ( fn:count($otherscripts/script) > 0 ) then
            if ( fn:exists($otherscripts/script[. = "Kana"]) or fn:exists($otherscripts/script[. = "Hira"]) ) then
                "Jpan"
            else if (fn:exists($otherscripts/script[. = "Hang"]) and fn:exists($otherscripts/script[. = "Hani"]) ) then
                "Kore"
            else
                xs:string($otherscripts/script[1])
        else
            "Latn"
    
};

(:~
:   This function validate EDTF dates, returning true if good
:   and false if not.
:   It will check EDTF Level 0 and Level 1.  Not Level 2
:   https://www.loc.gov/standards/datetime/
:
:   @param  $d      as xs:string is the date to validate
:   @return xs:boolean
:)
declare function shared:valid-edtf-date($d as xs:string) as xs:boolean
{
  (: 1985, 1985%, -1985, etc. :)
  if (fn:matches($d, "^(-)*[0-9X]{4}([~%?])*$")) then
    fn:true()
  
  (: 1985-01, 1985-02%, -1985-04, 1985-21, etc. :)
  else if (fn:matches($d, "^(-)*[0-9]{4}-[0-9X]{2}([~%?])*$")) then
    if (fn:ends-with( fn:replace($d, "[~%?]", ""), 'X')) then
      fn:true()
    else
      let $month-or-season := fn:tokenize($d, '-')[fn:last()]
      let $month-or-season := xs:integer(fn:replace($month-or-season, "[~%?]", ""))
      return
        if ( $month-or-season > 0 and $month-or-season < 13 ) then
          fn:true()
        else if ( $month-or-season eq 21 or $month-or-season eq 22 or $month-or-season eq 23 or $month-or-season eq 24) then
          fn:true()
        else
          fn:false()
  
  (: 1985-01-02, 1985-02-03%, -1985-04-05, etc. :)
  else if (fn:matches($d, "^(-)*[0-9]{4}-[0-9X]{2}-[0-9X]{2}([~%?])*$")) then
    if (fn:ends-with( fn:replace($d, "[~%?]", ""), 'X')) then
      fn:true()
    else
      let $date := fn:replace($d, "^-", "")
      let $date := fn:replace($date, "[~%?]", "")
      return $date castable as xs:date
  
  (: Y170000002 or Y-170000002 :)
  else if (fn:matches($d, "^Y(-)*[0-9]{5,}([~%?])*$")) then 
    fn:true()

  else if ($d castable as xs:date) then
    (: If true, we need do nothing more. :)
    fn:true()

  else if ( fn:matches($d, "[a-zA-WZ!@#$\^\*\(\)_\[\]\{\}:;<>,]") ) then
    (: Any characters other than Y, X, ~, ?, -, /, ., and % not allowed. :)
    fn:false()
  
  else if ( fn:contains($d, '/') ) then
    let $dates := fn:tokenize($d, '/')
    let $validD1 := 
      if ($dates[1] eq "" or $dates[1] eq "..") then
        fn:true()
      else
        shared:valid-edtf-date($dates[1])
    let $validD2 := 
      if ($dates[2] eq "" or $dates[2] eq "..") then
        fn:true()
      else
        shared:valid-edtf-date($dates[2])
    return $validD1 and $validD2
    
  else
    fn:false()
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
