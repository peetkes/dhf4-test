xquery version "1.0-ml";

(:~
: User: I25039
: Date: 22-6-2018
: Time: 10:02
:)

import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $params as map:map external;

xdmp:lock-for-update(map:get($params,"role-name")),
try {
    if (sec:role-exists(map:get($params,"role-name")))
    then ()
    else sec:create-role(map:get($params,"role-name"),
        map:get($params,"role-description"),
        map:get($params,"role-names"),
        (),
        ()
    )
} catch( $ex) {
    xdmp:trace("tfs-role",$ex)
}
