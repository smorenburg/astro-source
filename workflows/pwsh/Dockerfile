FROM mcr.microsoft.com/powershell:7.2.0-ubuntu-20.04

RUN pwsh -command "Install-Module -Name Az -Repository PSGallery -Force"

COPY /scripts /scripts

WORKDIR /scripts

CMD [ "pwsh" ]