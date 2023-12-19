const WebSocket = require('ws');
const CryptoJS = require('crypto-js');
const evmTestnets = require('./evmTestnets.json');
const getSecrets = require('./getSecrets.js');

class WebSocketClient {
    constructor() {
        this.authToken = null;
        this.wsToken = null;
        this.socket = null;
        this.baseUrl = 'https://api-v2.qredo.network/api/v2';
        this.wsBaseUrl = 'wss://api-v2.qredo.network/api/v2/actions/signrequests?token=';
        this.actionID = null;
        this.saHeaders = { 'Content-Type': 'application/json' };
        this.saUrl = 'http://127.0.0.1:8007/api/v2';
        // Check for environment variables and use them if available
        this.apiKey = process.env.apiKey || null;
        this.apiSecret = process.env.apiSecret || null;
        this.workspaceID = process.env.workspaceID || null;
        this.awsRegion = process.env.awsRegion || null;
        this.awsSecretName = process.env.secretsName || null;
    }
    async initializeSecrets() {
        if (this.awsRegion !== null && this.secretsName !== null) {
            try {
                const secrets = await getSecrets(this.awsSecretName, this.awsRegion);
                this.apiSecret = secrets.apiSecret;
                this.apiKey = secrets.apiKey;
                this.workspaceID = secrets.workspaceID;
                console.log('Using AWS Secrets Manager to initialize websocket')
            } catch (error) {
                console.error('Error initializing secrets:', error);
            }
        } else {
            console.log('Using Linux environment variables to initialize websocket')
        }
    }


    async approveAction() {
        let myActionID = await this.actionID;
        const url = `${this.saUrl}/client/action/${myActionID}`;
        const method = "PUT";
        const response = await fetch(url, { method, headers: this.saHeaders });
        let confirmation = await response.json();
        console.log(` * * *  chainID:${this.chainID} found as known EVM testnet: ${this.chainName}. Approving actionID: ${myActionID}  * * * `);
        console.log(confirmation);
    }

    async rejectAction() {
        let myActionID = await this.actionID;
        const url = `${this.saUrl}/client/action/${myActionID}`;
        const method = "DELETE";
        const response = await fetch(url, { method, headers: this.saHeaders });
        let confirmation = await response.json();
        console.log(` * * *  chainID:${this.chainID} not found as known EVM testnet. Rejecting actionID: ${this.actionID}  * * * `);
        console.log(confirmation);
    }

    async governAction() {
        const matchChain = evmTestnets.find(entry => entry.chainID === this.chainID);
        if (matchChain) {
            this.chainName = matchChain.name;
            await this.approveAction();
        } else {
            await this.rejectAction();
        }
    }

    async getAuthToken() {
        const getSecrets = require('./getSecrets.js');
        const method = 'GET';
        const url = `${this.baseUrl}/workspaces/${this.workspaceID}/token`
        const timestamp = Math.floor(Date.now() / 1000);
        const message = `${timestamp}${method}${url}`

        const buff = Buffer.from(this.apiSecret, 'base64');
        const secret = buff.toString('ascii');
        const hmac = CryptoJS.HmacSHA256(message, secret);
        const sig = CryptoJS.enc.Base64.stringify(hmac)
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');

        const headers = {
            'qredo-api-key': this.apiKey,
            'qredo-api-timestamp': timestamp,
            'qredo-api-signature': sig
        };
        try {
            const response = await fetch(url, { method, headers });
            const rawResponse = await response.text();

            if (!response.ok) {
                throw new Error(`HTTP Error: ${response.status} ${response.statusText}`);
            }

            let tokenResponse;
            try {
                tokenResponse = JSON.parse(rawResponse);
            } catch (err) {
                console.error('Error parsing response as JSON:', err);
                throw err;
            }

            if (!tokenResponse || !tokenResponse.token) {
                throw new Error('Token not present in response');
            }

            this.authToken = tokenResponse.token;
        } catch (error) {
            console.error('Error fetching authentication token:', error);
            throw error;
        }
    }

    async getWebSocketToken() {
        if (!this.authToken) {
            console.error('Authentication token is missing. Call getAuthToken first.');
            return;
        }

        const url = 'https://api-v2.qredo.network/api/v2/websocket/token';
        const headers = {
            'x-token': this.authToken,
            'content-type': 'application/json',
        };

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: headers,
            });

            const data = await response.json();
            this.wsToken = data.wsToken;
        } catch (error) {
            console.error('Error fetching WebSocket token:', error);
        }
    }

    openWebSocket() {
        if (!this.wsToken) {
            console.error('WebSocket token is missing. Call getWebSocketToken first.');
            return;
        }

        // Open the WebSocket connection with the acquired WebSocket token
        this.socket = new WebSocket(`${this.wsBaseUrl}${this.wsToken}`)

        this.socket.onopen = () => {
            console.log(`WebSocket connection opened to ${this.wsBaseUrl}${this.wsToken}`);

        };

        this.socket.onmessage = async (event) => {
            // Parse the entire received message as JSON
            let payloadObj;
            try {
                payloadObj = JSON.parse(event.data);
            } catch (error) {
                console.error("Error parsing message as JSON:", error);
                return;
            }

            // Check if payload is present and is base64-encoded
            if (payloadObj && payloadObj.payload) {
                // Decode the base64 payload
                let decodedPayload;
                try {
                    decodedPayload = Buffer.from(payloadObj.payload, 'base64').toString('utf-8');
                } catch (error) {
                    console.error("Error decoding payload:", error);
                    return;
                }

                // Parse the decoded payload as JSON
                let payloadData;
                try {
                    payloadData = JSON.parse(decodedPayload);
                } catch (error) {
                    console.error("Error parsing decoded payload:", error);
                    payloadData = null;
                }

                if (payloadData) {
                    // Keep the rest of the message data and print it (excluding the payload)
                    let { payload, ...restOfMessage } = payloadObj;
                    this.txDetails = restOfMessage; console.log(this.txDetails);
                    this.JSONPayload = payloadData; console.log(this.JSONPayload);
                    this.actionID = this.txDetails.id

                    // Catch chainID and run governance function
                    this.chainID = Number(payloadData.externalExtension?.network?.chainID);
                    let governStuff = this.governAction()
                } else {
                    console.log(decodedPayload);
                }
            } else {
                console.log("Payload not found or not in the expected format");
            }

        };

        this.socket.onclose = () => {
            console.log('WebSocket connection closed');
        };

        this.socket.onerror = (error) => {
            console.error('WebSocket error:', error);
        };
    }
}

// Initialise

const webSocketClient = new WebSocketClient();

async function initializeWebSocket() {
    await webSocketClient.initializeSecrets();
    await webSocketClient.getAuthToken();
    await webSocketClient.getWebSocketToken();
    await webSocketClient.openWebSocket()
}

initializeWebSocket();
