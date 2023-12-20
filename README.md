# Qredo Signing Agent Logic Example

This repository uses a webSocket connection to the Qredo API network and receives approval data in JSON. If the chainID of the transaction matches an entry in the 'evmTestnets.json' file an approval is sent to a Signing Agent (SA) instance running on the localhost.

## Purpose

Please use this tool as an practical example of performing fully automated governance decisions via customisable logic. Take the opportunity to look at the full set of human readable web3 data presented over the websocket.

This rich metadata can be used to create powerful conditional logic to need the requirements of your business. 

## Pre-Reqs

- You have followed the Qredo API video tutorials [here](https://www.youtube.com/playlist?list=PLOPaH-ltpzReDIuBRwN_Hhw1-R5bQoq6p).
- You already have a Qredo SA instance running on the same host.
- This SA instance is registered as an approver and included within at least 1 transaction policy.
- The SA instance has AutoApprove set to **false** in config.yaml.
- You are using an Amazon Linux 2023 OS with sudo privileges.
- You have read and understood the API security best pracices guide [here](https://developers.qredo.com/developer-guides/qredo-api/security-best-practices).

## Installation and Usage

- Clone the Repo
```bash
git clone https://github.com/grahamlaye/saLogic.git
```
- Change into the repo directory
```bash
cd saLogic
```
- Run the setup.bash script. **IMPORTANT: ** Please run this script as per the example below. Typing "bash setup.bash" or "./setup.bash" results in errors.
```bash
. setup.bash
```

The Setup script will check if necessary, will install Node.js and the necessary dependencies to run the webSocket.js application.

You will be prompted to decide how you want to access your apiKey, apiSecret and workspaceID credentials necessary to run the websocket. This can be either AWS or Linux environment variables.

For increased security, we recommend using AWS Secrets Manager where possible. If you select environment variables the setup script will:

- Disable history for execution of script.
- Save 3 environment variables; apiKey, apiSecret & workspaceID.
- These will **ONLY** be available to the current user's session. Variables are not shared or persisted.
- Where both AWS variables and environment variables exist, the webSocket.js script will default to AWS.
- Start the websSocket.js script.

## Initiate a transaction. Using your own code or the Postman examples cited in the [API tutorial videos](https://www.youtube.com/playlist?list=PLOPaH-ltpzReDIuBRwN_Hhw1-R5bQoq6p).
For example:
```json
{
"broadcast": false,
"chainID": "5",
"from": "your_web3_api_wallet_address",
"gas": "",
"input": "",
"maxFeePerGas": "",
"maxPriorityFeePerGas": "",
"nonce": "",
"note": "",
"description": "",
"to": "destination_wallet_address",
"value": "value_in_wei"
}
```

The websocket should report the actionID is found as a known EVM testnet in evmTestnets.json and push an approval signal to your SA instance. For example:
```bash
 * * *  chainID:5 found as known EVM testnet: Ethereum Goerli. Approving actionID: 2ZmdhoN1M154CW7j8dkzDl40tzr  * * *
{ actionID: '2ZmdhoN1M154CW7j8dkzDl40tzr', status: 'approved' }
```

Consider changing the chainID in your transaction request to a known mainnet. For example this transaction is over the Ethereum mainnet (chainID: 1). As it is not found in the evmTestnets.json file a reject is signalled for this actionID to our SA instance.

```json
{
"broadcast": false,
"chainID": "1",
"from": "your_web3_api_wallet_address",
"gas": "",
"input": "",
"maxFeePerGas": "",
"maxPriorityFeePerGas": "",
"nonce": "",
"note": "",
"description": "",
"to": "destination_wallet_address",
"value": "value_in_wei"
}
```

You should now see this in the websocket stream:

```bash
 * * *  chainID:1 not found as known EVM testnet. Rejecting actionID: 2ZmdfXiD6ManikMgu32IlMnwfNu  * * *
{ actionID: '2ZmdfXiD6ManikMgu32IlMnwfNu', status: 'rejected' }
```

Thank you for following this example.



