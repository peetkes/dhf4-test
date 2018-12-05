xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

import module namespace es = "http://marklogic.com/entity-services"
at "/MarkLogic/entity-services/entity-services.xqy";

declare option xdmp:mapping "false";

(:~
: Create Content Plugin
:
: @param $id          - the identifier returned by the collector
: @param $options     - a map containing options. Options are sent from Java
:
: @return - your transformed content
:)
declare function plugin:create-content(
  $id as xs:string,
  $raw-content as node()?,
  $options as map:map) as item()?
{
  $raw-content
};
