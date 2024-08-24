################################################################################
##################################################################   build   ###

FROM  --platform=linux/amd64  mcr.microsoft.com/dotnet/sdk:6.0  as  build

WORKDIR  /app/

COPY  ./Shared/Shared.csproj  ./Shared/Shared.csproj
COPY  ./Server/Server.csproj  ./Server/Server.csproj

ARG TARGETARCH

# Download NuGet dependencies
RUN  dotnet  restore  \
    ./Server/Server.csproj  \
    -r debian.11-`echo $TARGETARCH | sed 's@^amd@x@'`  \
;

COPY  ./Shared/  ./Shared/
COPY  ./Server/  ./Server/

# Build application binary
RUN  dotnet  publish  \
    ./Server/Server.csproj  \
    -r debian.11-`echo $TARGETARCH | sed 's@^amd@x@'`  \
    -c Release  \
    -o ./out/  \
    --no-restore  \
    --self-contained  \
    -p:publishSingleFile=true  \
;

##################################################################   build   ###
################################################################################
################################################################   runtime   ###

FROM  mcr.microsoft.com/dotnet/runtime:6.0  as  runtime

# Create the user and group 'container'
RUN groupadd -r container && \
    useradd -r -g container -d /home/container -m container

# Set the working directory to /home/container
WORKDIR /home/container

# Copy application binary from build stage
COPY  --from=build  /app/out/  /app/

# Set the USER before creating the directory to ensure it's owned by the container user
USER container
ENV  USER=container HOME=/home/container

# Ensure the data directory exists and set permissions
RUN mkdir -p /home/container/data && \
    chown -R container:container /home/container/data && \
    chmod -R 770 /home/container/data

ENTRYPOINT  [ "/app/Server" ]
EXPOSE      1027/tcp
WORKDIR     /home/container/data/
VOLUME      /home/container/data/

################################################################   runtime   ###
################################################################################
