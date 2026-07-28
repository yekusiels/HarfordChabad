# Daily Seven Excavation Questions

A small personal web app that asks the seven excavation questions every
day, one at a time like a quick quiz. Under each question you can tap
an example belief (drawn from the appendix PDF) to instantly use it as
your answer — no typing required — and rate 1-10 how much it
resonates. A streak counter, a level badge, and a progress tracker
make it feel like a habit game instead of a chore. Everything — date,
your answer to each question, the samples shown, and your ratings —
saves as one row in a Google Sheet.

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

Open the web app URL. It walks you through the seven questions one at
a time, like a quick quiz:

- **Tap to answer.** Under each question, four example beliefs
  (rotating automatically each day) are shown as tappable cards — tap
  one and it instantly becomes your answer in the text box above, no
  typing required. You can still edit it, or write your own from
  scratch. Rate any example 1-10 for how much it resonates.
- **Progress dots** across the top show all 7 questions at a glance —
  filled and checked once answered, so you can jump to any question or
  just watch the dots fill in as you go.
- **Streak, level, and days-practiced** are shown at the top: your
  current daily streak, a level badge that levels up the more
  consistently you show up (🌱 Seedling → 🌳 Rooted at 7 days → 🔥
  Steady at 30 → 🕊️ Steward at 90), and your total days practiced.
- Hit **Finish** on the seventh question for a small celebration
  (confetti + updated streak). A **Save now** button in the header
  saves your progress at any point, even mid-way through.

Your entry lands in a **Responses** tab in the spreadsheet with these
columns: `Timestamp`, `Date`, and for each question `Qn Response`,
`Qn Samples Shown`, `Qn Sample Ratings`.

If you open the app again later the same day, it preloads what you
already wrote and shows which questions are already answered — saving
again updates that day's row instead of adding a duplicate.

## Source of the questions

The seven questions and the pool of example beliefs come from the
appendix "The Seven Excavation Questions with Example Responses,"
provided as a PDF. `Questions.gs` contains all 140 example beliefs (20
per question); each day the app deterministically shows a different 4
per question.
