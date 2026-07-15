---
date: 2026-07-15
tags:
  - project
  - homelab
  - roadmap
  - automation
parent: "[[Homelab 3.0]]"
status: planned
---

# Homelab Roadmap

This note records planned personal workflow automation that may be hosted by or integrated with the homelab. Neither system is deployed yet.

## Job Hunter + Hermes

### Goal

Expand the existing job-hunter workflow so Hermes can help discover suitable roles, compare them against a user-maintained profile, tailor application materials, track application state, and assist with repetitive application steps.

### Proposed workflow

1. **Ingest** — collect job URLs, descriptions, recruiter messages, and closing dates from approved sources.
2. **Normalize** — deduplicate postings and store employer, title, location, compensation, work mode, requirements, and source URL.
3. **Match** — score opportunities against the candidate profile and record the reasons for the score.
4. **Prepare** — draft tailored resume variants, cover letters, answers, and recruiter follow-ups using approved source material.
5. **Review gate** — present the complete application package and any uncertain answers for human review.
6. **Assist** — use Hermes/browser automation or supported APIs to populate forms only after approval.
7. **Submit and track** — require explicit confirmation before submission; record the application URL, timestamp, status, and follow-up date.

### Guardrails

- No automatic submission, attestation, identity claims, or answers to screening questions without human approval.
- Never fabricate experience, qualifications, sponsorship status, salary history, or work authorization.
- Keep resumes, personal identifiers, recruiter correspondence, and application data in an access-controlled private store; do not commit them to this repository.
- Respect site terms, rate limits, robots controls, CAPTCHA, and login boundaries. Stop for manual intervention when a site requires it.
- Keep an audit trail of source posting, generated draft, edits, approval, and final submission.

### Likely components

- Hermes as the orchestration and review interface.
- A private database for opportunities, applications, contacts, and state transitions.
- Object storage for resumes and generated application artifacts.
- A browser-assisted worker for sites without a supported API, isolated from the core homelab where practical.
- Scheduled discovery and follow-up jobs, with notifications requiring explicit user action.

## Receipt Ingest

### Goal

Allow receipt images uploaded from a phone to a private cloud drop location each day. The system should preserve the original image, extract structured details and location, and maintain an Excel-compatible ledger/database that supports Quicken import and budget analysis.

### Proposed workflow

1. **Upload** — phone uploads an image to a private, authenticated cloud folder or inbox.
2. **Capture metadata** — record upload time, original filename, file hash, device metadata when available, and source location.
3. **Extract** — OCR the merchant, date, total, tax, currency, payment method, line items, and receipt number where present.
4. **Resolve location** — use receipt address or geotag when available; otherwise geocode the merchant address with a configured provider and mark the confidence/source.
5. **Review exceptions** — send low-confidence, duplicate, unreadable, or conflicting receipts to a review queue.
6. **Store** — retain the original image and a normalized record linked by immutable receipt ID.
7. **Export** — write an Excel-compatible workbook and provide a Quicken-friendly export mapping without overwriting the source ledger.
8. **Reconcile** — later match receipt totals and dates against bank/card transactions, preserving unmatched and manually corrected states.

### Minimum normalized record

| Field | Purpose |
|---|---|
| `receipt_id` | Stable internal identifier |
| `image_path` / `image_url` | Link to the original image |
| `sha256` | Duplicate detection and integrity check |
| `merchant` | Payee/merchant name |
| `transaction_date` | Date printed on the receipt |
| `total` / `tax` / `currency` | Financial amounts |
| `category` | Budget category, including confidence/source |
| `location_name` / `latitude` / `longitude` | Place information, when available |
| `line_items` | Item-level detail, preferably in a child table |
| `payment_method` | Card, cash, or other method when identifiable |
| `source` / `ocr_confidence` | Provenance and review priority |
| `review_status` | Pending, approved, corrected, duplicate, or rejected |
| `quicken_export_status` | Export/reconciliation state |

### Privacy and integrity requirements

- Keep receipts and financial records private; do not store them in this public documentation repository.
- Encrypt storage and backups, restrict access, and define a retention policy for images and exports.
- Treat OCR and geolocation as suggestions until reviewed; retain provenance and confidence rather than silently changing values.
- Never delete an original image because an export was generated.
- Make ingestion idempotent so retries do not create duplicate financial transactions.
- Do not claim Quicken compatibility until a sample export is validated against the target Quicken workflow.

## Suggested delivery phases

1. **Foundation** — choose private upload destination, storage, database schema, and backup policy.
2. **Receipt MVP** — ingest images, OCR core fields, review exceptions, and export XLSX.
3. **Reconciliation** — add bank-transaction matching and category rules.
4. **Job Hunter MVP** — private profile store, job normalization, drafting, review UI, and application tracker.
5. **Assisted applications** — browser/API assistance with approval gates and audit records.

## Open decisions

- Which private cloud inbox should receive phone uploads?
- Should the receipt ledger use SQLite/Postgres, a spreadsheet-first workflow, or both?
- Which OCR/geocoding providers meet the privacy and cost requirements?
- Which Quicken edition/import format is the target?
- Where should personal documents and automation workers run relative to the trusted homelab network?
