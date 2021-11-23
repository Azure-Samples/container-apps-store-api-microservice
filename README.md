# Container App Store Microservice Sample

This is a sample microservice solution for Azure Container Apps.  It will create a store microservice which will need to call into an order service and an inventory service.  Dapr is used to secure communication and calls between services, and Azure API Management and Azure Cosmos DB are created alongside the microservices.

The entire solution is configured with [GitHub Actions](https://github.com/features/actions) and [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/overview) for CI/CD.

IMPORTANT: In general, each microservice should have an independent release and deployment. For the sake of this sample we are building and deploying as part of a single repo.  

- [Deploy](#deploy)
- [Solution Overview](#solution-overview)
- [Build and run](#build-and-run)  
<br/>

### Demo 
[<img src="./assets/thumbnail.png" alt="Demo video" width="400">](https://youtu.be/fmGHEJL81rU)

<br/>

### Github Actions Secrets

## Deploy and Run

### Deploy via GitHub Actions (recommended)

1. Fork the sample repo
2. Create the following required [encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) for the sample

  | Name | Value |
  | ---- | ----- |
  | AZURE_CREDENTIALS | The JSON credentials for an Azure subscription. [Learn more](https://docs.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#create-a-service-principal-and-add-it-as-a-github-secret) |
  | RESOURCE_GROUP | The name of the resource group to create |
  | PACKAGES_TOKEN | A GitHub personal access token with the `read:packages` scope. [Learn more](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) |

3. Open the GitHub Actions, select the **Build and Deploy** action and choose to run the workflow.  
  
    This will start the GitHub Actions which will build the code, publish them to your GitHub repository as private container images, create an Azure Container App environment, a Cosmos DB database, and Container Apps for each of the microservices.
4. Once the GitHub Actions have completed successfully, navigate to the [Azure Portal](https://portal.azure.com) and select the resource group you created.  Open the `node-app` container, and browse to the URL.  You should see the sample application running.  You can go through the UX to create an order through the order microservice, and then navigate to the `/orders?id=foo` endpoint and `/inventory?id=foo` to get the status via other microservices.  
5. After calling each microservice, you can open the application insights resource created and select the **Application Map**, you should see a visualization of your calls between Container Apps (note: it may take a few minutes for the app insights data to ingest and process into the app map view).

### Deploy via Azure Bicep

You can also deploy the solution at anytime using the Azure CLI.

1. Clone the repo and navigate to the folder
2. Run the following CLI command (with appropiate values for $variables)
  ```cli
  az group create -n $resourceGroup -l canadacentral
  az deployment group create -g $resourceGroup -f ./deploy/main.bicep \
    -p \
      minReplicas=0 \
      nodeImage='ghcr.io/jeffhollan/container-apps-store-api-microservice/node-service:main' \
      nodePort=3000 \
      isNodeExternalIngress=true \
      pythonImage='ghcr.io/jeffhollan/container-apps-store-api-microservice/python-service:main' \
      pythonPort=5000 \
      isPythonExternalIngress=false \
      goImage='ghcr.io/jeffhollan/container-apps-store-api-microservice/go-service:main' \
      goPort=8050 \
      isGoExternalIngress=false \
      containerRegistry=ghcr.io \
      containerRegistryUsername=$username \
      containerRegistryPassword=$GitHubPackagesToken
  ```
3. Continue with Step #4 in the GitHub Actions flow above to test your solution

## Solution Overview

![image of architecture](./assets/arch.png)

There are three main microservices in the solution.  

#### Store API (`node-app`)
The [`node-app`](./node-service) is an express.js API that exposes three endpoints.  `/` will return the primary index page, `/order` will return details on an order (retrieved from the **order service**), and `/inventory` will return details on an inventory item (retrieved from the **inventory service**).

#### Order Service (`python-app`)
The [`python-app`](./python-service) is a Python flask app that will retrieve and store the state of orders.  It uses [Dapr state management](https://docs.dapr.io/developing-applications/building-blocks/state-management/state-management-overview/) to store the state of the orders.  When deployed in Container Apps, Dapr is configured to point to an Azure Cosmos DB to back the state. 

#### Inventory Service (`go-app`)
The [`go-app`](./go-service) is a Go mux app that will retrieve and store the state of inventory.  For this sample, the mux app just returns back a static value.

## Build and Run

- [Option 1: Build and run with GitHub Codespaces (recommended)](#option-1-build-and-run-with-github-codespaces-recommended)
- [Option 2: Build and run with VS Code Dev Containers](#option-2-build-and-run-with-vs-code-dev-containers)
- [Option 3: Build and run with VS Code directly](#option-3-build-and-run-with-vs-code-directly)
- [Option 4: Build and run manually](#option-4-build-and-run-manually)

### Option 1: Build and run with GitHub Codespaces (recommended)

#### Pre-requisites
- A GitHub account with access to [GitHub Codespaces](https://github.com/features/codespaces)  

#### Steps
1. Select **Code** and open in Codespace from GitHub
2. After the codespaces has initialized, select to debug and run **All Containers** to run the sample locally

### Option 2: Build and run with VS Code Dev Containers

#### Pre-requisites
- Docker (with docker-compose)
- VS Code with the [remote containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension installed

#### Steps
1. Fork the sample repo
2. Clone the repo: `git clone https://github.com/{username}/container-apps-store-api-microservice`
3. Open the cloned repo in VS Code
4. Follow the prompt to open in a dev container
5. Select the debug **All Containers** and run the sample locally

Any changes made to the project and checked into your GitHub repo will trigger a GitHub action to build and deploy

### Option 3: Build and run with VS Code Directly

#### Pre-requisites
- [VS Code](https://code.visualstudio.com/) with the [recommended extensions](./.vscode/extensions.json) installed
- [Node.js](https://nodejs.org/en/download/)
- [Python 3.x](https://www.python.org/downloads/)
- [Go](https://golang.org/doc/install)
- [Dapr](https://docs.dapr.io/getting-started/install-dapr-cli/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)
- [Azure Container Apps CLI extension](https://github.com/microsoft/azure-container-apps)

1. Fork the sample repo
2. Clone the repo: `git clone https://github.com/{username}/container-apps-store-api-microservice`
3. Open the cloned repo in VS Code
4. Follow the prompt to install recommended extensions
5. Select the debug **All Containers** and run the sample locally

Any changes made to the project and checked into your GitHub repo will trigger a GitHub action to build and deploy

### Option 4: Build and run manually

#### Pre-requisites
- [Node.js](https://nodejs.org/en/download/)
- [Python 3.x](https://www.python.org/downloads/)
- [Go](https://golang.org/doc/install)
- [Dapr](https://docs.dapr.io/getting-started/install-dapr-cli/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)
- [Azure Container Apps CLI extension](https://github.com/microsoft/azure-container-apps)

#### Steps

1. Fork the sample repo
2. Clone the repo: `git clone https://github.com/{username}/container-apps-store-api-microservice`
3. Build the sample: 
```bash
cd node-service
npm install
cd ../go-service
go install
cd ../python-service
pip install -r requirements.txt
cd ..
```
4. Run the sample
##### Local run and debug

Dapr will be used to start microservices and enable APIs for things like service discovery, state management, and observability.  The code for `store-api` service invokes other services at the localhost:daprport host address, and sets the `dapr-app-id` HTTP header to enable service discovery using an HTTP proxy feature. 

Run the `node-app` (store-api) service in a new terminal window:
```bash
dapr run --app-id node-app --app-port 3000 --dapr-http-port 3501 --components-path ./components -- npm run start
```

Run the `python-app` (order) service in a new terminal window:
```bash
dapr run --app-id python-app --app-port 5000 --dapr-http-port 3500 --components-path . -- python3 app.py
```

Run the `go-app` (inventory) service in a new terminal window:
```bash
dapr run --app-id go-app --app-port 8050 --dapr-http-port 3502 -- go run .
```

`State management`: orders app calls the Dapr State Store APIs which are bound to a Redis container that is preinstalled with Dapr.  When the application is later deployed to Azure Container Apps, the component config yaml will be modified to point to an Azure CosmosDb instance.  No code changes will be needed since the Dapr State Store API is completely portable.  

`Observability`: distributed tracing is enabled by default on (http://localhost:9411/).  Browse to this URL to inspect any distributed trace or to inspect dependencies in real time.  When the application is deployed to Azure we recommend modifying the component config YAML to enable [Open Telemetry and Application Insights](https://docs.dapr.io/operations/monitoring/tracing/open-telemetry-collector-appinsights/). 

##### Local run and debug easily using Tye (optional)

Tye is a new tool that makes it easy to run multiple microservices, observe in a dashboard, and tail the logs.  This is an alternative to manually doing the three `dapr run` commands above.  This step requires a pre-requistite install of Tye from (https://aka.ms/tye). 

To run all services using Tye simply:
```bash
tye run
```

Once the microservices are started by Tye you can observe in the Tye dashboard.  The Tye dashboard will be listed in the standard output, and typically this is available at (http://localhost:8000). In the dashboard you can view each microservice, endpoint, and view Logs.
