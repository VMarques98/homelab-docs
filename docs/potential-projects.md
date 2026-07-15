# Potential Projects

This page is the intake list for future homelab and Hermes-adjacent projects. Entries are ideas, not deployed services. Each project needs an owner, data classification, dependency map, backup plan, and verification checklist before implementation.

## Job Hunter + Hermes

A private, review-driven assistant for job discovery and applications. Hermes would normalize postings, score them against an approved candidate profile, draft tailored materials, track contacts and deadlines, and assist with browser/API form filling. Submission, attestations, screening answers, and identity claims require explicit human approval. Personal documents and application records stay outside Git.

**First milestone:** private profile store, job URL ingestion, deduplication, tailored draft generation, application tracker, and an approval screen.

## Receipt Ingest

A phone-to-cloud receipt workflow that preserves the original image, extracts merchant/date/total/tax/line items, resolves location when possible, detects duplicates, and writes a normalized record to a private database plus Excel-compatible export. Low-confidence OCR and Quicken mappings require review.

**First milestone:** authenticated upload inbox, immutable image storage, OCR of core fields, review queue, SQLite schema, and validated XLSX export.

## Quicken and budget reconciliation

A follow-on to Receipt Ingest that matches receipt records with bank/card transactions, tracks unmatched items, and applies reviewable category rules. It should preserve source values and corrections instead of silently rewriting financial history.

**First milestone:** import a sample transaction export, match on date/amount/merchant, and produce a review report without touching the source data.

## Hermes homelab operator

A constrained Hermes interface for read-only health checks, documentation lookup, incident evidence collection, and safe runbook execution. Destructive operations and broad restarts remain blocked or require explicit confirmation.

**First milestone:** read-only Proxmox/service inventory, runbook links, and evidence bundles with no secret output.

## Household document intake

A private intake pipeline for non-receipt documents such as warranties, invoices, manuals, and service records. It would classify documents, extract dates and identifiers, link them to assets, and schedule reminders without exposing private documents to the public documentation repository.

**First milestone:** encrypted upload folder, file hashing, OCR text extraction, metadata review, and retention rules.

## Homelab change and backup dashboard

A dashboard that correlates documentation commits, PBS backup freshness, service health, and outstanding recovery tests. It should distinguish "configured," "healthy now," and "restore verified."

**First milestone:** read-only status cards for Git remote SHA, recent PBS jobs, Uptime Kuma state, and documentation freshness.

## Delivery rules

1. Start with a written data-flow and threat model.
2. Keep personal, financial, identity, and credential-bearing data in private stores.
3. Make ingestion idempotent and retain immutable originals.
4. Add human review for uncertain extraction and external side effects.
5. Back up state through PBS or an explicitly chosen private backup system.
6. Document deployment, monitoring, failure handling, and recovery before calling a project operational.
