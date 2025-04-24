/**
 * CloudBox API - List Handler
 * 
 * Lists files stored in S3 for the authenticated user.
 */

const { listFiles } = require('./utils/s3');
const { createResponse } = require('./index');

/**
 * List handler - retrieves a list of files for the authenticated user
 */
exports.handler = async (event) => {
  try {
    const userId = event.userId;
    
    if (!userId) {
      return createResponse(401, { error: 'Unauthorized' });
    }
    
    // Get query parameters
    const queryParams = event.queryStringParameters || {};
    const limit = queryParams.limit ? parseInt(queryParams.limit, 10) : 100;
    
    // Get files for the user
    const files = await listFiles(userId);
    
    // Add presigned URLs to the response if requested
    const includeUrls = queryParams.includeUrls === 'true';
    
    // Apply pagination if necessary
    const paginatedFiles = files.slice(0, limit);
    
    return createResponse(200, {
      files: paginatedFiles,
      total: files.length,
      limit,
      includeUrls
    });
  } catch (error) {
    console.error('Error listing files:', error);
    return createResponse(500, { error: 'Internal Server Error' });
  }
};
