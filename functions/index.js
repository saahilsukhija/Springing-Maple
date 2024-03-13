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
  // const initialLocation = req.body.data.initialLocation;
  const finalLocation = req.body.data.finalLocation;
  const type = req.body.data.type;
  const initialTime = req.body.data.initialTime;
  const finalTime = req.body.data.finalTime;
  const moneySpent = parseFloat(req.body.data.money);
  const ticketNumber = req.body.data.ticketNumber;
  const notes = req.body.data.notes;
  const receiptLink = req.body.data.receiptLink;
  const username = req.body.data.username;
  const duration = req.body.data.duration;
  const milesDriven = Math.round(parseFloat(req.body.data.milesDriven)*100)/100;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });
  const range = "'" + username + "'!A1";

  addNewSheet(auth, apiKey, spreadsheetID, username);
  appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
      [date, initialTime,
        finalTime, ticketNumber,
        type, finalLocation,
        moneySpent, receiptLink, notes,
        duration, milesDriven]);
  // const values = request.query.values

  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Added row onto " + spreadsheetID});
});

exports.create_new_sheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const username = req.body.data.username;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });

  addNewSheet(auth, apiKey, spreadsheetID, username);

  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Added sheet onto " + spreadsheetID});
});

exports.reset_header = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const username = req.body.data.username;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });

  resetHeader(auth, apiKey, spreadsheetID, username);

  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Reset header onto " + spreadsheetID});
});

exports.append_break_to_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const username = req.body.data.username;
  const date = req.body.data.date;
  const initialTime = req.body.data.initialTime;
  const finalTime = req.body.data.finalTime;
  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });

  const appendValue = [date, initialTime,
    finalTime, "",
    "Break", "",
    "0.00", "", "", "", ""];

  const backgroundColor = {red: 1, green: 165.0/255, blue: 0, alpha: 1.0/3};
  // appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
  //     appendValue);
  const values = appendValue.map((e) => ({userEnteredValue: {stringValue: e},
    userEnteredFormat: {backgroundColor}}));
  const sheetId = await getSheetID(auth, spreadsheetID, username);

  const sheets = google.sheets({version: "v4", auth});
  sheets.spreadsheets.batchUpdate(
      {
        auth: auth,
        spreadsheetId: spreadsheetID,
        key: apiKey,
        resource: {
          requests: [
            {
              "appendCells": {
                "rows": [{values}],
                "sheetId": sheetId,
                "fields": "userEnteredValue,userEnteredFormat",
              },
            },
          ],
        },
      },
  );

  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Reset header onto " + spreadsheetID});
});

exports.append_dailysummary_to_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const username = req.body.data.username;
  const date = req.body.data.date;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });

  const appendValue = [date, "",
    "", "",
    "", "",
    "=SUM(FILTER(INDIRECT(\"G1:G\"& ROW()-1), " +
      "INDIRECT(\"A1:A\"&ROW()-1) = INDIRECT(\"A\"&ROW())))",
    "", "", "", ""];

  const backgroundColor = {red: 0, green: 165.0/255, blue: 0, alpha: 1.0/3};
  // appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
  //     appendValue);
  const dateNumber = ((new Date(date)).getTime() / 1000 / 86400) + 25569;
  const values = appendValue.map((e, index) => (
    {
      userEnteredValue: {
        stringValue: (index === 6 || index == 0) ? undefined : e,
        formulaValue: index === 6 ? e : undefined,
        numberValue: index === 0 ? dateNumber : undefined},
      userEnteredFormat: {backgroundColor,
        numberFormat: index <= 2 ?
        {type: index === 0 ? "DATE" : "TIME",
          pattern: index === 0 ? "mm/dd/yy" : "h:mm A/PM"} : undefined},
    }));
  logger.info("Values: " + JSON.stringify(values), {structuredData: true});
  const sheetId = await getSheetID(auth, spreadsheetID, username);

  const sheets = google.sheets({version: "v4", auth});
  sheets.spreadsheets.batchUpdate(
      {
        auth: auth,
        spreadsheetId: spreadsheetID,
        key: apiKey,
        resource: {
          requests: [
            {
              "appendCells": {
                "rows": [{values}],
                "sheetId": sheetId,
                "fields": "userEnteredValue,userEnteredFormat"
                ,
              },
            },
          ],
        },
      },
  );

  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Added summary onto " + spreadsheetID});
});

/**
 * Adds a new sheet
 * @param {auth} auth TODO: OAUTH
 * @param {String} apiKey API Key
 * @param {String} spreadsheetID The second number.
 * @param {String} name the name of sheet
 */
function addNewSheet(auth, apiKey, spreadsheetID, name) {
  const sheets = google.sheets({version: "v4", auth});
  sheets.spreadsheets.batchUpdate(
      {
        auth: auth,
        spreadsheetId: spreadsheetID,
        key: apiKey,
        resource: {
          requests: [
            {
              "addSheet": {
                "properties": {
                  "title": name,
                },
              },
            },
          ],
        },
      },
  );
}

/**
 * Resets the header to a sheet
 * @param {auth} auth TODO: OAUTH
 * @param {String} apiKey API Key
 * @param {String} spreadsheetID The second number.
 * @param {String} name the name of sheet
 */
function resetHeader(auth, apiKey, spreadsheetID, name) {
  const sheets = google.sheets({version: "v4", auth});
  sheets.spreadsheets.values.update({
    spreadsheetId: spreadsheetID,
    range: "'" + name + "'!A1",
    auth: auth,
    key: apiKey,
    valueInputOption: "RAW",
    resource: {values: [["Date", "Start", "Finish",
      "Appfolio Ticket Number", "Type", "Location",
      "Expense Amount", "Receipt Link", "Description",
      "Duration", "Miles Driven"]]},
  }, (err, result) => {
    if (err) {
      throw err;
    } else {
      console.log("Updated sheet: " + result.data.updates.updatedRange);

      sheets.spreadsheets.batchUpdate(
          {
            valueInputOption: "USER_ENTERED",
            auth: auth,
            spreadsheetId: spreadsheetID,
            key: apiKey,
            resource: {
              requests: [
                {
                  "repeatCell": {
                    "range": {
                      "sheetId": spreadsheetID,
                      "startColumnIndex": 0,
                      "endColumnIndex": 7,
                    },
                    "cell": {
                      "userEnteredFormat": {
                        "numberFormat": {
                          "type": "CURRENCY",
                        },
                      },
                    },
                    "fields": "userEnteredFormat",
                  },
                },
              ],
            },
          },
      );

      sheets.spreadsheets.batchUpdate(
          {
            valueInputOption: "USER_ENTERED",
            auth: auth,
            spreadsheetId: spreadsheetID,
            key: apiKey,
            resource: {
              requests: [
                {
                  "repeatCell": {
                    "range": {
                      "sheetId": spreadsheetID,
                      "startColumnIndex": 8,
                      "endColumnIndex": 10,
                    },
                    "cell": {
                      "userEnteredFormat": {
                        "numberFormat": {
                          "type": "DATE_TIME",
                          "pattern": "[h]:mm",
                        },
                      },
                    },
                    "fields": "userEnteredFormat",
                  },
                },
              ],
            },
          },
      );

      sheets.spreadsheets.batchUpdate(
          {
            valueInputOption: "USER_ENTERED",
            auth: auth,
            spreadsheetId: spreadsheetID,
            key: apiKey,
            resource: {
              requests: [
                {
                  "repeatCell": {
                    "range": {
                      "sheetId": spreadsheetID,
                      "startColumnIndex": 0,
                      "endColumnIndex": 1,
                    },
                    "cell": {
                      "userEnteredFormat": {
                        "numberFormat": {
                          "type": "DATE",
                          "pattern": "mm/dd/yy",
                        },
                      },
                    },
                    "fields": "userEnteredFormat",
                  },
                },
              ],
            },
          },
      );

      sheets.spreadsheets.batchUpdate(
          {
            valueInputOption: "USER_ENTERED",
            auth: auth,
            spreadsheetId: spreadsheetID,
            key: apiKey,
            resource: {
              requests: [
                {
                  "repeatCell": {
                    "range": {
                      "sheetId": spreadsheetID,
                      "startColumnIndex": 1,
                      "endColumnIndex": 3,
                    },
                    "cell": {
                      "userEnteredFormat": {
                        "numberFormat": {
                          "type": "TIME",
                          "pattern": "h:mm A/PM",
                        },
                      },
                    },
                    "fields": "userEnteredFormat",
                  },
                },
              ],
            },
          },
      );
    }
  });
}

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
    valueInputOption: "USER_ENTERED",
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

/**
 * Gets the sheetID for the specified sheet
 * @param {auth} auth TODO: OAUTH
 * @param {String} spreadsheetID The second number.
 * @param {String} username the name of the sheet
 */
async function getSheetID(auth, spreadsheetID, username) {
  const sheets = google.sheets({version: "v4", auth});
  const result = (await sheets.spreadsheets.get({
    spreadsheetId: spreadsheetID,
  })).data.sheets;
  for (let i = 0; i < result.length; i++) {
    if (result[i].properties.title == username) {
      return result[i].properties.sheetId;
    }
  }
  return "Sheet1";
}

/**
 * Sorts all entries by ascending order by date.
 * @param {*} auth TODO: OAUTH
 * @param {*} apiKey the apiKey
 * @param {*} spreadsheetID the id of ENTIRE spreadsheet
 * @param {*} username name of user
 */
async function sort(auth, apiKey, spreadsheetID, username) {
  const sheets = google.sheets({version: "v4", auth});
  const sheetId = await getSheetID(auth, spreadsheetID, username);
  sheets.spreadsheets.batchUpdate(
      {
        auth: auth,
        spreadsheetId: spreadsheetID,
        key: apiKey,
        resource: {
          requests: [
            {
              "sortRange": {
                "range": {
                  "sheetId": sheetId,
                  "startColumnIndex": 0,
                  "startRowIndex": 1,
                },
                "sortSpecs": [
                  {
                    "dimensionIndex": 0,
                    "sortOrder": "ASCENDING",
                  },
                  {
                    "dimensionIndex": 1,
                    "sortOrder": "ASCENDING",
                  },
                  {
                    "dimensionIndex": 2,
                    "sortOrder": "ASCENDING",
                  },
                ],
              },
            },
          ],
        },
      },
  );
}
