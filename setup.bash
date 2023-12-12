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
if [ $(npm ls | egrep -c "@aws-sdk/client-secrets-manager@3.470.0|aws-sdk@2.1516.0|crypto-js@4.2.0|node-fetch@3.3.2|package.json@2.0.1|ws@8.15.0") != 6 ]; then
    npm install package.json
else
    echo "Correct packages already installed."
fi

# Check installed packages
npm ls

