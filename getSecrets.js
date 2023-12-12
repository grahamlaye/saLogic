const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

async function getSecrets(secretName, region) {
    const client = new SecretsManagerClient({ region });

    try {
        const response = await client.send(
            new GetSecretValueCommand({
                SecretId: secretName,
                VersionStage: "AWSCURRENT",
            })
        );

        const secret = JSON.parse(response.SecretString);
        return {
            apiSecret: secret.apiSecret,
            apiKey: secret.apiKey,
            workspaceID: secret.workspaceID,
        };
    } catch (error) {
        console.error('Error fetching secrets from AWS Secrets Manager:', error);
        throw error;
    }
}

module.exports = getSecrets;

