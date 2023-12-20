#!/bin/bash

# Stop recording history for this session
set +o history

# Set fancy colours
gT='\033[0;32m'; pT='\033[0;35m'; rC='\033[0m'

# Check if Node.js is installed
if command -v node &> /dev/null; then
    echo "Node.js is already installed."
else
    # Get Node.js
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    . ~/.nvm/nvm.sh
    nvm install --lts
    node -e "console.log('Running Node.js ' + process.version)"
fi

# Check if npm is installed
if command -v npm &> /dev/null; then
    echo -e "npm is already installed."
else
    # Install npm
    sudo dnf install npm -y
fi

# Install required packages if not already installed
if [ $(npm ls | egrep -c "@aws-sdk/client-secrets-manager|aws-sdk|crypto-js|node-fetch|package.json|ws") != 6 ]; then
    npm install package.json
else
    echo -e "Correct packages already installed."
fi

# Check installed packages
npm ls

# Secrets method selector
echo -e "Please select a method for the webSocket.js file to retrieve apiKey, apiSecret and workspaceID values.

If you are using AWS Secrets Manager, please structure the secret as follows:

{
${pT}\"apiKey\"${rC}: ${gT}\"apiKey\"${rC},
${pT}\"apiSecret\"${rC}: ${gT}\"apiSecret\"${rC},
${pT}\"workspaceID\"${rC}: ${gT}\"workspaceID\"${rC}
}

AWS Secrets Manager (aws)
Environment Variables (env)"
read -p "type aws or env: " secretChoice

if [[ $secretChoice == "aws" ]]; then
    # Set AWS environment variables for this session only
    read -p "Enter AWS Region name (example: us-east-1): " awsRegion
    export awsRegion

    read -p "Enter AWS Secrets Name (example: api-demo-secrets): " secretsName
    export secretsName

elif [[ $secretChoice == "env" ]]; then

    # Set environment variables for this session only
    read -p "Enter API Key: " apiKey
    export apiKey

    read -p "Enter API Secret: " apiSecret
    export apiSecret

    read -p "Enter Workspace ID: " workspaceID
    export workspaceID
fi

# Check if SA instance is running, ask for permission to start if not
if [ "$(sudo docker ps | grep -ci signing-agent)" -lt 1 ]; then
    echo "No SA instance detected, do you want to start one from this script?"
    read -p "Please enter yes or no: " yesNoStart

    if [ "$yesNoStart" == "yes" ]; then
        echo "Searching for volume directory and config.yaml file in user home directory"
        volDir=$(find "$HOME" -name volume)
        configFile=$(find "$HOME" -name config.yaml)
        echo "Volume folder: ${volDir} found | Config file: ${configFile} found. Trying to start SA instance..."
        startSA=$(sudo docker run -ti --rm --name sa-demo -d -v "${volDir}:/volume" -p 8007:8007 signing-agent:latest)

        if [ "$(sudo docker ps | grep -ci signing-agent)" -eq 1 ]; then
            echo "SA instance started successfully as...

            $(sudo docker ps)"
        else
            echo "Could not start SA instance. Please start manually and try running this utility again"
        fi
    fi
fi

# Restore history for this session
set -o history

# Start Websocket stream
node webSocket.js
