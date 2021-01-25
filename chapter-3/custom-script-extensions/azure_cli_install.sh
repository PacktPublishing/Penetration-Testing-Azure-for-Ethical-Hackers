#!/bin/bash

apt-get update -y && apt-get upgrade -y
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
apt install jq zip unzip httpie -y
