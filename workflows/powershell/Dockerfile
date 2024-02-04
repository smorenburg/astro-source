FROM mcr.microsoft.com/azure-powershell:alpine-3.17

COPY /scripts /scripts

WORKDIR /scripts

CMD [ "pwsh", "-Command", "$PSVersionTable" ]