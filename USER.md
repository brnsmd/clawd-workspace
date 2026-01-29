# USER.md - About Your Human

- **Name:** Heorhii Tsapenko
- **What to call them:** Heorhii
- **Timezone:** Europe/Kyiv (UTC+2/+3)
- **Location:** Kyiv, Ukraine

## Professional

- **Role:** Orthopaedic-trauma-reconstructive surgeon
- **Workplace:** Military hospital (Ukraine)
- **Focus:** Bone and septic trauma ward (кістково-гнійна травматологія)
- **Academic:** Finishing PhD

### Security Requirements
- **Fort Knox level security** — routing, encryption, everything
- Military hospital = critical infrastructure
- Patient data protection is paramount
- ClickUp uses only case numbers, never names (names stay in CyberIntern)

## Projects

### Zav (Завідувач) — `/Projects/Zav`
Hospital management system with **Rust TUIs** replacing Python backends. **ACTIVE DEVELOPMENT.**

**Architecture:**
- **boss-tui** — Main hospital dashboard (patients, VLK, operations, wards) + embedded API server (:8083)
- **cyberintern-tui** — Doctor's view (alerts, diaries, prescriptions)
- **nurse-tui** — Nurse station (temperature sheets, tasks, medications)

**Current State (2026-01-29):**
- Rust Sync Phases 1-4 complete (~960 lines): Airtable, Validator, CyberIntern clients
- 5 issues remaining — all need EMR/API access for testing
- Uses `bd` (beads) for issue tracking

**Integrates:** Airtable, CyberIntern API, МІС (hospital EMR via Playwright), Slack
**Military-specific:** VLK (military medical commission), evacuation flow, staged treatment

**Commands:** `boss`, `boss-relay`, `boss-status`

### CyberIntern — `/Projects/Cyberintern`
Medical automation software (Python + Playwright):

- EMR scraping/automation for hospital system
- Patient diaries, prescriptions, consultations, diagnostics
- OCR for medical document parsing
- Form 027/о (discharge summary) automation
- Windows installer for hospital deployment
- **cyberintern-tui** (Rust, in Zav) wraps this with AlertGenerator, DiaryTemplates, SlackService

### Debugging Style
- **GRUG MODE / BARBARIAN TECHNIQUE** — all caps, bugs are "boars", high-energy debugging
- "CLUG" was promoted to CO-CHIEF OF TRIBE after conquering Form 027/о
- Wisdom: "SIMPLE CODE. ROCK TO BOAR HEAD. BOAR GONE."

## Context Management
For long projects, uses a workflow:
1. HUNT (complete phase)
2. DOCUMENT (update STATUS.md, MASTERPLAN)
3. REPORT (tell Grug what was done)
4. CLEAR (`/clear` to reset context)
5. REPEAT

## Notes
- Uses Claude heavily for development (see CLAUDE.md in projects)
- n8n webhooks for automation
- PhD writing also happens on this machine
- Ukrainian language for medical interfaces
