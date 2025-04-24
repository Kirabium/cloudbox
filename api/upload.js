/**
 * CloudBox API - Upload Handler
 * 
 * Handles file uploads to S3 and stores metadata in DynamoDB.
 */

const { uploadFile } = require('./utils/s3');
const { createResponse } = require('./index');

/**
 * Parse multipart form data from API Gateway event
 * @param {object} event - Lambda event object
 * @returns {object} Parsed file data
 */
const parseMultipartData = (event) => {
  if (!event.body) {
    throw new Error('Missing request body');
  }

  // Check if the body is base64 encoded
  const body = event.isBase64Encoded
    ? Buffer.from(event.body, 'base64').toString('utf8')
    : event.body;

  const contentType = event.headers['Content-Type'] || event.headers['content-type'];
  
  if (!contentType || !contentType.includes('multipart/form-data')) {
    throw new Error('Content-Type must be multipart/form-data');
  }

  const boundary = contentType.split('boundary=')[1];
  
  if (!boundary) {
    throw new Error('Could not find form boundary');
  }

  // Split the body by boundary
  const parts = body.split(`--${boundary}`);
  
  // Process the parts to extract file data
  const fileData = {};
  
  for (const part of parts) {
    if (part.includes('filename=')) {
      const filenameMatch = part.match(/filename="([^"]+)"/);
      const contentTypeMatch = part.match(/Content-Type: ([^\r\n]+)/);
      
      if (filenameMatch && contentTypeMatch) {
        const filename = filenameMatch[1];
        const contentType = contentTypeMatch[1];
        
        // Extract file content (everything after the double newline)
        const contentStart = part.indexOf('\r\n\r\n') + 4;
        const content = part.substring(contentStart).trim();
        
        fileData.filename = filename;
        fileData.contentType = contentType;
        fileData.buffer = Buffer.from(content, 'utf8');
        fileData.size = fileData.buffer.length;
      }
    }
  }

  if (!fileData.filename) {
    throw new Error('No file found in request');
  }

  return fileData;
};

/**
 * Upload handler - processes file uploads
 */
exports.handler = async (event) => {
  try {
    const userId = event.userId;
    
    if (!userId) {
      return createResponse(401, { error: 'Unauthorized' });
    }
    
    // Parse the file data from the request
    const fileData = parseMultipartData(event);
    
    // Upload the file to S3 and store metadata in DynamoDB
    const result = await uploadFile(fileData, userId);
    
    return createResponse(201, {
      message: 'File uploaded successfully',
      fileId: result.fileId,
      filename: result.filename
    });
  } catch (error) {
    console.error('Error uploading file:', error);
    
    if (error.message.includes('Content-Type') || 
        error.message.includes('boundary') || 
        error.message.includes('No file found')) {
      return createResponse(400, { error: error.message });
    }
    
    return createResponse(500, { error: 'Internal Server Error' });
  }
};
