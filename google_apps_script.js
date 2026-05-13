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

const EMPLOYEES_SHEET = 'employees';
const USERS_SHEET      = 'users';

// ══════════════════════════════════════════════════════════════
//  ENTRY POINTS
// ══════════════════════════════════════════════════════════════

function doGet(e) {
  const action = e && e.parameter && e.parameter.action;

  if (action === 'get_users') {
    return jsonResponse(getUsers());
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

    default:
      return jsonResponse({ error: 'Unknown action: ' + action });
  }
}

// ══════════════════════════════════════════════════════════════
//  EMPLOYEES
// ══════════════════════════════════════════════════════════════

function getAllEmployees() {
  const sheet = getOrCreateSheet(EMPLOYEES_SHEET);
  const data  = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  return data.slice(1).map(row => {
    const obj = {};
    headers.forEach((h, i) => obj[h] = row[i]);
    return obj;
  });
}

function addEmployee(data) {
  const sheet   = getOrCreateSheet(EMPLOYEES_SHEET);
  const headers = getHeaders(sheet);
  const row     = headers.map(h => data[h] !== undefined ? data[h] : '');
  sheet.appendRow(row);
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
  const headers = getHeaders(sheet);

  // Clear all rows except header
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    sheet.deleteRows(2, lastRow - 1);
  }

  // Re-insert all employees
  const rows = employees.map(emp => headers.map(h => emp[h] !== undefined ? emp[h] : ''));
  if (rows.length > 0) {
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

function jsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
