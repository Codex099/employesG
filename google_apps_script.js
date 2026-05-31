/**
 * ============================================================
 *  Google Apps Script — نظام إدارة العمال + RBAC
 *  Feuilles requises :
 *    1. "employees"  — données des employés (existante)
 *    2. "users"      — comptes utilisateurs (NOUVELLE)
 *
 *  Colonnes de la feuille "users" :
 *    A: username | B: passwordHash | C: role | D: fullName | E: createdAt
 * ============================================================
 */

const EMPLOYEES_SHEET      = 'employees';
const USERS_SHEET          = 'users';
const NOTIFICATIONS_SHEET  = 'notifications';

// ══════════════════════════════════════════════════════════════
//  ENTRY POINTS
// ══════════════════════════════════════════════════════════════

function doGet(e) {
  const action = e && e.parameter && e.parameter.action;

  if (action === 'get_users') {
    return jsonResponse(getUsers());
  }

  if (action === 'get_notifications') {
    const since = parseInt(e.parameter.since || '0', 10);
    return jsonResponse(getNotifications(since));
  }

  // Default: return all employees
  return jsonResponse(getAllEmployees());
}

function doPost(e) {
  let payload;
  try {
    payload = JSON.parse(e.postData.contents);
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON' });
  }

  const action = payload.action;

  switch (action) {
    // ── Employees ──
    case 'add':       return jsonResponse(addEmployee(payload.data));
    case 'delete':    return jsonResponse(deleteEmployee(payload.reg));
    case 'sync_all':  return jsonResponse(syncAll(payload.data));

    // ── Users ──
    case 'add_user':    return jsonResponse(addUser(payload.data));
    case 'update_user': return jsonResponse(updateUser(payload.data));
    case 'delete_user': return jsonResponse(deleteUser(payload.reg));

    // ── Notifications ──
    case 'add_notification': return jsonResponse(addNotification(payload.data));

    default:
      return jsonResponse({ error: 'Unknown action: ' + action });
  }
}

// ══════════════════════════════════════════════════════════════
//  EMPLOYEES
// ══════════════════════════════════════════════════════════════

function getAllEmployees() {
  const sheet = getOrCreateSheet(EMPLOYEES_SHEET);
  if (sheet.getLastRow() <= 1) return [];

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  // getDisplayValues() returns the formatted string — preserves leading zeros for text cells
  const displayData = sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn()).getDisplayValues();

  return displayData.map(row => {
    const obj = {};
    headers.forEach((h, i) => obj[h] = row[i]);
    return obj;
  });
}

function addEmployee(data) {
  const sheet   = getOrCreateSheet(EMPLOYEES_SHEET);
  let headers = getHeaders(sheet);

  // Auto-expand headers if data contains new keys
  const newHeaders = Object.keys(data).filter(k => !headers.includes(k));
  if (newHeaders.length > 0) {
    if (headers.length === 0 || (headers.length === 1 && headers[0] === "")) {
       sheet.getRange(1, 1, 1, newHeaders.length).setValues([newHeaders]);
       headers = newHeaders;
    } else {
       sheet.getRange(1, headers.length + 1, 1, newHeaders.length).setValues([newHeaders]);
       headers = headers.concat(newHeaders);
    }
    // Make headers bold
    sheet.getRange(1, 1, 1, headers.length).setBackground('#1e3a5f').setFontColor('#ffffff').setFontWeight('bold');
  }

  // Force String() on every value so "0123" is NEVER auto-converted to 123
  const row = headers.map(h => (data[h] !== undefined ? String(data[h]) : ''));

  const nextRow = sheet.getLastRow() + 1;

  // Pre-format reg & phone columns as Plain Text
  ['reg', 'phone'].forEach(col => {
    const idx = headers.indexOf(col);
    if (idx >= 0) {
      sheet.getRange(nextRow, idx + 1).setNumberFormat('@');
    }
  });

  // Use setValues instead of appendRow — appendRow auto-converts "0123" → 123
  // even when the column is pre-formatted as Plain Text.
  sheet.getRange(nextRow, 1, 1, headers.length).setValues([row]);

  return { success: true };
}

function deleteEmployee(reg) {
  const sheet = getOrCreateSheet(EMPLOYEES_SHEET);
  const data  = sheet.getDataRange().getValues();
  const headers = data[0];
  const regIdx  = headers.indexOf('reg');

  for (let i = data.length - 1; i >= 1; i--) {
    if (String(data[i][regIdx]) === String(reg)) {
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }
  return { success: false, error: 'Employee not found' };
}

function syncAll(employees) {
  const sheet   = getOrCreateSheet(EMPLOYEES_SHEET);
  let headers = getHeaders(sheet);

  // Auto-expand headers if data contains new keys
  const newHeadersSet = new Set();
  employees.forEach(emp => Object.keys(emp).forEach(k => {
    if (!headers.includes(k)) newHeadersSet.add(k);
  }));
  const newHeaders = Array.from(newHeadersSet);
  
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

  // Clear all rows except header
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.deleteRows(2, lastRow - 1);
  }

  // Re-insert all employees
  // Force String() to protect leading zeros ("0123" must not become 123)
  const rows = employees.map(emp => headers.map(h => (emp[h] !== undefined ? String(emp[h]) : '')));
  if (rows.length > 0) {
    // Format reg & phone columns as Plain Text BEFORE setValues
    // so "0123" is not auto-converted to the number 123
    ['reg', 'phone'].forEach(col => {
      const idx = headers.indexOf(col);
      if (idx >= 0) {
        sheet.getRange(2, idx + 1, rows.length, 1).setNumberFormat('@');
      }
    });
    sheet.getRange(2, 1, rows.length, headers.length).setValues(rows);
  }
  return { success: true };
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

  // Check for duplicate username
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
const MAX_NOTIFICATIONS = 200; // Keep only last 200 rows to avoid sheet bloat

function getOrCreateNotificationsSheet() {
  const ss    = SpreadsheetApp.getActiveSpreadsheet();
  let sheet   = ss.getSheetByName(NOTIFICATIONS_SHEET);

  if (!sheet) {
    sheet = ss.insertSheet(NOTIFICATIONS_SHEET);
    sheet.getRange(1, 1, 1, NOTIF_HEADERS.length).setValues([NOTIF_HEADERS]);
    sheet.getRange(1, 1, 1, NOTIF_HEADERS.length)
      .setBackground('#1e3a5f')
      .setFontColor('#ffffff')
      .setFontWeight('bold');
    sheet.setFrozenRows(1);
  }
  return sheet;
}

/**
 * Adds a notification row.
 * data: { id, type, title, message, author, timestamp }
 */
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

  // Trim old rows to keep sheet small
  const lastRow = sheet.getLastRow();
  if (lastRow > MAX_NOTIFICATIONS + 1) {
    sheet.deleteRows(2, lastRow - MAX_NOTIFICATIONS - 1);
  }

  return { success: true };
}

/**
 * Returns notifications with timestamp > since (ms).
 * Returns an array of { id, type, title, message, author, timestamp }.
 */
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
    // Write headers
    sheet.getRange(1, 1, 1, USER_HEADERS.length).setValues([USER_HEADERS]);
    // Style the header row
    sheet.getRange(1, 1, 1, USER_HEADERS.length)
      .setBackground('#1e3a5f')
      .setFontColor('#ffffff')
      .setFontWeight('bold');
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function getHeaders(sheet) {
  return sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
}

/**
 * Forces 'Plain Text' number format on the reg and phone columns
 * so that values like "0123" are never auto-converted to the number 123.
 */
function ensureTextColumns(sheet, headers) {
  ['reg', 'phone'].forEach(col => {
    const idx = headers.indexOf(col);
    if (idx >= 0 && sheet.getLastRow() > 1) {
      sheet.getRange(2, idx + 1, sheet.getLastRow() - 1, 1)
           .setNumberFormat('@');
    }
  });
}

function jsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
