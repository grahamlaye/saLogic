#!/bin/bash

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
    echo "npm is already installed."
else
    # Install npm
    sudo dnf install npm -y
fi

# Install required packages if not already installed
if [ $(npm ls | egrep -c "@aws-sdk/client-secrets-manager|aws-sdk|crypto-js|node-fetch|package.json|ws") != 6 ]; then
    npm install package.json
else
    echo "Correct packages already installed."
fi

# Check installed packages
npm ls

# Stop OS from recording history for this session.
set +o history

# Set environment variables for this session only.
read -p "Enter API Key: " apiKey
export apiKey

read -p "Enter API Secret: " apiSecret
export apiSecret

read -p "Enter Workspace ID: " workspaceID
export workspaceID

