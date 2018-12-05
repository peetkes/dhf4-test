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
  $options as map:map) as map:map
{
  let $doc := fn:doc($id)
  let $source      :=
    if ($doc/*:envelope and $doc/node() instance of element()) then
      $doc/*:envelope/*:instance/node()
    else if ($doc/*:envelope) then
      $doc/*:envelope/*:instance
    else if ($doc/instance) then
        $doc/instance
      else
        $doc
  let $_ := (
    map:put($options, "validStart", xs:dateTime(($source//timestamp)[1])),
    map:put($options, "permissions", xdmp:document-get-permissions($id))
  )
  return
  plugin:extract-instance-User($source)
};
  
(:~
: Creates a map:map instance from some source document.
: @param $source-node  A document or node that contains
:   data for populating a User
: @return A map:map instance with extracted data and
:   metadata about the instance.
:)
declare function plugin:extract-instance-User(
$source as node()?
) as map:map
{

  (: the original source documents :)
  let $attachments := $source
  let $source      :=
    if ($source/*:envelope and $source/node() instance of element()) then
      $source/*:envelope/*:instance/node()
    else if ($source/*:envelope) then
      $source/*:envelope/*:instance
    else if ($source/instance) then
      $source/instance
    else
      $source
  let $id := xs:string($source/Id)
  let $name := xs:string($source/Name)

  (: return the in-memory instance :)
  (: using the XQuery 3.0 syntax... :)
  let $model := json:object()
  let $_ := (
    map:put($model, '$attachments', $attachments),
    map:put($model, '$type', 'User'),
    map:put($model, '$version', '0.0.1'),
    map:put($model, '$namespacePrefix', 'usr'),
    map:put($model, '$namespace', 'http://example.com/entity-types/user'),
    map:put($model, 'Id', $id),
    map:put($model, 'Name', $name)
  )

  (: if you prefer the xquery 3.1 version with the => operator....
  https://www.w3.org/TR/xquery-31/#id-arrow-operator
  let $model :=
  json:object()
    =>map:with('$attachments', $attachments)
    =>map:with('$type', 'User')
    =>map:with('$version', '0.0.1')
    =>map:with('Id', $id)
  =>map:with('Name', $name)
  :)
  return $model
};

declare function plugin:make-reference-object(
$type as xs:string,
$ref as xs:string)
{
  let $o := json:object()
  let $_ := (
    map:put($o, '$type', $type),
    map:put($o, '$ref', $ref)
  )
  return
  $o
};