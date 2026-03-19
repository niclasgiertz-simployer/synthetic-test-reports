# Synthetic User Test Reports

Persona-based UX evaluations deployed as static HTML via Vercel.

## Setup (one-time)

### 1. Create GitHub repo

```bash
cd synthetic-test-reports
git init
git add -A
git commit -m "Initial commit with report index and existing tests"
git branch -M main
git remote add origin git@github.com:<your-username>/synthetic-test-reports.git
git push -u origin main
```

Or use GitHub CLI:

```bash
cd synthetic-test-reports
git init && git add -A && git commit -m "Initial commit"
gh repo create synthetic-test-reports --public --source=. --push
```

### 2. Connect to Vercel

1. Go to [vercel.com/new](https://vercel.com/new)
2. Click **Import Git Repository**
3. Select `synthetic-test-reports`
4. Framework Preset: **Other**
5. Output Directory: `.` (root)
6. Click **Deploy**

That's it. Every `git push` to `main` will auto-deploy.

Your reports will be live at: `https://synthetic-test-reports.vercel.app/`

## Adding new reports

### Option A: Use the publish script

```bash
./publish.sh path/to/report.html \
  --site "Company.com" \
  --date "2026-03-17" \
  --personas "Olivia (HR Admin)" \
  --task "HRIS Evaluation" \
  --verdict "Recommended" \
  --verdict-type "good"
```

The script copies the file, updates the index, commits, and pushes.

`--verdict-type` options: `good` (green), `mixed` (yellow), `bad` (red)

### Option B: Manual

1. Copy your `.html` report into `/reports`
2. Edit `index.html` — add an entry before the `REPORT_ENTRIES_END` marker
3. Commit and push

## Structure

```
synthetic-test-reports/
├── index.html          ← Dashboard listing all reports
├── reports/            ← Individual HTML test reports
│   ├── synthetic-test-simployer-2026-03-17.html
│   └── synthetic-test-sia-mvp-2026-03-17.html
├── publish.sh          ← Script to add new reports
├── vercel.json         ← Vercel deploy config
└── README.md
```

## Custom domain (optional)

In Vercel dashboard → Settings → Domains, add your custom domain.
Example: `tests.yourcompany.com`
