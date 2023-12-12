#!/bin/bash
# Get Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
. ~/.nvm/nvm.sh
nvm install --lts
node -e "console.log('Running Node.js ' + process.version)"

# Install npm
sudo dnf install npm -y

# Install required packages
npm install package.json

# Check installed packages
npm ls
