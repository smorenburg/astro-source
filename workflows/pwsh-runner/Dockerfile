FROM mcr.microsoft.com/azure-powershell:ubuntu-22.04

RUN apt-get update
RUN apt-get install -y wget

RUN wget -O bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
RUN chmod +x ./bicep
RUN mv ./bicep /usr/local/bin/bicep

ENV PSModulePath="$PSModulePath:/powershell"

COPY /powershell /powershell
COPY /bicep /bicep

CMD ["pwsh", "-Command", "$PSVersionTable"]