(:
  Copyright 2012-2018 MarkLogic Corporation

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
:)
xquery version "1.0-ml";

module namespace mlcpFlow = "http://example.com/ext/data-hub-framework/transforms/mlcp-flow-transform";


import module namespace consts = "http://marklogic.com/data-hub/consts"
at "/data-hub/4/impl/consts.xqy";

import module namespace debug = "http://marklogic.com/data-hub/debug"
at "/data-hub/4/impl/debug-lib.xqy";

import module namespace flow = "http://marklogic.com/data-hub/flow-lib"
at "/data-hub/4/impl/flow-lib.xqy";

import module namespace perf = "http://marklogic.com/data-hub/perflog-lib"
at "/data-hub/4/impl/perflog-lib.xqy";

import module namespace trace = "http://marklogic.com/data-hub/trace"
at "/data-hub/4/impl/trace-lib.xqy";

declare namespace hub = "http://marklogic.com/data-hub";

declare option xdmp:mapping "false";

declare function mlcpFlow:transform(
    $content as map:map,
    $context as map:map
) as map:map*
{
    debug:dump-env("mlcpFlow:transform"),

    let $uri := map:get($content, "uri")
    return
        perf:log('mlcp-flow-transform(' || $uri || ')', function() {
            let $params := map:new((
                for $pair in fn:substring-before(map:get($context, 'transform_param'), ",options=") ! fn:tokenize(., ",")
                let $parts := fn:tokenize($pair, "=")
                return map:entry($parts[1], $parts[2]),
                let $options := fn:substring-after(map:get($context, 'transform_param'), ",options=")
                return
                    if (fn:empty($options))
                    then ()
                    else map:entry("options", $options)
            ))

            let $job-id := (map:get($params, "job-id"), sem:uuid-string())[1]
            let $entity-name := map:get($params, 'entity-name') ! xdmp:url-decode(.)
            let $flow-name := map:get($params, 'flow-name') ! xdmp:url-decode(.)
            let $flow := flow:get-flow(
                $entity-name,
                $flow-name,
                $consts:INPUT_FLOW
            )

            let $_ :=
                if ($flow) then ()
                else
                    fn:error(xs:QName("MISSING_FLOW"), "The specified flow " || map:get($params, "flow") || " is missing.")

            (: configure the options :)
            let $options as map:map := (
                map:get($params, "options") ! xdmp:unquote(.)/object-node(),
                map:map()
            )[1]
            let $_ := flow:set-default-options($options, $flow)

            let $mainFunc := flow:get-main($flow/hub:main)
            (: this can throw, but we want MLCP to know about problems, so let it :)
            let $envelope := flow:run-flow($job-id, $flow, $uri, map:get($content, "value"), $options, $mainFunc)

            (: write the trace for the current identifier :)
            let $item-context := map:get($flow:context-queue, $uri)
            let $_ := trace:write-trace($item-context)
            let $_ := map:put($content, "value", $envelope)
            return
                $content
        })
};
