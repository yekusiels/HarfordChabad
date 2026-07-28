# Daily Seven Excavation Questions

A small personal web app that asks the seven excavation questions every
day, offers example beliefs (drawn from the appendix PDF) for
inspiration that you can rate 1-10 for how much they resonate, and
saves everything — date, your answer to each question, the samples
shown, and your ratings — as one row in a Google Sheet.

It's built as a Google Apps Script "container-bound" script, so there's
no server to host or pay for: Google runs it, and it writes directly
into a spreadsheet you own.

## One-time setup (~10 minutes)

1. Go to [sheets.google.com](https://sheets.google.com) and create a
   new blank spreadsheet. Name it something like **"Excavation
   Questions Log"**.
2. In the spreadsheet, open **Extensions > Apps Script**. This opens a
   script project already bound to your sheet.
3. In the Apps Script editor, delete the placeholder `Code.gs`
   content, then recreate the files from this folder:
   - `Code.gs` — create a file named `Code.gs`, paste in the contents
     of [`Code.gs`](./Code.gs).
   - `Questions.gs` — create a new script file named `Questions.gs`,
     paste in [`Questions.gs`](./Questions.gs).
   - `index.html` — create a new **HTML** file named `index`, paste in
     [`index.html`](./index.html).
   - `appsscript.json` — click the gear icon (Project Settings) and
     check "Show `appsscript.json` manifest file in editor", then open
     it from the file list and replace its contents with
     [`appsscript.json`](./appsscript.json).
4. Save the project (Ctrl/Cmd+S).
5. Click **Deploy > New deployment**.
   - Click the gear next to "Select type" and choose **Web app**.
   - Description: anything, e.g. "Daily questions v1".
   - **Execute as**: Me (your account).
   - **Who has access**: Only myself (you can pick "Anyone with a
     Google account" instead if you want to open it from a phone
     that's signed into a different Google identity, but "Only myself"
     is enough as long as you're signed into your own Google account
     in the browser you use).
   - Click **Deploy**, then **Authorize access** and click through the
     "Google hasn't verified this app" screen (choose "Advanced" >
     "Go to (project name)") — this is expected for a script you wrote
     and own.
6. Copy the **web app URL** it gives you. Bookmark it, or add it to
   your phone's home screen, so it's a one-tap daily habit.

## Daily use

Open the web app URL. It shows the seven questions with a text box for
each. Expand "Need a spark? See example beliefs" under any question to
see four example beliefs (rotates automatically each day) and rate how
much each one resonates, 1-10 — purely to help you find your own
words. Click **Save today's answers**.

Your entry lands in a **Responses** tab in the spreadsheet with these
columns: `Timestamp`, `Date`, and for each question `Qn Response`,
`Qn Samples Shown`, `Qn Sample Ratings`.

If you open the app again later the same day, it preloads what you
already wrote — saving again updates that day's row instead of adding
a duplicate.

## Source of the questions

The seven questions and the pool of example beliefs come from the
appendix "The Seven Excavation Questions with Example Responses,"
provided as a PDF. `Questions.gs` contains all 140 example beliefs (20
per question); each day the app deterministically shows a different 4
per question.
