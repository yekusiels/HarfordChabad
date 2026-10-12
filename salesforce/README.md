# Inner Circle donor segmentation: Salesforce metadata

Adds custom fields to **Contact**, plus a permission set **Inner Circle Fundraising** that grants access to them.

| Package | Contents | Requires |
|---|---|---|
| `1-inner-circle-fields.zip` | Inner Circle Tier, Estimated Net Worth, Largest Known Outside Gift, Mission Alignment, Relationship Depth, Alignment Notes, Next Step, Next Step Date, plus the permission set | nothing |
| `2-inner-circle-formulas-npsp.zip` | Everything in package 1 **plus** Suggested Tier and Touch Overdue formulas | NPSP (uses `npo02__` rollup fields) |

Deploy **package 2** if you use NPSP; it includes everything. If it fails with "field does not exist: npo02__…", deploy package 1 instead.

## Deploy with Workbench
1. Go to workbench.developerforce.com, choose **Production**, and log in.
2. **Migration → Deploy**, then choose the zip.
3. Tick **Check Only** for a dry run first, then deploy again without it. Leave "Single Package" ticked.

## Deploy with the Salesforce CLI
```
sf org login web --alias harford --instance-url https://harfordchabad.my.salesforce.com
sf project deploy start --metadata-dir salesforce/2-inner-circle-formulas-npsp --target-org harford --dry-run
sf project deploy start --metadata-dir salesforce/2-inner-circle-formulas-npsp --target-org harford
sf org assign permset --name Inner_Circle_Fundraising --target-org harford
```

## After deploying
- Assign the permission set: Setup → Permission Sets → Inner Circle Fundraising → Manage Assignments.
- Add the fields to the Contact page layout (Setup → Object Manager → Contact → Page Layouts). The packages don't change your layouts.

To change a field, edit `generate.py`, run `python3 salesforce/generate.py` from the repo root, and re-zip.
