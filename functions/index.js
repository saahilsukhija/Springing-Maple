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
        finalTime, type,
        ticketNumber, finalLocation,
        moneySpent, notes,
        duration, milesDriven, receiptLink]);
  // const values = request.query.values

  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Added row onto " + spreadsheetID});
});

exports.append_unreg_drive_to_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const date = req.body.data.date;
  // const initialLocation = req.body.data.initialLocation;
  const finalLocation = req.body.data.finalLocation;
  const type = req.body.data.type;
  const initialTime = req.body.data.initialTime;
  const finalTime = req.body.data.finalTime;
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

  const backgroundColor = {red: 220.0/255,
    green: 220.0/255, blue: 220.0/255, alpha: 1.0/3};

  await addBlankRow(auth, apiKey, spreadsheetID, username, backgroundColor);

  await sort(auth, apiKey, spreadsheetID, username);
  appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
      [date, initialTime,
        finalTime, type,
        "", finalLocation,
        "", "",
        duration, milesDriven, ""]);
  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});

  res.send({result: "Added unregistered onto " + spreadsheetID});
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

  const backgroundColor = {red: 246.0/255,
    green: 178.0/255, blue: 107.0/255, alpha: 1.0/3};

  await addBlankRow(auth, apiKey, spreadsheetID, username, backgroundColor);

  const range = "'" + username + "'!A1";
  await sort(auth, apiKey, spreadsheetID, username);
  appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
      [date, initialTime,
        finalTime, "BREAK",
        "", "",
        "0.00", "", "",
        "", ""]);
  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});
  logger.info("auth: " + auth.email, {structuredData: true});
  // return {result: "Hello from " + spreadsheetID};

  res.send({result: "Reset header onto " + spreadsheetID});
});

exports.append_clockinout_to_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const username = req.body.data.username;
  const date = req.body.data.date;
  const location = req.body.data.location;
  const type = req.body.data.type;
  const time = req.body.data.time;

  const auth = await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ],
  });


  const backgroundColor = type == "Clock In" ? {red: 255/255,
    green: 210/255, blue: 217/255, alpha: 3.0/3} :
    {red: 215/255,
      green: 199/255, blue: 255/255, alpha: 3.0/3};

  await addBlankRow(auth, apiKey, spreadsheetID, username, backgroundColor);

  const range = "'" + username + "'!A1";
  await sort(auth, apiKey, spreadsheetID, username);
  appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
      [date, time, time, type, "", location,
        "", "", "", "", ""]);
  await sort(auth, apiKey, spreadsheetID, username);
  logger.info("Spreadsheet ID: " + spreadsheetID, {structuredData: true});

  res.send({result: "Added " + type + " onto " + spreadsheetID});
  // return {result: "Hello from " + spreadsheetID};
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
    "", "Daily Summary",
    "", "",
    "=SUM(FILTER(INDIRECT(ADDRESS(1, COLUMN()) & \":\" & ADDRESS(ROW()-1, "+
      "COLUMN())), INDIRECT(\"A1:A\" & ROW()-1) = INDIRECT(\"A\" & ROW())))",
    "",
    "=SUM(FILTER(INDIRECT(ADDRESS(1, COLUMN()) & \":\" & ADDRESS(ROW()-1, "+
      "COLUMN())), INDIRECT(\"A1:A\" & ROW()-1) = INDIRECT(\"A\" & ROW())))",
    "=SUM(FILTER(INDIRECT(ADDRESS(1, COLUMN()) & \":\" & ADDRESS(ROW()-1, "+
    "COLUMN())), INDIRECT(\"A1:A\" & ROW()-1) = INDIRECT(\"A\" & ROW())))",
    ""];

  const backgroundColor = {red: 183.0/255,
    green: 215.0/255, blue: 168.0/255, alpha: 3.0/3};
  // appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
  //     appendValue);
  const dateNumber = ((new Date(date)).getTime() / 1000 / 86400) + 25569;
  const values = appendValue.map((e, index) => (
    {
      userEnteredValue: {
        stringValue: (index === 6 || index == 0 ||
          index === 8 || index === 9) ? undefined : e,
        formulaValue: (index === 6 || index === 8 ||
          index === 9) ? e : undefined,
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
  res.send({result: "Added daily summary onto " + spreadsheetID});
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
      "sheets": [{properties: {title: "Team Info"}},
        {properties: {title: "Property List"}}],
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

exports.get_property_list = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;

  const auth = await authorize();
  const sheets = google.sheets({version: "v4", auth});

  const range = "Properties!A2:B";
  const result = await sheets.spreadsheets.values.get({
    auth: auth,
    spreadsheetId: spreadsheetID,
    key: apiKey,
    range: range,
  });

  const values = result.data.values;
  const pairs = [];
  for (let i = 0; i < values.length; i += 2) {
    pairs.push([values[i], values[i+1]]);
  }
  console.log("Property values: " + pairs);
  res.send({result: result});
});

exports.delete_item_from_spreadsheet = onRequest(async (req, res) => {
  const spreadsheetID = req.body.data.spreadsheetID;
  const apiKey = req.body.data.apiKey;
  const date = req.body.data.date;
  // const finalLocation = req.body.data.finalLocation;
  // const type = req.body.data.type;
  const initialTime = req.body.data.initialTime;
  const finalTime = req.body.data.finalTime;
  const username = req.body.data.username;
  // const duration = req.body.data.duration;

  const auth = await authorize();
  // const numCols = 11;
  const rows = await getAllCells(auth, apiKey, spreadsheetID, username);


  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (row[0] == date && row[1] == initialTime && row[2] == finalTime) {
      console.log("Found match at row " + (i+1));
      await deleteRow(auth, apiKey, spreadsheetID, username, i);
      res.send({result: "Deleted row at " + (i+1)});
    }
  }


  // console.log("length: " + r.length);
  console.log("Cell values: " + rows);
  res.send({result: "Failed to find any matching row"});
});

/**
 * Returns an array of all values in a given spreadsheet
 * @param {auth} auth TODO: OAUTH
 * @param {String} apiKey API Key
 * @param {String} spreadsheetID The second number.
 * @param {String} name the name of sheet
 */
async function getAllCells(auth, apiKey, spreadsheetID, name) {
  const sheets = google.sheets({version: "v4", auth});
  const range = "'" + name + "'!A1:K";
  const result = await sheets.spreadsheets.values.get({
    auth: auth,
    spreadsheetId: spreadsheetID,
    key: apiKey,
    range: range,
  });

  const values = result.data.values;


  return values;
}


/**
 * Deletes a row from the spreadsheet
 * @param {*} auth TODO: OAUTH
 * @param {*} apiKey the apiKey
 * @param {*} spreadsheetID the id of ENTIRE spreadsheet
 * @param {*} username name of user
 * @param {*} row the row to delete
 */
async function deleteRow(auth, apiKey, spreadsheetID, username, row) {
  const sheets = google.sheets({version: "v4", auth});
  const sheetId = await getSheetID(auth, spreadsheetID, username);
  sheets.spreadsheets.batchUpdate(
      {
        auth: auth,
        spreadsheetId: spreadsheetID,
        key: apiKey,
        resource: {
          "requests": [
            {
              "deleteDimension": {
                "range": {
                  "sheetId": sheetId,
                  "dimension": "ROWS",
                  "startIndex": row,
                  "endIndex": row+1,
                },
              },
            },
          ],
        },
      },
  );
}

/**
 * Adds a blank row with a given color to the spreadsheet
 * @param {*} auth TODO: OAUTH
 * @param {*} apiKey the apiKey
 * @param {*} spreadsheetID the id of ENTIRE spreadsheet
 * @param {*} username name of user
 * @param {*} color the color to make the row
 */
async function addBlankRow(auth, apiKey, spreadsheetID, username, color) {
  const appendValue = ["", "",
    "", "",
    "", "",
    "", "", "", "", ""];

  const backgroundColor = color;
  // appendSpreadsheetRow(auth, apiKey, spreadsheetID, range,
  //     appendValue);

  const values = appendValue.map((e, index) => (
    {
      userEnteredValue: {
        numberValue: undefined,
        stringValue: undefined,
      },
      userEnteredFormat: {backgroundColor,
        numberFormat: undefined},
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
}

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
      "Type", "Appfolio Ticket Number", "Location",
      "Expense Amount", "Description",
      "Duration", "Miles Driven", "Receipt Link"]]},
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

  sheets.spreadsheets.values.update({
    spreadsheetId: spreadsheetID,
    range: "Properties!A1",
    auth: auth,
    key: apiKey,
    valueInputOption: "RAW",
    resource: {values: [["Original Property Address", "Custom Name"]]},
  }, (err, result) => {
    if (err) {
      throw err;
    } else {
      console.log("Updated sheet: " + result.data.updates.updatedRange);
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
