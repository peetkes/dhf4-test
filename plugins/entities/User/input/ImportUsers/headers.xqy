xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

declare namespace envelope = "http://marklogic.com/data-hub/envelope";
declare namespace tmp = "http://example.com/tmp";

declare option xdmp:mapping "false";
declare variable $INFINITY := xs:dateTime("9999-12-31T11:59:59Z");

(:~
 : Create Headers Plugin
 :
 : @param $id      - the identifier returned by the collector
 : @param $content - the output of your content plugin
 : @param $options - a map containing options. Options are sent from Java
 :
 : @return - zero or more header nodes
 :)
declare function plugin:create-headers(
  $id as xs:string,
  $content as item()?,
  $options as map:map) as node()*
{
  xdmp:trace("test", xdmp:quote($content)),
  element tmp:validStart { xs:dateTime(($content//timestamp)[1]) },
  element tmp:validEnd { $INFINITY },
  element tmp:systemStart {},
  element tmp:systemEnd {}
};
