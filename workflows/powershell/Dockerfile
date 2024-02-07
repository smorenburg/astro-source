FROM mcr.microsoft.com/azure-powershell:alpine-3.17

ENV PSModulePath="$PSModulePath:/Modules"

COPY /Modules /Modules

CMD [ "pwsh", "-Command", "$PSVersionTable" ]