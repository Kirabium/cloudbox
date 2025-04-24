/**
 * CloudBox API - Main Entry Point
 * 
 * This Lambda function serves as the main router for the CloudBox API,
 * directing requests to the appropriate handler based on the HTTP method and path.
 */

const { authenticateRequest } = require('./utils/auth');

// Import handlers
const uploadHandler = require('./upload');
const listHandler = require('./list');
const downloadHandler = require('./download');
const deleteHandler = require('./delete');

/**
 * Creates an API response with proper CORS headers
 */
const createResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-Api-Key,Authorization',
    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE'
  },
  body: JSON.stringify(body)
});

/**
 * Main handler function that routes requests to the appropriate handler
 */
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  // Handle CORS preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return createResponse(200, {});
  }

  try {
    // Authenticate the request
    const authResult = await authenticateRequest(event);
    
    if (!authResult.authenticated) {
      return createResponse(401, { error: authResult.error });
    }

    // Add the authenticated user ID to the event for downstream handlers
    event.userId = authResult.userId;

    // Route to the appropriate handler based on the HTTP method and path
    const { httpMethod, path } = event;
    const resourcePath = path.split('/').pop();

    switch (true) {
      case httpMethod === 'POST' && resourcePath === 'upload':
        return await uploadHandler.handler(event);
      
      case httpMethod === 'GET' && resourcePath === 'list':
        return await listHandler.handler(event);
      
      case httpMethod === 'GET' && resourcePath === 'download':
        return await downloadHandler.handler(event);
      
      case httpMethod === 'DELETE' && resourcePath === 'delete':
        return await deleteHandler.handler(event);
      
      default:
        return createResponse(404, { error: 'Not Found' });
    }
  } catch (error) {
    console.error('Error processing request:', error);
    return createResponse(500, { error: 'Internal Server Error' });
  }
};

// Export the response utility for other handlers
exports.createResponse = createResponse;
