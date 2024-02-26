/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const {google} = require("googleapis");

const logger = require("firebase-functions/logger");

exports.append_to_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const value = req.body.data.value;
  const location = req.body.data.location;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });
  const range = "A1";

  appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
      [value, location, getCurrentDate(), getCurrentTime()]);
  // const values = request.query.values

  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Added row onto " + spreadsheetID});
});

exports.append_drive_to_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const date = req.body.data.date;
  const initialLocation = req.body.data.initialLocation;
  const finalLocation = req.body.data.finalLocation;
  const initialTime = req.body.data.initialTime;
  const finalTime = req.body.data.finalTime;
  const moneySpent = req.body.data.money;
  const ticketNumber = req.body.data.ticketNumber;
  const notes = req.body.data.notes;
  const receiptLink = req.body.data.receiptLink;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });
  const range = "A1";

  appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
      [date, ticketNumber,
        initialLocation, finalLocation,
        initialTime, finalTime,
        moneySpent, receiptLink,
        notes]);
  // const values = request.query.values

  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Added row onto " + spreadsheetID});
});

/**
 * Adds a row to the spreadsheet
 * @param {auth} auth TODO: OAUTH
 * @param {String} apiKey API Key
 * @param {String} spreadsheetID The second number.
 * @param {String} range the row and col
 * @param {Object} val the val to add
 */
function appendSpreadsheetRow(auth, apiKey, spreadsheetID, range, val) {
  const sheets = google.sheets({version: "v4", auth});
  sheets.spreadsheets.values.append({
    spreadsheetId: spreadsheetID,
    range: range,
    auth: auth,
    key: apiKey,
    valueInputOption: "RAW",
    resource: {values: [val]},
  }, (err, result) => {
    if (err) {
      throw err;
    } else {
      console.log("Updated sheet: " + result.data.updates.updatedRange);
    }
  });
}

/**
 * Gets the current date and turns it into UTC
 * @return {String} current date in ISO format
 */
function getCurrentDate() {
  const date = new Date();
  const str = date.getFullYear() + "-" +
      ("0" + (date.getMonth() + 1)).slice(-2) + "-" +
      ("0" + date.getDate()).slice(-2);
  return str;
}

/**
 * Gets the current time and turns it into UTC
 * @return {String} current time in ISO format
 */
function getCurrentTime() {
  const date = new Date();
  const str = ("0" + date.getHours() ).slice(-2) + ":" +
      ("0" + date.getMinutes()).slice(-2) + ":" +
      ("0" + date.getSeconds()).slice(-2);
  return str;
}
