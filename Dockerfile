# Use the official .NET SDK image as a build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Set the working directory in the container
WORKDIR /app

# Copy the project file and restore dependencies
COPY mcp-dotnet.csproj ./
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
ENTRYPOINT ["dotnet", "mcp-dotnet.dll"]

