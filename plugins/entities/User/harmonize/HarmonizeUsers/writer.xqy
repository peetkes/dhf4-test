xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

declare option xdmp:mapping "false";
declare variable $COLL_TEMPORAL := "tmp-collection";

(:~
 : Writer Plugin
 :
 : @param $id       - the identifier returned by the collector
 : @param $envelope - the final envelope
 : @param $options  - a map containing options. Options are sent from Java
 :
 : @return - nothing
 :)
declare function plugin:write(
  $id as xs:string,
  $envelope as item(),
  $options as map:map) as empty-sequence()
{
  temporal:document-insert(
          $COLL_TEMPORAL,
          $id,
          $envelope,
          if (map:contains($options,"permissions")) then map:get($options,"permissions") else xdmp:default-permissions(),
          (map:get($options, "entity"),"Mine"))
};
