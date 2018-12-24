xquery version "1.0-ml";

(:~
: User: I33291
: Date: 3-5-2018
: Time: 11:51
:)

module namespace user-management = "http://marklogic.com/dhf41/ext/security/dhf-user-management";

import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare option xdmp:mapping "false";

(:~
 : Wraps $user and $envelope from writer.xqy plugin
 : and creates roles named after the users if they do not exist.
 : Performs the execution onto Security database and
 : calls user-management:create-subroles() with passing $envelope and $user
 : arguments for further processing.
 :
 : @param   $fn-user, function to return a map with user specific items like user-name, role, list of subroles etc
 : @param   $fn-level1, function to return a map with level1 role properties
 : @param   $fn-level2, function to return a map with level2 role properties
 : @param   $user,  name of the user to create roles for
 : @param   $envelope, as returned by plugin:write() function in writer.xqy
 : @return  empty-sequence()

 :)
declare function user-management:create-role(
    $fn-user as xdmp:function,
    $user-prefix as xs:string,
    $fn-level1 as xdmp:function,
    $level1-prefix as xs:string,
    $fn-level2 as xdmp:function?,
    $level2-prefix as xs:string?,
    $user as item(),
    $envelope as item()
) as empty-sequence()
{
    let $user-map := xdmp:apply($fn-user, $user, $user-prefix)
    let $role := map:get($user-map, "role-name")
    let $role-desc := map:get($user-map, "role-description")
    let $role-list := map:get($user-map, "role-list")
    let $_ := (
        xdmp:trace("security", "calling /ext/security/dhf-create-role.xqy for user " || $role),
        xdmp:trace("security", $user-map),
        xdmp:invoke("/ext/security/dhf-create-role.xqy",
            (xs:QName("params"),map:new((
                map:entry("role-name", $role),
                map:entry("role-description", $role-desc),
                map:entry("role-names", $role-list)
            ))),
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
                <update>true</update>
                <isolation>different-transaction</isolation>
            </options>)
        )
    return (
        xdmp:invoke-function(
            function() {
                user-management:create-subroles($fn-user, $user-prefix, $fn-level1, $level1-prefix, $fn-level2, $level2-prefix, $envelope, $user)
            },
            <options xmlns="xdmp:eval">
                <update>true</update>
                <isolation>different-transaction</isolation>
            </options>
        )
    )
};

(:~
 : Takes the arguments passed by the user-management:create-role()
 : function and results in sub-roles creation that are further connected
 : with the main roles. It accounts for sub-roles clearance if they don't exist.
 : Performs the execution onto Security database and
 : calls user-management:create-user() with passing $user
 : argument for further processing
 :
 : @param   $fn-user, function to return a map with user specific items like user-name, role, list of subroles etc
 : @param   $fn-level1, function to return a map with level1 role properties
 : @param   $fn-level2, function to return a map with level2 role properties
 : @param   $user,  name of the user to create roles for
 : @param   $envelope, as returned by plugin:write() function in writer.xqy
 : @return  empty-sequence()
 :)
declare private function user-management:create-subroles(
    $fn-user as xdmp:function,
    $user-prefix as xs:string,
    $fn-level1 as xdmp:function,
    $level1-prefix as xs:string,
    $fn-level2 as xdmp:function?,
    $level2-prefix as xs:string?,
    $envelope as item(),
    $user as item()
) as empty-sequence()
{
    let $user-map := xdmp:apply($fn-user, $user, $user-prefix)
    let $user-role := map:get($user-map, "role-name")
    return (
        xdmp:trace("security", "calling /ext/security/dhf-clear-role.xqy for user-role " || $user-role),
        xdmp:invoke("/ext/security/dhf-clear-role.xqy",
            (xs:QName("user-role"),$user-role),
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
                <update>true</update>
                <isolation>different-transaction</isolation>
            </options>)
        ,
        let $level1-map := xdmp:apply($fn-level1, $envelope, $level1-prefix)
        let $level1-list := map:get($level1-map, "role-list")
        let $level1-desc := map:get($level1-map, "description")
        for $level1-role in map:get($level1-map, "role-name")
        let $_ := (
            xdmp:trace("security", "calling /ext/security/dhf-create-role.xqy for level1 role " || $level1-role),
            xdmp:trace("security", $level1-map),
            xdmp:invoke("/ext/security/dhf-create-role.xqy",
                (xs:QName("params"),map:new((
                    map:entry("role-name", $level1-role),
                    map:entry("role-description", $level1-desc),
                    map:entry("role-names", $level1-list)
                ))),
                <options xmlns="xdmp:eval">
                    <database>{xdmp:database("Security")}</database>
                    <update>true</update>
                    <isolation>different-transaction</isolation>
                </options>
            )
        )
        return (
            xdmp:trace("security", "calling /ext/security/dhf-add-roles.xqy for user " || $user-role || " with level1 role " || $level1-role),
            xdmp:invoke("/ext/security/dhf-add-roles.xqy",
                (xs:QName("params"), map:new((
                    map:entry("role-name", $user-role),
                    map:entry("role-names", $level1-role)
                ))),
                <options xmlns="xdmp:eval">
                    <database>{xdmp:database("Security")}</database>
                    <update>true</update>
                    <isolation>different-transaction</isolation>
                </options>),
            xdmp:invoke-function(
                function() {
                    user-management:create-user($fn-user, $user, $user-prefix)
                },
                <options xmlns="xdmp:eval">
                    <update>true</update>
                    <isolation>different-transaction</isolation>
                </options>
            )
        ),
        if (fn:empty($fn-level2) and fn:empty($level2-prefix))
        then ()
        else (
            let $level2-map := xdmp:apply($fn-level2, $envelope, $level2-prefix)
            let $level2-desc := map:get($level2-map, "description")
            let $level2-list := map:get($level2-map, "role-list")
            let $level2-prefix := map:get($level2-map, "prefix")
            for $level2-role in map:get($level2-map, "role-name")
            let $_ := (
                xdmp:trace("security", $level2-role),
                if (fn:not($level2-role = $level2-prefix)) then (
                    xdmp:trace("security", "calling /ext/security/dhf-create-role.xqy for user " || $user-role || " with level2 role " || $level2-role),
                    xdmp:trace("security", $level2-map),
                    xdmp:invoke("/ext/security/dhf-create-role.xqy",
                        (xs:QName("params"),map:new((
                            map:entry("role-name", $level2-role),
                            map:entry("role-description", $level2-desc),
                            map:entry("role-names", $level2-list)
                        ))),
                        <options xmlns="xdmp:eval">
                            <database>{xdmp:database("Security")}</database>
                            <update>true</update>
                            <isolation>different-transaction</isolation>
                        </options>)
                ) else ()
            )
            return (
                xdmp:trace("security", "calling /ext/security/dhf-add-roles.xqy for user " || $user-role || " with level2 role " || $level2-role),
                xdmp:invoke("/ext/security/dhf-add-roles.xqy",
                    (xs:QName("params"), map:new((
                        map:entry("role-name", $user-role),
                        map:entry("role-names", $level2-role)
                    ))),
                    <options xmlns="xdmp:eval">
                        <database>{xdmp:database("Security")}</database>
                        <update>true</update>
                        <isolation>different-transaction</isolation>
                    </options>),
                xdmp:invoke-function(
                    function() {
                        user-management:create-user($fn-user, $user, $user-prefix)
                    },
                    <options xmlns="xdmp:eval">
                        <update>true</update>
                        <isolation>different-transaction</isolation>
                    </options>
                )
            )
        )
    )
};

(:~
 : Takes the argument passed by the user-management:create-subroles()
 : function and creates users. Furthermore, the function assigns a role
 : to each user that is connected to appropriate sub-roles.
 : Performs the execution onto Security database
 : resulting in the users creation.
 :
 : @param   $fn-user, function to return a map with user specific items like user-name, role, list of subroles etc
 : @param   $user,  name of the user to create roles for
 : @return  empty-sequence()
 :)
declare private function user-management:create-user(
    $fn-user as xdmp:function,
    $user as item()*,
    $prefix as xs:string
) as empty-sequence()
{
    let $user-map := xdmp:apply($fn-user, $user, $prefix)
    let $user-name := map:get($user-map, "user-name")
    let $user-desc := map:get($user-map, "user-description")
    let $user-password := map:get($user-map, "password")
    let $role-name := map:get($user-map, "role-name")
    let $collections := map:get($user-map, "collections")
    let $permissions := xdmp:value(map:get($user-map, "permissions"))
    let $_ := (
        xdmp:trace("security", "calling /ext/security/dhf-create-user.xqy for user " || $user-name),
        xdmp:trace("security", $user-map),
        xdmp:invoke("/ext/security/dhf-create-user.xqy",
            (xs:QName("params"), map:new((
                map:entry("user-name", $user-name),
                map:entry("description", $user-desc),
                map:entry("user-password", $user-password),
                map:entry("user-role", $role-name),
                map:entry("permissions", $permissions),
                map:entry("collections", $collections)
            ))),
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
                <update>true</update>
                <isolation>different-transaction</isolation>
            </options>
        )
    )
    return ()
};

(:~
 : This function creates a set of sec:permission elements to be added to the resulting harmonized document
 :
 : @param   $fn-user-permissions, function to create a set of userspecific permissions
 : @param   $id, the identifier for the document to write
 : @return  a set of  sec:permission elements that holds the roles with appropriate permissions.
 :)
declare function user-management:document-permissions(
    $fn-user-permissions as xdmp:function,
    $id as xs:string,
    $prefix as xs:string
) as element(sec:permission)*
{
    xdmp:apply($fn-user-permissions, $id, $prefix)
};

(:~
 : Takes $pattern as a parameter that is a scheme for executing the function.
 : When executed, the function removes all the roles from Security database
 : that match the predefined pattern.
 :
 : @param   $pattern one or more patterns specified by the user that is used to filter the roles for delition
 : @return  empty-sequence()
 :)
declare function user-management:remove-roles-by-pattern(
    $pattern as xs:string
) as xs:string*
{
    let $role-names :=
        xdmp:invoke-function(
            function() {
                sec:get-role-names()/fn:string()
            },
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
            </options>
        )
    let $roles-to-delete := fn:filter(function($a) {fn:matches($a, $pattern)}, $role-names)
    return
        if (fn:count($roles-to-delete) > 0)
        then xdmp:invoke-function(
            function() {
                xdmp:trace("security", "Roles to delete:" || fn:string-join($roles-to-delete, ",")),
                $roles-to-delete ! (sec:remove-role(.), .)
            },
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
            </options>
        )
        else ()
};

(:~
 : Takes $pattern as a parameter that is a scheme for executing the function.
 : When executed, the function removes all the users from Secuirty database
 : that match the predefined pattern.
 :
 : @param   $pattern specified by the user that is used to filter the users for delition
 : @return  empty-sequence()
 :)
declare function user-management:remove-users-by-pattern(
    $pattern as xs:string
) as xs:string*
{
    let $user-names :=
        xdmp:invoke-function(
            function() {
                for $user in //sec:user
                let $user-name := $user/sec:user-name/text()
                return $user-name
            },
            <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
            </options>)
    let $users-to-delete := fn:filter(function($a) {fn:matches($a, $pattern)}, $user-names)
    return
        if (fn:count($users-to-delete) > 0)
        then xdmp:invoke-function(
            function() {
                xdmp:trace("security", "Users to delete:" || fn:string-join($users-to-delete, ",")),
                $users-to-delete ! (sec:remove-user(.), .)
            },
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
            </options>
        )
        else ()
};
