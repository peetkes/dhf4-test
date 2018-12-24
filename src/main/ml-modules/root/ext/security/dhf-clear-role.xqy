xquery version "1.0-ml";

(:~
: User: I25039
: Date: 22-6-2018
: Time: 10:14
:)

import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $user-role as xs:string external;

xdmp:lock-for-update($user-role),
try {
    if (sec:role-exists($user-role))
    then sec:role-set-roles($user-role,())
    else ()
} catch( $ex) {
    xdmp:trace("tfs-role",$ex)
}

