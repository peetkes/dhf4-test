xquery version "1.0-ml";

(:~
: User: I25039
: Date: 1-5-2018
: Time: 14:56
:)

module namespace tfs-flow = "http://example.com/ext/data-hub-framework/impl/flow-lib";

import module namespace es = "http://marklogic.com/entity-services"
    at "/MarkLogic/entity-services/entity-services.xqy";
import module namespace consts = "http://marklogic.com/data-hub/consts"
    at "/data-hub/4/impl/consts.xqy";
import module namespace flow = "http://marklogic.com/data-hub/flow-lib"
    at "/data-hub/4/impl/flow-lib.xqy";
import module namespace json="http://marklogic.com/xdmp/json"
at "/MarkLogic/json/json.xqy";


declare option xdmp:mapping "false";

(:
 : Wraps a canonical instance (returned by instance-to-canonical())
 : within an envelope patterned document, along with the source
 : document, which is stored in an attachments section.
 : @param $entity-instance an instance, as returned by an extract-instance
 : function
 : @param $entity-format Either "json" or "xml", selects the output format
 : for the envelope
 : @return A document which wraps both the canonical instance and source docs.
 :)
declare function tfs-flow:make-envelope(
    $content as map:map,
    $headers as item()*,
    $triples as item()*,
    $data-format as xs:string
) as document-node()
{
    let $content := flow:clean-data($content, "content", $data-format)
    let $headers := flow:clean-data($headers, "headers", $data-format)
    let $triples := flow:clean-data($triples, "triples", $data-format)
    return
        if ($data-format = $consts:XML)
        then
            document {
                element es:envelope {
                    element es:headers { $headers },
                    element es:triples { $triples },
                    element es:instance {
                        if ($content instance of map:map and map:keys($content) = "$type") then (
                            element es:info {
                                element es:title {map:get($content, '$type')},
                                element es:version {'0.0.1'}
                            },
                            tfs-flow:instance-to-canonical-xml($content)
                        )
                        else $content
                    },
                    element es:attachments {
                        if ($content instance of map:map and map:keys($content) = "$attachments") then
                            if (map:get($content, "$attachments") instance of element() or
                                    map:get($content, "$attachments")/node() instance of element())
                            then map:get($content, "$attachments")
                            else
                                let $c := json:config("basic")
                                let $_ := map:put($c,"whitespace" , "ignore" )
                                return
                                    json:transform-from-json(map:get($content, "$attachments"),$c)
                        else
                            ()
                    }
                }
            }
        else if ($data-format = $consts:JSON)
        then
            let $envelope :=
                let $o := json:object()
                let $_ := (
                    map:put($o, "headers", $headers),
                    map:put($o, "triples", $triples),
                    map:put($o, "instance",
                            if ($content instance of map:map and map:keys($content) = "$type") then
                                let $json := flow:instance-to-canonical-json($content)
                                let $info :=
                                    let $o :=json:object()
                                    let $_ := (
                                        map:put($o, "title", map:get($content, "$type")),
                                        map:put($o, "version",  map:get($content, "$version"))
                                    )
                                    return $o
                                let $_ := map:put($json, "info", $info)
                                return $json
                            else
                                $content
                    ),
                    map:put($o, "attachments",
                            if ($content instance of map:map and map:keys($content) = "$attachments") then
                                if(map:get($content, "$attachments")/node() instance of element()) then
                                    let $c := json:config("custom")
                                    let $_ := map:put($c,"whitespace" , "ignore" )
                                    let $_ := map:put($c, "element-namespace", "http://marklogic.com/entity-services")
                                    return json:transform-to-json(flow:clean-xml-for-json(map:get($content, "$attachments")/node()),$c)
                                else
                                    map:get($content, "$attachments")
                            else
                                ()
                    )
                )
                return
                    $o
            let $wrapper := json:object()
            let $_ := map:put($wrapper, "envelope", $envelope)
            return
                xdmp:to-json($wrapper)
        else
            fn:error((), "RESTAPI-INVALIDCONTENT", "Invalid data format: " || $data-format)
};

(:~
 : Turns an entity instance into an XML structure.
 : This out-of-the box implementation traverses a map structure
 : and turns it deterministically into an XML tree.
 : Using this function as-is should be sufficient for most use
 : cases, and will play well with other generated artifacts.
 : @param $entity-instance A map:map instance returned from one of the extract-instance
 :    functions.
 : @return An XML element that encodes the instance.
 :)
declare function tfs-flow:instance-to-canonical-xml(
    $entity-instance as map:map
) as element()
{
(: Construct an element that is named the same as the Entity Type :)
    let $namespace := map:get($entity-instance, "$namespace")
    let $namespace-prefix := map:get($entity-instance, "$namespacePrefix")
    let $nsdecl :=
        if ($namespace) then
            namespace {$namespace-prefix} {$namespace}
        else ()
    let $type-name := map:get($entity-instance, '$type')
    let $type-qname :=
        if ($namespace)
        then fn:QName($namespace, $namespace-prefix || ":" || $type-name)
        else $type-name
    return
        element {$type-qname} {
            $nsdecl,
            if ( map:contains($entity-instance, '$ref'))
            then map:get($entity-instance, '$ref')
            else
                for $key in map:keys($entity-instance)
                let $instance-property := map:get($entity-instance, $key)
                let $ns-key :=
                    if ($namespace and $key castable as xs:NCName)
                    then fn:QName($namespace, $namespace-prefix || ":" || $key)
                    else $key
                where ($key castable as xs:NCName)
                return
                    typeswitch ($instance-property)
                    (: This branch handles embedded objects.  You can choose to prune
                       an entity's representation of extend it with lookups here. :)
                        case json:object+
                            return
                                for $prop in $instance-property
                                return element {$ns-key} {
                                    tfs-flow:instance-to-canonical-xml($prop)
                                }
                    (: An array can also treated as multiple elements :)
                        case json:array
                            return
                                element {$ns-key} {
                                    attribute datatype {'array'},
                                    for $val in json:array-values($instance-property)
                                    return
                                        if ($val instance of json:object)
                                        then tfs-flow:instance-to-canonical-xml($val)
                                        else $val
                                }
                    (: A sequence of values should be simply treated as multiple elements :)
                        case item()+
                            return
                                for $val in $instance-property
                                return element {$ns-key} {$val}
                        default return element {$ns-key} {$instance-property}
        }
};
