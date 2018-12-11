# Test Project for deploying dhf4.1.0-rc1 project on ML

You have to be connected to the MarkLogic VPN for this project to build
 
Adjust properties in gradle.properties or add gradle-local.properties with your mileage:

````
mlHost=....

mlUsername=....
mlPassword=....

````

## Setup you docker container
Get the MarkLogic installer rpm and the converter rpm and store those in the src/main/docker/marklogic folder

Build the docker image for the marklogic node

````
docker-compose build
````

Setup Node
````
gradle mlDockerSetup
````
Open a browser http://localhost:8001
Install a certificate template with your preferred values, give it the name 'dhf4-test.local' This name is used in the properties files

Go to App-Services application server and select the created certificate template in the ssl certificate template drop down box
Repeat these steps for Manage and Admin application servers.

Now the ML node is set up for https on the Admin, App-Services and Manage application servers.

## Deploy and redeploy without ssl support for the application ports

Deploy the application
````
gradle mlDeploy -i -PenvironmentName=http
````
This runs OK.

Redeploy the application
````
gradle mlRedeploy -i -PenvironmentName=http
````
This runs OK

Undeploy the application
````
gradle mlUndeploy -i -PenvironmentName=http -Pconfirm=true
````
This runs OK

## Deploy and redeploy with ssl support for the application ports

Deploy the application
````
gradle mlDeploy -i -PenvironmentName=https
````
This fails without any modules in the modules database.
Message:
````
Execution failed for task ':mlDeployApp'.
> Error occurred while loading REST modules: Error occurred while loading modules; host: localhost; port: 8010; cause: Local message: /config/query not found for write. Server Message: 404 Not Found
````

Redeploy the application
````
gradle mlRedeploy -i -PenvironmentName=https
````
This fails also with message:
````
Execution failed for task ':mlClearModulesDatabase'.
> java.io.IOException: unexpected end of stream on Connection{localhost:8011, proxy=DIRECT hostAddress=localhost/0:0:0:0:0:0:0:1:8011 cipherSuite=none protocol=http/1.1}
````

ReloadModules
````
gradle mlReloadModules -i -PenvironmentName=https
````
This fails with message:
````
Execution failed for task ':mlClearModulesDatabase'.
> java.io.IOException: unexpected end of stream on Connection{localhost:8011, proxy=DIRECT hostAddress=localhost/0:0:0:0:0:0:0:1:8011 cipherSuite=none protocol=http/1.1}
````
Undeploy the application
````
gradle mlUndeploy -i -PenvironmentName=http -Pconfirm=true
````
This runs OK


````
gradle mlDeploy -i
````

it will give below error 

````
Execution failed for task ':hubInstallModules'.
> Error occurred while loading REST modules: Error occurred while loading modules; host: ericsson-1.demo.marklogic.com; port: 8010; cause: Local message: /config/query not found for write. Server Message: Server (not a REST instance?) did not respond with an expected REST Error message.
````

