#!/bin/bash

# Stop recording history for this session
set +o history

# Set fancy colours
greenText='\033[0;32m'
resetColour='\033[0m'

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
    echo -e "${greenText} npm is already installed. ${resetColour}"
else
    # Install npm
    sudo dnf install npm -y
fi

# Install required packages if not already installed
if [ $(npm ls | egrep -c "@aws-sdk/client-secrets-manager|aws-sdk|crypto-js|node-fetch|package.json|ws") != 6 ]; then
    npm install package.json
else
    echo -e "${greenText} Correct packages already installed. ${resetColour}"
fi

# Check installed packages
npm ls

# Secrets method selector
echo -e "${greenText} Please select a method for the webSocket.js file to retrieve apiKey, apiSecret and workspaceID values.

If you are using AWS Secrets Manager. Please structure the secret as follows:

{
"apiKey": apiKey,
"apiSecret": apiSecret,
"workspaceID": workspaceID
}

AWS Secrets Manager (aws)
Environment Variables (env)${resetColour}"
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
