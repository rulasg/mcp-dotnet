# MCP Server build with dotnet

## Description

This is a simple server build with dotnet. It is a simple server that can be used to test the MCP protocol. It is not a full implementation of the MCP protocol, but it can be used to test the protocol and see how it works.

Follow reference [modelcontextprotocol/csharp-sdk: The official C# SDK for Model Context Protocol servers and clients. Maintained in collaboration with Microsoft.](https://github.com/modelcontextprotocol/csharp-sdk)

## Steps to build this repo

### 1. Init

Create a new directory and init a new dotnet project

```sh
md mcp-dotnet
cd mcp-dotnet
dotnet new webapi
dotnet new .gitignore

git init
git add .
git commit -m "init"
```

### 2. MCP packages added

Add the MCP packages

```sh
dotnet add package ModelContextProtocol --prerelease
dotnet add package Microsoft.Extensions.Hosting
git add .
git commit -m "MCP packages added"
```

### 3. Add Docker support

Create Dockerfile

```dockerfile
# Use the official .NET SDK image as a build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Set the working directory in the container
WORKDIR /app

# Copy the project file and restore dependencies
COPY client-repo.csproj ./
RUN dotnet restore

# Copy the rest of the application code
COPY . ./

# Build the application
RUN dotnet publish -c Release -o /out

# Use the official .NET runtime image for the runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0

# Set the working directory in the container
WORKDIR /app

# Copy the published output from the build stage
COPY --from=build /out ./

# Expose the port the application runs on
EXPOSE 80

# Set the entry point for the container
ENTRYPOINT ["dotnet", "client-repo.dll"]
```

### 4. Update Program.cs

Copy the [web sample.](https://github.com/modelcontextprotocol/csharp-sdk#getting-started-server)

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ModelContextProtocol.Server;
using System.ComponentModel;

var builder = Host.CreateApplicationBuilder(args);
builder.Logging.AddConsole(consoleLogOptions =>
{
    // Configure all logs to go to stderr
    consoleLogOptions.LogToStandardErrorThreshold = LogLevel.Trace;
});
builder.Services
    .AddMcpServer()
    .WithStdioServerTransport()
    .WithToolsFromAssembly();
await builder.Build().RunAsync();

[McpServerToolType]
public static class EchoTool
{
    [McpServerTool, Description("Echoes the message back to the client.")]
    public static string Echo(string message) => $"hello {message}";
}
```

### 5. get_customer_information

YOu can change the functionality of the server to be able to get information for a given github user.

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ModelContextProtocol.Server;
using System.ComponentModel;

var builder = Host.CreateApplicationBuilder(args);
builder.Logging.AddConsole(consoleLogOptions =>
{
    // Configure all logs to go to stderr
    consoleLogOptions.LogToStandardErrorThreshold = LogLevel.Trace;
});
builder.Services
    .AddMcpServer()
    .WithStdioServerTransport()
    .WithToolsFromAssembly();
await builder.Build().RunAsync();

[McpServerToolType]
public static class EchoTool
{
    [McpServerTool, Description("Echoes the message back to the client.")]
    public static string Echo(string message) => $"This text is echoed from MCP -  {message}";

    [McpServerTool, Description("Gets the information of a given user")]
    public static async Task<string> get_user_information(string handle)
    {
        using var httpClient = new HttpClient();
        httpClient.DefaultRequestHeaders.UserAgent.TryParseAdd("request");

        var response = await httpClient.GetAsync($"https://api.github.com/users/{handle}");
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            return content;
        }
        else
        {
            return $"Error: Unable to fetch user information. Status Code: {response.StatusCode}";
        }
    }
}
```

Refresh the docker image with the new code.

```sh
docker build -t mcp-dotnet .
```

## Installation

Follow these steps to set up and run the server:

1. **Clone the Repository**:

   ```sh
   git clone https://github.com/octodemo/mcp-dotnet
   cd mcp-dotnet
   ```

2. **Build container**:

   ```bash
   docker build -t mcp-dotnet .
   ```

## Usage in your MCP Client

To use this MCP server in your own MCP client, you can reference it as a tool in your MCP configuration. Below is an example of how to configure the MCP server in your client:

```json
{
  "Servers": {
    "mcp-dotnet": {
      "command": "docker",
      "args": [ "run", "-i", "--rm", "mcp-dotnet" ]
    }
  }
}
```
