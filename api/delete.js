/**
 * CloudBox API - Delete Handler
 * 
 * Deletes files from S3 and their metadata from DynamoDB.
 */

const { deleteFile } = require('./utils/s3');
const { createResponse } = require('./index');

/**
 * Delete handler - removes files from S3 and their metadata from DynamoDB
 */
exports.handler = async (event) => {
  try {
    const userId = event.userId;
    
    if (!userId) {
      return createResponse(401, { error: 'Unauthorized' });
    }
    
    // Get query parameters
    const queryParams = event.queryStringParameters || {};
    const fileId = queryParams.fileId;
    
    if (!fileId) {
      return createResponse(400, { error: 'fileId parameter is required' });
    }
    
    // Delete the file
    await deleteFile(userId, fileId);
    
    return createResponse(200, {
      message: 'File deleted successfully',
      fileId
    });
  } catch (error) {
    console.error('Error deleting file:', error);
    
    // Handle specific errors
    if (error.code === 'NoSuchKey') {
      return createResponse(404, { error: 'File not found' });
    }
    
    if (error.code === 'AccessDenied') {
      return createResponse(403, { error: 'Access denied to this file' });
    }
    
    return createResponse(500, { error: 'Internal Server Error' });
  }
};
