const AWS = require('aws-sdk');

// Initialize S3 and DynamoDB clients
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Table name from environment variable
const TABLE_NAME = process.env.DYNAMODB_TABLE;
const BUCKET_NAME = process.env.S3_BUCKET;

/**
 * Generate a presigned URL for file download
 * @param {string} key - S3 object key
 * @param {number} expiresIn - URL expiration time in seconds
 * @returns {string} Presigned URL
 */
const getPresignedUrl = async (key, expiresIn = 3600) => {
  const params = {
    Bucket: BUCKET_NAME,
    Key: key,
    Expires: expiresIn
  };
  
  return s3.getSignedUrlPromise('getObject', params);
};

/**
 * Upload file to S3 and store metadata in DynamoDB
 * @param {object} fileData - File object with buffer, filename, and metadata
 * @param {string} userId - ID of the user uploading the file
 * @returns {object} Upload result with fileId
 */
const uploadFile = async (fileData, userId) => {
  const { buffer, filename, contentType, size } = fileData;
  const fileId = `${userId}/${Date.now()}-${filename}`;
  
  // Upload to S3
  const s3Params = {
    Bucket: BUCKET_NAME,
    Key: fileId,
    Body: buffer,
    ContentType: contentType
  };
  
  await s3.upload(s3Params).promise();
  
  // Store metadata in DynamoDB
  const timestamp = new Date().toISOString();
  const dbParams = {
    TableName: TABLE_NAME,
    Item: {
      userId,
      fileId,
      filename,
      contentType,
      size,
      createdAt: timestamp,
      updatedAt: timestamp
    }
  };
  
  await dynamodb.put(dbParams).promise();
  
  return { fileId, filename };
};

/**
 * List files for a user
 * @param {string} userId - User ID to list files for
 * @returns {Array} List of file metadata
 */
const listFiles = async (userId) => {
  const params = {
    TableName: TABLE_NAME,
    KeyConditionExpression: 'userId = :uid',
    ExpressionAttributeValues: {
      ':uid': userId
    }
  };
  
  const result = await dynamodb.query(params).promise();
  return result.Items;
};

/**
 * Delete a file from S3 and its metadata from DynamoDB
 * @param {string} userId - User ID
 * @param {string} fileId - File ID to delete
 * @returns {boolean} Success status
 */
const deleteFile = async (userId, fileId) => {
  // Delete from S3
  const s3Params = {
    Bucket: BUCKET_NAME,
    Key: fileId
  };
  
  await s3.deleteObject(s3Params).promise();
  
  // Delete from DynamoDB
  const dbParams = {
    TableName: TABLE_NAME,
    Key: {
      userId,
      fileId
    }
  };
  
  await dynamodb.delete(dbParams).promise();
  return true;
};

module.exports = {
  getPresignedUrl,
  uploadFile,
  listFiles,
  deleteFile
};
