const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const { randomBytes } = require('crypto');
const { passport } = require('./auth.js');
const requireHttps = require('./require-https.js');
const {
  validate, GreetingSchema,
} = require('./validation.js');
const {  dynamodbClient } = require('./db');
const { errorHandler, asyncMiddleware } = require('./error-handler.js');
const logger = require('./logger.js');

const apiBaseUrl = '/api/v1';
const app = express();

//app.use(requireHttps);
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '../client/build')));

// Remove empty strings (DynamoDB doesn't accept)
const scrubObject = (obj) => {
  const scrubbed = obj;
  Object.keys(scrubbed).forEach((key) => {
    if (typeof scrubbed[key] === 'object' && scrubbed[key] !== null) {
      scrubbed[key] = scrubObject(scrubbed[key]); // Nested object
    } else if (scrubbed[key] === '') {
      scrubbed[key] = null; // Null instead of empty for DynamoDB
    }
  });
  return scrubbed;
};

const generateUniqueHexId = async (collection) => {
  const randomHexId = randomBytes(4).toString('hex').toUpperCase();
  if (await collection.countDocuments({ id: randomHexId }, { limit: 1 }) > 0) {
    return generateUniqueHexId(collection); // Ensure ID is unique
  }
  return randomHexId;
};

// Choose and save greeting
app.post(`${apiBaseUrl}/greeting`,
  asyncMiddleware(async (req, res) => {
    
    logger.info('Saving to db: ' + JSON.stringify(req.body));

    const greeting = req.body["greeting"];
    const result = await dynamodbClient.addGreeting(greeting);
    const id = result.id;

    
    return res.json({ id, greeting});
  }));


// Get existing greeting
app.get(`${apiBaseUrl}/greeting/:latest`,
  asyncMiddleware(async (req, res) => {
    
    const greetingItems = await dynamodbClient.getGreetings();
    
    logger.info('Reading from db: ' + JSON.stringify(greetingItems));

    return res.json({greetingItems});
  }));

// Client app
if (process.env.NODE_ENV === 'production') {
  app.get('/*', (req, res) => res.sendFile(path.join(__dirname, '../client/build/index.html')));
}

app.use(errorHandler);

module.exports = app;
