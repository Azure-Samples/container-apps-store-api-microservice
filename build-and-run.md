## Build and run solution

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
5. Select the debug **All Services** and run the sample locally

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
5. Select the debug **All Services** and run the sample locally

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

Dapr will be used to start microservices and enable APIs for things like service discovery and state management. The code for `store-api` service invokes other services at the localhost:daprport host address, and sets the `dapr-app-id` HTTP header to enable service discovery using an HTTP proxy feature.

Run the `node-app` (store-api) service in a new terminal window:

```bash
dapr run --app-id node-app --app-port 3000 --dapr-http-port 3501 --components-path ./dapr-components -- npm run start
```

Run the `python-app` (order) service in a new terminal window:

```bash
dapr run --app-id python-app --app-port 5000 --dapr-http-port 3500 --components-path ./dapr-components -- python3 app.py
```

Run the `go-app` (inventory) service in a new terminal window:

```bash
dapr run --app-id go-app --app-port 8050 --dapr-http-port 3502 --components-path ./dapr-components -- go run .
```

`State management`: orders app calls the Dapr State Store APIs which are bound to a Redis container that is preinstalled with Dapr. When the application is later deployed to Azure Container Apps, the component config yaml will be modified to point to an Azure CosmosDb instance. No code changes will be needed since the Dapr State Store API is completely portable.
