/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const fs = require("fs").promises;
const path = require("path");
const process = require("process");
// const {authenticate} = require("@google-cloud/local-auth");
const {google} = require("googleapis");
const {onRequest} = require("firebase-functions/v2/https");

// If modifying these scopes, delete token.json.
const SCOPES = ["https://www.googleapis.com/auth/spreadsheets",
  "https://www.googleapis.com/auth/spreadsheets.readonly",
  "https://www.googleapis.com/auth/drive"];
// The file token.json stores the user's access and refresh tokens, and is
// created automatically when the authorization flow completes for the first
// time.
const TOKEN_PATH = path.join(process.cwd(), "token.json");
const CREDENTIALS_PATH = path.join(process.cwd(),
    "keys.json");

/**
 * Reads previously authorized credentials from the save file.
 *
 * @return {Promise<OAuth2Client|null>}
 */
async function loadSavedCredentialsIfExist() {
  try {
    const content = await fs.readFile(TOKEN_PATH);
    const credentials = JSON.parse(content);
    return google.auth.fromJSON(credentials);
  } catch (err) {
    return null;
  }
}

/**
 * Serializes credentials to a file compatible with GoogleAuth.fromJSON.
 *
 * @param {OAuth2Client} client
 * @return {Promise<void>}
 */
async function saveCredentials(client) {
  const content = await fs.readFile(CREDENTIALS_PATH);
  const keys = JSON.parse(content);
  const key = keys.installed || keys.web;
  const payload = JSON.stringify({
    type: "authorized_user",
    client_id: key.client_id,
    client_secret: key.client_secret,
    refresh_token: client.credentials.refresh_token,
  });
  await fs.writeFile(TOKEN_PATH, payload);
}

/**
 * Load or request or authorization to call APIs.
 *
 */
async function authorize() {
  let client = await loadSavedCredentialsIfExist();
  if (client) {
    return client;
  }
  client = new google.auth.GoogleAuth({
    keyFile: path.join(__dirname, "keys.json"),
    scopes: SCOPES,
  });
  if (client.credentials) {
    await saveCredentials(client);
  }
  return client;
}

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

  const backgroundColor = {red: 246.0/255,
    green: 178.0/255, blue: 107.0/255, alpha: 1.0/3};
  // appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
  //     appendValue);
  const dateNumber = ((new Date(date)).getTime() / 1000 / 86400) + 25569;
  const values = appendValue.map((e, index) => (
    {
      userEnteredValue: {
        numberValue: index === 0 ? dateNumber : undefined,
        stringValue: (index === 1 || index === 2) ? e: undefined,
      },
      userEnteredFormat: {backgroundColor,
        numberFormat: index <= 0 ?
        {type: index === 0 ? "DATE" : "TIME",
          pattern: index === 0 ? "mm/dd/yy" : "h:mm A/PM"} : undefined},
    }));
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
    "Daily Summary", "",
    "=SUM(FILTER(INDIRECT(\"G1:G\"& ROW()-1), " +
      "INDIRECT(\"A1:A\"&ROW()-1) = INDIRECT(\"A\"&ROW())))",
    "", "",
    "=SUM(FILTER(INDIRECT(\"J1:J\"& ROW()-1), " +
      "INDIRECT(\"A1:A\"&ROW()-1) = INDIRECT(\"A\"&ROW())))",
    "=SUM(FILTER(INDIRECT(\"K1:K\"& ROW()-1), " +
    "INDIRECT(\"A1:A\"&ROW()-1) = INDIRECT(\"A\"&ROW())))"];

  const backgroundColor = {red: 183.0/255,
    green: 215.0/255, blue: 168.0/255, alpha: 3.0/3};
  // appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
  //     appendValue);
  const dateNumber = ((new Date(date)).getTime() / 1000 / 86400) + 25569;
  const values = appendValue.map((e, index) => (
    {
      userEnteredValue: {
        stringValue: (index === 6 || index == 0 ||
          index === 9 || index === 10) ? undefined : e,
        formulaValue: (index === 6 || index === 9 ||
          index === 10) ? e : undefined,
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
});

exports.create_spreadsheet = onRequest(async (req, res) => {
  console.log("Creating spreadsheet...");
  const title = req.body.data.spreadsheetName;
  const email = req.body.data.email;
  const teamName = req.body.data.teamName;
  const teamID = req.body.data.teamID;
  const apiKey = req.body.data.apiKey;

  const auth = await authorize();
  const sheets = google.sheets({version: "v4", auth});

  const tableInfo = [["Team Name", "Team ID"], [teamName, teamID]];

  sheets.spreadsheets.create({
    "resource": {
      "properties": {
        "title": title,
      },
      "sheets": [{properties: {title: "Team Info"}}],
    },
  }, (err, result) => {
    if (err) {
      res.send({result: "Error"});
      throw err;
    } else {
      const spreadsheetID = result.data.spreadsheetId;
      console.log("New sheet created with ID: " + spreadsheetID);


      sheets.spreadsheets.values.append({
        spreadsheetId: spreadsheetID,
        range: "'Team Info'!A1",
        auth: auth,
        key: apiKey,
        valueInputOption: "USER_ENTERED",
        resource: {values: tableInfo},
      }, (err, result) => {
        if (err) {
          res.send({result: "Error"});
          throw err;
        } else {
          console.log("Updated sheet: " + result.data.updates.updatedRange);
        }
      });

      const permissions = {"type": "user", "role": "writer",
        "emailAddress": email};
      const resource = {
        "value": "default",
        "type": "anyone",
        "role": "writer",
      };
      const drive = google.drive({version: "v3", auth});
      drive.permissions.create({
        resource: permissions,
        fileId: spreadsheetID,
        fields: "id",
        sendNotificationEmail: true,
        supportsAllDrives: true,
      }, (err, resp) => {
        if (err) return console.log(err);
        console.log("Shared new spreadsheet with " + email);

        drive.permissions.create({
          resource: resource,
          fileId: spreadsheetID,
          fields: "id",
          supportsAllDrives: true,
        });
        res.send({result: spreadsheetID});
      });
    }
  });
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
