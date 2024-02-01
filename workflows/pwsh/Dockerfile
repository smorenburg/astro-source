FROM mcr.microsoft.com/powershell:7.2.0-ubuntu-20.04

COPY /scripts /scripts

RUN pwsh -command "Install-Module -Name Az -Repository PSGallery -Force"

WORKDIR /scripts

CMD [ "pwsh" ]