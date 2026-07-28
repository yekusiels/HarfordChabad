/**
 * Daily Seven Excavation Questions app.
 * Serves the form and reads/writes the "Responses" sheet in the
 * spreadsheet this script is bound to.
 */

var SHEET_NAME = 'Responses';
var SAMPLES_PER_QUESTION = 4;

function doGet() {
  return HtmlService.createTemplateFromFile('index')
    .evaluate()
    .setTitle('The Seven Excavation Questions')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function getSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
    var header = ['Timestamp', 'Date'];
    for (var i = 1; i <= 7; i++) {
      header.push('Q' + i + ' Response', 'Q' + i + ' Samples Shown', 'Q' + i + ' Sample Ratings');
    }
    sheet.getRange(1, 1, 1, header.length).setValues([header]);
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function todayString_() {
  return Utilities.formatDate(new Date(), Session.getScriptTimeZone() || 'America/New_York', 'yyyy-MM-dd');
}

/**
 * Deterministic pick of `count` samples out of `pool`, seeded from a
 * string so the same day always shows the same samples on reload, but
 * a new day gets a fresh set.
 */
function pickSamples_(pool, count, seedString) {
  var seed = 0;
  for (var i = 0; i < seedString.length; i++) {
    seed = (seed * 31 + seedString.charCodeAt(i)) >>> 0;
  }
  var indices = pool.map(function (_, i) { return i; });
  var s = seed || 1;
  function rand() {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s / 0x7fffffff;
  }
  for (var j = indices.length - 1; j > 0; j--) {
    var k = Math.floor(rand() * (j + 1));
    var tmp = indices[j];
    indices[j] = indices[k];
    indices[k] = tmp;
  }
  return indices.slice(0, count).map(function (i) { return pool[i]; });
}

function parseDateUTC_(dateStr) {
  var p = dateStr.split('-');
  return Date.UTC(parseInt(p[0], 10), parseInt(p[1], 10) - 1, parseInt(p[2], 10));
}

var DAY_MS = 24 * 60 * 60 * 1000;

var LEVELS = [
  { minDays: 90, title: 'Steward', emoji: '🕊️' },
  { minDays: 30, title: 'Steady', emoji: '🔥' },
  { minDays: 7, title: 'Rooted', emoji: '🌳' },
  { minDays: 0, title: 'Seedling', emoji: '🌱' }
];

function levelFor_(totalDays) {
  for (var i = 0; i < LEVELS.length; i++) {
    if (totalDays >= LEVELS[i].minDays) return { title: LEVELS[i].title, emoji: LEVELS[i].emoji };
  }
  return { title: 'Seedling', emoji: '🌱' };
}

/**
 * Current streak (consecutive days up to today or, if today isn't
 * answered yet, up to yesterday), longest streak ever, and total
 * distinct days answered.
 */
function computeStats_(sheet) {
  var lastRow = sheet.getLastRow();
  var dateSet = {};
  if (lastRow >= 2) {
    var values = sheet.getRange(2, 2, lastRow - 1, 1).getValues();
    values.forEach(function (r) {
      if (r[0]) dateSet[r[0]] = true;
    });
  }
  var dates = Object.keys(dateSet).sort();
  var totalDays = dates.length;

  var longest = 0, current = 0, prevTime = null;
  dates.forEach(function (d) {
    var t = parseDateUTC_(d);
    current = (prevTime !== null && t - prevTime === DAY_MS) ? current + 1 : 1;
    longest = Math.max(longest, current);
    prevTime = t;
  });

  var today = todayString_();
  var cursor = dateSet[today] ? parseDateUTC_(today) : parseDateUTC_(today) - DAY_MS;
  var streak = 0;
  while (dateSet[Utilities.formatDate(new Date(cursor), 'UTC', 'yyyy-MM-dd')]) {
    streak++;
    cursor -= DAY_MS;
  }

  return {
    streak: streak,
    longestStreak: Math.max(longest, streak),
    totalDays: totalDays,
    level: levelFor_(totalDays)
  };
}

function findRowForDate_(sheet, date) {
  var lastRow = sheet.getLastRow();
  if (lastRow < 2) return null;
  var lastCol = sheet.getLastColumn();
  var values = sheet.getRange(2, 1, lastRow - 1, lastCol).getValues();
  var headers = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
  for (var r = 0; r < values.length; r++) {
    if (values[r][1] === date) {
      var rowValues = {};
      headers.forEach(function (h, i) { rowValues[h] = values[r][i]; });
      return { rowIndex: r + 2, values: rowValues };
    }
  }
  return null;
}

/**
 * Returns everything the client needs to render today's form: the
 * questions, a deterministic set of sample beliefs per question, and
 * any response/ratings already saved for today.
 */
function getTodayData() {
  var date = todayString_();
  var sheet = getSheet_();
  var existing = findRowForDate_(sheet, date);

  var questions = QUESTION_TEXT.map(function (text, idx) {
    var qNum = idx + 1;
    var pool = SAMPLE_ANSWERS[qNum];
    var samples = pickSamples_(pool, SAMPLES_PER_QUESTION, date + '-' + qNum);

    var response = '';
    var ratings = samples.map(function () { return null; });

    if (existing) {
      response = existing.values['Q' + qNum + ' Response'] || '';
      var savedRatingsRaw = existing.values['Q' + qNum + ' Sample Ratings'];
      if (savedRatingsRaw) {
        var parts = String(savedRatingsRaw).split(',').map(function (p) { return p.trim(); });
        ratings = samples.map(function (_, i) {
          var v = parseInt(parts[i], 10);
          return isNaN(v) ? null : v;
        });
      }
    }

    return { number: qNum, text: text, samples: samples, response: response, ratings: ratings };
  });

  return {
    date: date,
    questions: questions,
    hasExisting: !!existing,
    sheetUrl: SpreadsheetApp.getActiveSpreadsheet().getUrl(),
    stats: computeStats_(sheet)
  };
}

/**
 * Saves (or updates, if today already has an entry) one row: the date
 * plus, per question, the response, the samples shown, and their
 * 1-10 ratings.
 */
function submitResponses(payload) {
  var sheet = getSheet_();
  var date = (payload && payload.date) || todayString_();
  var existing = findRowForDate_(sheet, date);

  var row = [new Date(), date];
  for (var i = 1; i <= 7; i++) {
    var q = (payload.questions && payload.questions[i - 1]) || {};
    var samples = q.samples || [];
    var ratings = q.ratings || [];
    row.push(
      q.response || '',
      samples.join(' | '),
      ratings.map(function (r) { return (r === null || r === undefined) ? '' : r; }).join(', ')
    );
  }

  if (existing) {
    sheet.getRange(existing.rowIndex, 1, 1, row.length).setValues([row]);
  } else {
    sheet.appendRow(row);
  }
  return { ok: true, date: date, stats: computeStats_(sheet) };
}
