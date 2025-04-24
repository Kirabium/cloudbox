const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');

// Initialize Secret Manager
const secretsManager = new AWS.SecretsManager();

// Cache for secrets to avoid excessive API calls
let secretsCache = {};

/**
 * Get a secret from AWS Secrets Manager with caching
 * @param {string} secretName - Name of the secret to retrieve
 * @returns {object} The secret value
 */
const getSecret = async (secretName) => {
  if (secretsCache[secretName]) {
    return secretsCache[secretName];
  }

  const params = {
    SecretId: secretName
  };

  try {
    const data = await secretsManager.getSecretValue(params).promise();
    let secret;
    
    if (data.SecretString) {
      secret = JSON.parse(data.SecretString);
    } else {
      const buff = Buffer.from(data.SecretBinary, 'base64');
      secret = JSON.parse(buff.toString('ascii'));
    }
    
    secretsCache[secretName] = secret;
    return secret;
  } catch (err) {
    console.error(`Error retrieving secret ${secretName}`, err);
    throw err;
  }
};

/**
 * Verify API Key authentication
 * @param {string} apiKey - API Key from request headers
 * @returns {object} Authentication result with userId if successful
 */
const verifyApiKey = async (apiKey) => {
  if (!apiKey) {
    return { authenticated: false, error: 'API Key is required' };
  }

  try {
    const secrets = await getSecret(process.env.API_KEYS_SECRET_NAME);
    
    // Find user with matching API key
    const user = Object.keys(secrets.apiKeys).find(
      userId => secrets.apiKeys[userId] === apiKey
    );
    
    if (!user) {
      return { authenticated: false, error: 'Invalid API Key' };
    }
    
    return { authenticated: true, userId: user };
  } catch (err) {
    console.error('Error verifying API key', err);
    return { authenticated: false, error: 'Authentication error' };
  }
};

/**
 * Verify JWT token
 * @param {string} token - JWT token from Authorization header
 * @returns {object} Authentication result with userId if successful
 */
const verifyJwt = async (token) => {
  if (!token) {
    return { authenticated: false, error: 'JWT token is required' };
  }

  try {
    // Remove "Bearer " prefix if present
    if (token.startsWith('Bearer ')) {
      token = token.slice(7);
    }
    
    const secrets = await getSecret(process.env.JWT_SECRET_NAME);
    const decoded = jwt.verify(token, secrets.jwtSecret);
    
    return { 
      authenticated: true, 
      userId: decoded.sub,
      claims: decoded
    };
  } catch (err) {
    console.error('Error verifying JWT', err);
    return { authenticated: false, error: 'Invalid token' };
  }
};

/**
 * Authenticate a request using either API Key or JWT
 * @param {object} event - Lambda event object
 * @returns {object} Authentication result
 */
const authenticateRequest = async (event) => {
  const headers = event.headers || {};
  
  // Try API Key first
  if (headers['x-api-key']) {
    return verifyApiKey(headers['x-api-key']);
  }
  
  // Then try JWT in Authorization header
  if (headers.Authorization || headers.authorization) {
    const authHeader = headers.Authorization || headers.authorization;
    return verifyJwt(authHeader);
  }
  
  return { authenticated: false, error: 'No authentication credentials provided' };
};

module.exports = {
  authenticateRequest,
  verifyApiKey,
  verifyJwt,
  getSecret
}; 