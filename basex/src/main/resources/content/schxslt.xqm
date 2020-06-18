xquery version "3.1";

(:~
 : BaseX module for Schematron validation with SchXslt.
 :
 : @author David Maus
 : @see    https://doi.org/10.5281/zenodo.1495494
 : @see    https://basex.org
 :
 :)

module namespace schxslt = "https://doi.org/10.5281/zenodo.1495494";

declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";

(:~
 : Validate document against Schematron and return the validation report.
 :
 : @param  $document   Document to be validated
 : @param  $schematron Schematron schema
 : @param  $phase      Validation phase
 : @param  $parameters Validation parameters
 : @return Validation report
 :)
declare function schxslt:validate ($document as node(), $schematron as node(), $phase as xs:string?, $parameters as map(*)) as document-node(element(svrl:schematron-output)) {
  let $compileOptions := if ($phase) then map{"phase": $phase} else map{}
  let $validateOptions := if (map:contains($parameters, "validate")) then $parameters("validate") else map{}
  let $schematron := if ($schematron instance of document-node()) then $schematron/sch:schema else $schematron
  let $xsltver := schxslt:processor-path(lower-case($schematron/@queryBinding))
  return
    if ($xsltver = ("2.0", "3.0") and xslt:version() ne "3.0")
      then error(xs:QName("schxslt:UnsupportedQueryBinding"))
      else $document => xslt:transform(schxslt:compile($schematron, $compileOptions, $xsltver), $validateOptions)
};

(:~
 : Validate document against Schematron and return the validation report.
 :
 : @param  $document   Document to be validated
 : @param  $schematron Schematron schema
 : @param  $phase      Validation phase
 : @return Validation report
 :)
declare function schxslt:validate ($document as node(), $schematron as node(), $phase as xs:string?) as document-node(element(svrl:schematron-output)) {
  schxslt:validate($document, $schematron, $phase, map{})
};

(:~
 : Validate document against Schematron and return the validation report.
 :
 : @param  $document Document to be validated
 : @param  $schematron Schematron document
 : @return Validation report
 :)
declare function schxslt:validate ($document as node(), $schematron as node()) as document-node(element(svrl:schematron-output)) {
  schxslt:validate($document, $schematron, ())
};

(:~
 : Return URI of compiler stylesheet.
 :
 : @error  Query language not supported
 :
 : @param  $queryBinding Query language token
 : @return URI of compiler stylesheet.
 :)
declare function schxslt:resolve-compiler-uri ($queryBinding as xs:string) as xs:string {
  let $xsltver := schxslt:processor-path($queryBinding)
  return
    file:base-dir() || "/xslt/" || $xsltver || "/compile/compile-" || $xsltver || ".xsl"
};

(:~
 : Perform inclusions.
 :
 : @param  $schema Schematron
 : @return Schematron
 :)
declare function schxslt:include ($schema as element(sch:schema)) as element(sch:schema) {
  let $queryBinding := $schema/@queryBinding
  let $xsltver := schxslt:processor-path($queryBinding)
  let $include := file:base-dir() || "/xslt/" || $xsltver || "/include.xsl"
  return
    $schema => xslt:transform($include, map{})
};

(:~
 : Expand abstract rules and patterns.
 :
 : @param  $schema Schematron
 : @return Schematron
 :)
declare function schxslt:expand ($schema as element(sch:schema)) as element(sch:schema) {
  let $queryBinding := $schema/@queryBinding
  let $xsltver := schxslt:processor-path($queryBinding)
  let $expand := file:base-dir() || "/xslt/" || $xsltver || "/expand.xsl"
  return
    $schema => xslt:transform($expand, map{})
};

(:~
 : Return path segment to processor for requested query language.
 :
 : @error  Query language not supported
 :
 : @param  $queryBinding Query language token
 : @return Path segment to processor
 :)
declare %private function schxslt:processor-path ($queryBinding as xs:string) as xs:string {
  switch ($queryBinding)
    case ""
      return "1.0"
    case "xslt"
      return "1.0"
    case "xslt2"
      return "2.0"
    case "xslt3"
      return "2.0"
    default
      return error(xs:QName("schxslt:UnsupportedQueryBinding"))
};

(:~
 : Compile Schematron to validation stylesheet.
 :
 : @param  $schematron Schematron document
 : @param  $options Schematron compiler parameters
 : @return Validation stylesheet
 :)
declare %private function schxslt:compile ($schematron as node(), $options as map(*), $xsltver as xs:string) as document-node(element(xsl:transform)) {
  let $basedir := file:base-dir() || "/xslt/" || $xsltver || "/"
  let $include := $basedir || "include.xsl"
  let $expand  := $basedir || "expand.xsl"
  let $compile := $basedir || "compile-for-svrl.xsl"
  return
    $schematron => xslt:transform($include) => xslt:transform($expand) => xslt:transform($compile, $options)
};
