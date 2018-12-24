xquery version "1.0-ml";

(:~
: User: I25039
: Date: 22-6-2018
: Time: 10:08
:)

import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $params as map:map external;

try{
    sec:role-add-roles(map:get($params,"role-name"), map:get($params,"role-names"))
} catch( $ex) {
    xdmp:trace("tfs-role",$ex)
}
