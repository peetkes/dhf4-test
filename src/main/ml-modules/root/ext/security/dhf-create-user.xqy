xquery version "1.0-ml";

(:~
: User: I25039
: Date: 22-6-2018
: Time: 10:00
:)
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $params as map:map external;

xdmp:lock-for-update(map:get($params,"user-name")),

try {
    if (sec:user-exists(map:get($params,"user-name")))
    then sec:user-set-roles(map:get($params,"user-name"),(map:get($params,"user-role")))
    else sec:create-user(
        map:get($params,"user-name"),
        map:get($params,"description"),
        map:get($params,"user-password"),
        map:get($params,"user-role"),
        map:get($params,"permissions"),
        map:get($params,"collections"))
} catch( $ex) {
    xdmp:trace("tfs-user",$ex)
}