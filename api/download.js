/**
 * CloudBox API - Download Handler
 * 
 * Generates presigned URLs for downloading files from S3.
 */

const AWS = require('aws-sdk');
const { getPresignedUrl } = require('./utils/s3');
const { createResponse } = require('./index');

// Initialize DynamoDB client
const dynamodb = new AWS.DynamoDB.DocumentClient();

/**
 * Verify that the user has access to the requested file
 * @param {string} userId - User ID
 * @param {string} fileId - File ID to verify
 * @returns {boolean} Whether the user has access
 */
const verifyFileAccess = async (userId, fileId) => {
  const params = {
    TableName: process.env.DYNAMODB_TABLE,
    Key: {
      userId,
      fileId
    }
  };
  
  try {
    const result = await dynamodb.get(params).promise();
    return !!result.Item;
  } catch (err) {
    console.error('Error verifying file access:', err);
    return false;
  }
};

/**
 * Download handler - generates presigned URLs for file downloads
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
    
    // Verify that the user has access to this file
    const hasAccess = await verifyFileAccess(userId, fileId);
    
    if (!hasAccess) {
      return createResponse(403, { error: 'Access denied to this file' });
    }
    
    // Get expiration time from query params or use default (1 hour)
    const expiresIn = queryParams.expiresIn 
      ? parseInt(queryParams.expiresIn, 10)
      : 3600;
    
    // Generate the presigned URL
    const downloadUrl = await getPresignedUrl(fileId, expiresIn);
    
    return createResponse(200, {
      downloadUrl,
      fileId,
      expiresIn
    });
  } catch (error) {
    console.error('Error generating download URL:', error);
    return createResponse(500, { error: 'Internal Server Error' });
  }
};
