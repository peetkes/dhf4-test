# Test Project for deploying dhf4.0.1 project on cluster

Check out :
````
git clone git@github.com:peetkes/dhf4-test.git
````
Adjust properties in gradle.properties or add gradle-local.properties with your mileage:
````
mlHost=....

mlUsername=....
mlPassword=....

````
When running 

````
gradle mlDeploy -i
````

it will give below error 

````
Execution failed for task ':hubInstallModules'.
> Error occurred while loading REST modules: Error occurred while loading modules; host: ericsson-1.demo.marklogic.com; port: 8010; cause: Local message: /config/query not found for write. Server Message: Server (not a REST instance?) did not respond with an expected REST Error message.
````

