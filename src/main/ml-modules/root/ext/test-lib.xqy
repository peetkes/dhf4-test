xquery version "1.0-ml";

(:~
: User: pkester
: Date: 05/12/2018
: Time: 14:57
: To change this template use File | Settings | File Templates.
:)

module namespace test-lib = "http://example.com/ext/test-lib";

declare function test-function(
    $input as xs:string
) as xs:string
{
    fn:upper-case($input)
};
