xquery version "1.0-ml";

(:~
: User: I33291
: Date: 11-5-2018
: Time: 17:13
:)

module namespace document-permissions = "http://marklogic.com/dhf41/ext/security/dhf-document-permissions";
import module namespace sec = "http://marklogic.com/xdmp/security"
at "/MarkLogic/security.xqy";

declare option xdmp:mapping "false";

(:
 : Wraps desk and region that was extracted in writer.xqy
 : and proceeds with cleaning the strings and constructing
 : meaningful names, furthermore, it quitely passes refined variables to
 : document-permissions:create-region-desk-roles()
 :
 : @param fn-level1, a function to be called for creation of a level1 role
 : @param level1, a string as returned by $envelope in writer.xqy
 : @param level1-prefix, a string to be used as the prefix for the level1 role
 : @return nothing
 :)
declare function document-permissions:role-creation(
    $fn-level1 as xdmp:function,
    $level1 as xs:string,
    $level1-prefix as xs:string
) as empty-sequence()
{

    let $level1-role := xdmp:apply($fn-level1, $level1, $level1-prefix)
    return  document-permissions:create-level1-roles($level1-role)
};

(:
 : Wraps desk and region that was extracted in writer.xqy
 : and proceeds with cleaning the strings and constructing
 : meaningful names, furthermore, it quitely passes refined variables to
 : document-permissions:create-region-desk-roles()
 : @param $desk a string, as returned by $envelope in writer.xqy
 : @param $region a string, as returned by $envelope in writer.xqy
 : @return nothing
 :)
declare function document-permissions:role-creation(
    $fn-level1 as xdmp:function,
    $level1 as xs:string+,
    $level1-prefix as xs:string,
    $fn-level2 as xdmp:function,
    $level2 as xs:string+,
    $level2-prefix as xs:string
) as empty-sequence()
{

    let $level1-role := xdmp:apply($fn-level1, $level1, $level1-prefix)
    let $level2-role := xdmp:apply($fn-level2, $level2, $level2-prefix)
    return  document-permissions:create-level1-level2-roles($level1-role, $level2-role)
};

(:
 : Creates region roles and desk roles, if they don't exist,
 : and assigns the desk roles to appropriate region role
 : @param $region-role a string, as declared in document-permissions:role-creation()
 : @param $desk-role a string, as declared in document-permissions:role-creation()
 : @return nothing
 :)
declare private function document-permissions:create-level1-level2-roles(
    $level1-map as map:map,
    $level2-map as map:map
) as empty-sequence()
{
    let $level1-role := map:get($level1-map, "role-name")
    let $level1-role-desc := map:get($level1-map, "description")
    let $level1-role-list := map:get($level1-map, "role-list")
    let $level1-prefix := map:get($level1-map, "prefix")
    let $level2-role := map:get($level2-map, "role-name")
    let $level2-role-desc := map:get($level2-map, "description")
    let $level2-role-list := map:get($level2-map, "role-list")
    let $level2-prefix := map:get($level2-map, "prefix")

    let $_ := (
        if (fn:not($level1-role = $level1-prefix)) then (
            xdmp:trace("security", "calling /ext/security/dhf-create-role.xqy for role " || $level1-role),
            xdmp:trace("security", $level2-map),
            xdmp:invoke("/ext/security/dhf-create-role.xqy",
                (xs:QName("params"),map:new((
                    map:entry("role-name", $level1-role),
                    map:entry("role-description", $level1-role-desc),
                    map:entry("role-names", $level1-role-list)
                ))),
                <options xmlns="xdmp:eval">
                    <database>{xdmp:database("Security")}</database>
                    <update>true</update>
                    <isolation>different-transaction</isolation>
                </options>)
        ) else(),
        if (fn:not($level2-role = $level2-prefix)) then (
            xdmp:trace("security", "calling /ext/security/dhf-create-role.xqy for with role " || $level2-role),
            xdmp:trace("security", $level2-map),
            xdmp:invoke("/ext/security/dhf-create-role.xqy",
                (xs:QName("params"),map:new((
                    map:entry("role-name", $level2-role),
                    map:entry("role-description", $level2-role-desc),
                    map:entry("role-names", $level2-role-list)
                ))),
                <options xmlns="xdmp:eval">
                    <database>{xdmp:database("Security")}</database>
                    <update>true</update>
                    <isolation>different-transaction</isolation>
                </options>)
        ) else(),
        xdmp:invoke("/ext/security/dhf-add-roles.xqy",
            (xs:QName("params"), map:new((
                map:entry("role-name", $level1-role),
                map:entry("role-names", $level2-role)
            ))),
            <options xmlns="xdmp:eval">
                <database>{xdmp:database("Security")}</database>
                <update>true</update>
                <isolation>different-transaction</isolation>
            </options>)
    )
    return()
};

(:
 : Creates region roles and desk roles, if they don't exist,
 : and assigns the desk roles to appropriate region role
 : @param $region-role a string, as declared in document-permissions:role-creation()
 : @param $desk-role a string, as declared in document-permissions:role-creation()
 : @return nothing
 :)
declare private function document-permissions:create-level1-roles(
    $level1-map as map:map
) as empty-sequence()
{
    let $level1-role := map:get($level1-map, "role-name")
    let $level1-role-desc := map:get($level1-map, "description")
    let $level1-role-list := map:get($level1-map, "role-list")
    let $level1-prefix := map:get($level1-map, "prefix")

    let $_ := (
        if (fn:not($level1-role = $level1-prefix)) then (
            xdmp:trace("security", "calling /ext/security/dhf-create-role.xqy for role " || $level1-role),
            xdmp:invoke("/ext/security/dhf-create-role.xqy",
                (xs:QName("params"),map:new((
                    map:entry("role-name", $level1-role),
                    map:entry("role-description", $level1-role-desc),
                    map:entry("role-names", $level1-role-list)
                ))),
                <options xmlns="xdmp:eval">
                    <database>{xdmp:database("Security")}</database>
                    <update>true</update>
                    <isolation>different-transaction</isolation>
                </options>)
        ) else()
    )
    return()
};

(:
 : Forms the permissions based on a level2-role that
 : are used to assign document-level access
 : @param $level2 a string, reflects an eligible role name
 : @return security permission element.
 :)
declare function document-permissions:set-permissions(
    $fn as xdmp:function,
    $level as xs:string,
    $prefix as xs:string
) as element(sec:permission)*
{
    xdmp:apply($fn, $level, $prefix)
};


(:~
 : This function takes a sequence of maps and creates roles in the Security database
 : The maps contain role-name, description and a list of initial sub-roles for the role.
 : If a role already exists it will be skipped.
 :
 : @param   sequence of maps containing role info.
 : @return  list of role identifiers that are created. Empty if all roles already exist.
 :)
declare function document-permissions:create-roles(
        $roles as map:map*
) as xs:unsignedLong*
{
    xdmp:invoke-function(
        function() {
            xdmp:trace("security", "tx-mode=" || xdmp:get-transaction-mode()),
            for $role in ($roles)
            let $role-name := map:get($role, "role-name")
            where fn:not(sec:role-exists($role-name))
            return sec:create-role($role-name, map:get($role, "description"), map:get($role, "role-list"), (), ())
        },
        <options xmlns="xdmp:eval">
            <database>{xdmp:database("Security")}</database>
        </options>
    )
};

(:~
 : This function takes a map with primary role as key and a sequence of roles to link to as value.
 : Prerequisite: all roles should already exist.
 :
 : @param   map containing primary roles and link roles
 : @return  emmpty-sequence()
 :)
declare function document-permissions:link-roles(
        $roles as map:map
) as empty-sequence()
{
    xdmp:invoke-function(
        function() {
            xdmp:trace("security", "tx-mode=" || xdmp:get-transaction-mode()),
            for $role in map:keys($roles)
            return sec:role-add-roles($role, map:get($roles,$role))
        },
        <options xmlns="xdmp:eval">
            <database>{xdmp:database("Security")}</database>
        </options>
    )
};