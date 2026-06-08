/**
 * ============================================================
 *  Google Apps Script — نظام إدارة العمال + RBAC + Offline Sync
 * ============================================================
 */

const EMPLOYEES_SHEET      = 'employees';
const ABSENCES_SHEET       = 'absences';
const USERS_SHEET          = 'users';
const NOTIFICATIONS_SHEET  = 'notifications';
const CONFIG_SHEET         = 'config';

// ══════════════════════════════════════════════════════════════
//  ENTRY POINTS
// ══════════════════════════════════════════════════════════════

function doGet(e) {
  const action = e && e.parameter && e.parameter.action;

  if (action === 'ping') {
    return jsonResponse({ status: 'ok', ts: new Date().toISOString() });
  }
  if (action === 'get_config_last_modified') {
    return jsonResponse({ lastModified: getConfigLastModified() });
  }
  if (action === 'get_users') {
    return jsonResponse(getUsers());
  }
  if (action === 'get_notifications') {
    const since = parseInt(e.parameter.since || '0', 10);
    return jsonResponse(getNotifications(since));
  }
  if (action === 'get_absences') {
    return jsonResponse(getAllRecords(ABSENCES_SHEET));
  }

  // Default: return all employees
  return jsonResponse(getAllRecords(EMPLOYEES_SHEET));
}

function doPost(e) {
  let payload;
  try {
    payload = JSON.parse(e.postData.contents);
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON' });
  }

  const action = payload.action;

  try {
    switch (action) {
      // ── Employees ──
      case 'add_employee':    return jsonResponse(createRecord(EMPLOYEES_SHEET, payload.data));
      case 'update_employee': return jsonResponse(updateRecord(EMPLOYEES_SHEET, payload.id || payload.data.reg, payload.data, 'reg'));
      case 'delete_employee': return jsonResponse(softDeleteRecord(EMPLOYEES_SHEET, payload.id || payload.reg, 'reg'));

      // ── Absences ──
      case 'add_absence':     return jsonResponse(createRecord(ABSENCES_SHEET, payload.data));
      case 'update_absence':  return jsonResponse(updateRecord(ABSENCES_SHEET, payload.id, payload.data, 'id'));
      case 'delete_absence':  return jsonResponse(softDeleteRecord(ABSENCES_SHEET, payload.id, 'id'));

      // ── Users ──
      case 'add_user':        return jsonResponse(addUser(payload.data));
      case 'update_user':     return jsonResponse(updateUser(payload.data));
      case 'delete_user':     return jsonResponse(deleteUser(payload.reg || payload.username));

      // ── Notifications ──
      case 'add_notification': return jsonResponse(addNotification(payload.data));

      default:
        return jsonResponse({ error: 'Unknown action: ' + action });
    }
  } catch (err) {
    return jsonResponse({ error: err.toString() });
  }
}

// ══════════════════════════════════════════════════════════════
//  CONFIG & SYNC HELPER
// ══════════════════════════════════════════════════════════════

function getOrCreateConfigSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(CONFIG_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(CONFIG_SHEET);
    sheet.getRange(1, 1, 2, 2).setValues([
      ['key', 'value'],
      ['lastModified', new Date().toISOString()]
    ]);
    sheet.getRange('A1:B1').setBackground('#1e3a5f').setFontColor('#ffffff').setFontWeight('bold');
  }
  return sheet;
}

function getConfigLastModified() {
  const sheet = getOrCreateConfigSheet();
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === 'lastModified') {
      return data[i][1];
    }
  }
  return null;
}

function bumpLastModified() {
  const sheet = getOrCreateConfigSheet();
  const data = sheet.getDataRange().getValues();
  const now = new Date().toISOString();
  let found = false;
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === 'lastModified') {
      sheet.getRange(i + 1, 2).setValue(now);
      found = true;
      break;
    }
  }
  if (!found) {
    sheet.appendRow(['lastModified', now]);
  }
}

// ══════════════════════════════════════════════════════════════
//  GENERIC CRUD (EMPLOYEES & ABSENCES)
// ══════════════════════════════════════════════════════════════

function getAllRecords(sheetName) {
  const sheet = getOrCreateSheet(sheetName);
  if (sheet.getLastRow() <= 1) return [];

  const headers = getHeaders(sheet);
  const displayData = sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn()).getDisplayValues();

  return displayData.map(row => {
    const obj = {};
    headers.forEach((h, i) => obj[h] = row[i]);
    return obj;
  });
}

function createRecord(sheetName, data) {
  const sheet = getOrCreateSheet(sheetName);
  let headers = getHeaders(sheet);

  const now = new Date().toISOString();
  if (sheetName === ABSENCES_SHEET && !data.id) {
     data.id = Utilities.getUuid();
  }
  data.version = 1;
  data.updatedAt = now;
  data.deletedAt = '';

  const newHeaders = Object.keys(data).filter(k => !headers.includes(k));
  if (newHeaders.length > 0) {
    if (headers.length === 0 || (headers.length === 1 && headers[0] === "")) {
       sheet.getRange(1, 1, 1, newHeaders.length).setValues([newHeaders]);
       headers = newHeaders;
    } else {
       sheet.getRange(1, headers.length + 1, 1, newHeaders.length).setValues([newHeaders]);
       headers = headers.concat(newHeaders);
    }
    sheet.getRange(1, 1, 1, headers.length).setBackground('#1e3a5f').setFontColor('#ffffff').setFontWeight('bold');
  }

  const row = headers.map(h => (data[h] !== undefined ? String(data[h]) : ''));
  const nextRow = sheet.getLastRow() + 1;

  ensureTextColumns(sheet, headers);
  sheet.getRange(nextRow, 1, 1, headers.length).setValues([row]);

  bumpLastModified();
  return { success: true, data: data, id: data.id || data.reg };
}

function updateRecord(sheetName, id, data, idField = 'id') {
  const sheet = getOrCreateSheet(sheetName);
  const sheetData = sheet.getDataRange().getValues();
  if (sheetData.length <= 1) return { success: false, error: 'Empty sheet' };

  let headers = sheetData[0];
  const idColIdx = headers.indexOf(idField);
  if (idColIdx === -1) return { success: false, error: 'ID column not found' };

  for (let i = 1; i < sheetData.length; i++) {
    if (String(sheetData[i][idColIdx]) === String(id)) {
      data.version = parseInt(sheetData[i][headers.indexOf('version')] || 0) + 1;
      data.updatedAt = new Date().toISOString();
      
      const newHeaders = Object.keys(data).filter(k => !headers.includes(k));
      if (newHeaders.length > 0) {
         sheet.getRange(1, headers.length + 1, 1, newHeaders.length).setValues([newHeaders]);
         headers = headers.concat(newHeaders);
         sheet.getRange(1, 1, 1, headers.length).setBackground('#1e3a5f').setFontColor('#ffffff').setFontWeight('bold');
      }

      const currentRow = sheet.getRange(i + 1, 1, 1, headers.length).getValues()[0];
      const newRow = headers.map((h, idx) => {
        if (data[h] !== undefined) return String(data[h]);
        return currentRow[idx] !== undefined ? String(currentRow[idx]) : '';
      });

      ensureTextColumns(sheet, headers);
      sheet.getRange(i + 1, 1, 1, headers.length).setValues([newRow]);
      
      bumpLastModified();
      return { success: true };
    }
  }
  return { success: false, error: 'Record not found' };
}

function softDeleteRecord(sheetName, id, idField = 'id') {
  const sheet = getOrCreateSheet(sheetName);
  const sheetData = sheet.getDataRange().getValues();
  if (sheetData.length <= 1) return { success: false, error: 'Empty sheet' };

  const headers = sheetData[0];
  const idColIdx = headers.indexOf(idField);
  
  if (idColIdx === -1) return { success: false, error: 'ID column not found' };

  for (let i = 1; i < sheetData.length; i++) {
    if (String(sheetData[i][idColIdx]) === String(id)) {
      const now = new Date().toISOString();
      return updateRecord(sheetName, id, { deletedAt: now }, idField);
    }
  }
  return { success: false, error: 'Record not found' };
}

// ══════════════════════════════════════════════════════════════
//  USERS
// ══════════════════════════════════════════════════════════════

const USER_HEADERS = ['username', 'passwordHash', 'role', 'fullName', 'createdAt'];

function getUsers() {
  const sheet = getOrCreateUsersSheet();
  const data  = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  return data.slice(1).map(row => ({
    username:     String(row[0]),
    passwordHash: String(row[1]),
    role:         String(row[2]),
    fullName:     String(row[3]),
    createdAt:    String(row[4]),
  }));
}

function addUser(data) {
  const sheet = getOrCreateUsersSheet();
  const users = getUsers();
  if (users.some(u => u.username.toLowerCase() === String(data.username).toLowerCase())) {
    return { success: false, error: 'Username already exists' };
  }
  sheet.appendRow([
    data.username    || '',
    data.passwordHash || '',
    data.role        || 'user',
    data.fullName    || '',
    data.createdAt   || Date.now(),
  ]);
  return { success: true };
}

function updateUser(data) {
  const sheet    = getOrCreateUsersSheet();
  const sheetData = sheet.getDataRange().getValues();
  for (let i = 1; i < sheetData.length; i++) {
    if (String(sheetData[i][0]).toLowerCase() === String(data.username).toLowerCase()) {
      sheet.getRange(i + 1, 1, 1, 5).setValues([[
        data.username    || sheetData[i][0],
        data.passwordHash || sheetData[i][1],
        data.role        || sheetData[i][2],
        data.fullName    || sheetData[i][3],
        data.createdAt   || sheetData[i][4],
      ]]);
      return { success: true };
    }
  }
  return { success: false, error: 'User not found' };
}

function deleteUser(username) {
  const sheet = getOrCreateUsersSheet();
  const data  = sheet.getDataRange().getValues();
  for (let i = data.length - 1; i >= 1; i--) {
    if (String(data[i][0]).toLowerCase() === String(username).toLowerCase()) {
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }
  return { success: false, error: 'User not found' };
}

// ══════════════════════════════════════════════════════════════
//  NOTIFICATIONS
// ══════════════════════════════════════════════════════════════

const NOTIF_HEADERS = ['id', 'type', 'title', 'message', 'author', 'timestamp'];
const MAX_NOTIFICATIONS = 200;

function getOrCreateNotificationsSheet() {
  const ss    = SpreadsheetApp.getActiveSpreadsheet();
  let sheet   = ss.getSheetByName(NOTIFICATIONS_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(NOTIFICATIONS_SHEET);
    sheet.getRange(1, 1, 1, NOTIF_HEADERS.length).setValues([NOTIF_HEADERS]);
    sheet.getRange(1, 1, 1, NOTIF_HEADERS.length).setBackground('#1e3a5f').setFontColor('#ffffff').setFontWeight('bold');
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function addNotification(data) {
  const sheet = getOrCreateNotificationsSheet();
  const row = [
    data.id        || String(Date.now()),
    data.type      || 'info',
    data.title     || '',
    data.message   || '',
    data.author    || '',
    data.timestamp || Date.now(),
  ];
  sheet.appendRow(row);
  const lastRow = sheet.getLastRow();
  if (lastRow > MAX_NOTIFICATIONS + 1) {
    sheet.deleteRows(2, lastRow - MAX_NOTIFICATIONS - 1);
  }
  bumpLastModified();
  return { success: true };
}

function getNotifications(since) {
  const sheet = getOrCreateNotificationsSheet();
  const lastRow = sheet.getLastRow();
  if (lastRow <= 1) return [];

  const data = sheet.getRange(2, 1, lastRow - 1, NOTIF_HEADERS.length).getValues();
  const result = [];
  for (const row of data) {
    const ts = parseInt(String(row[5]), 10);
    if (ts > since) {
      result.push({
        id:        String(row[0]),
        type:      String(row[1]),
        title:     String(row[2]),
        message:   String(row[3]),
        author:    String(row[4]),
        timestamp: ts,
      });
    }
  }
  return result;
}

// ══════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════

function getOrCreateSheet(name) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(name) || ss.insertSheet(name);
}

function getOrCreateUsersSheet() {
  const ss    = SpreadsheetApp.getActiveSpreadsheet();
  let sheet   = ss.getSheetByName(USERS_SHEET);
  if (!sheet) {
    sheet = ss.insertSheet(USERS_SHEET);
    sheet.getRange(1, 1, 1, USER_HEADERS.length).setValues([USER_HEADERS]);
    sheet.getRange(1, 1, 1, USER_HEADERS.length).setBackground('#1e3a5f').setFontColor('#ffffff').setFontWeight('bold');
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function getHeaders(sheet) {
  return sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
}

function ensureTextColumns(sheet, headers) {
  ['reg', 'phone'].forEach(col => {
    const idx = headers.indexOf(col);
    if (idx >= 0 && sheet.getLastRow() > 1) {
      sheet.getRange(2, idx + 1, sheet.getLastRow() - 1, 1).setNumberFormat('@');
    }
  });
}

function jsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function migrateAbsenceTypeIfNeeded() {
  const sheet = getOrCreateConfigSheet();
  const data = sheet.getDataRange().getValues();
  let done = false;
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === 'migrationV2Done' && data[i][1] === 'true') {
      done = true;
      break;
    }
  }
  
  if (!done) {
    const absSheet = getOrCreateSheet(ABSENCES_SHEET);
    if (absSheet.getLastRow() > 1) {
      const absData = absSheet.getDataRange().getValues();
      const typeIdx = absData[0].indexOf('type');
      if (typeIdx !== -1) {
        for (let i = 1; i < absData.length; i++) {
           if (absData[i][typeIdx] === 'غ غ ش') {
              absSheet.getRange(i + 1, typeIdx + 1).setValue('غ غ ش');
           }
        }
      }
    }
    
    // Add flag
    sheet.appendRow(['migrationV2Done', 'true']);
    bumpLastModified();
  }
  return jsonResponse({ success: true, message: 'Migration executed if needed' });
}
