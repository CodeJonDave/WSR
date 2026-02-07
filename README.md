# Work Safe Radio (WSR)

Work Safe Radio (WSR) is a concept and design repository for a workplace-safe,
Spotify-like music platform intended for shared environments (warehouses,
retail floors, offices).

The goal is to provide centralized music playback that is:
- compliant with workplace policies
- controllable by admins
- predictable for listeners
- extensible for future features

This repository focuses on **system design, data modeling, and product scope**
rather than a finished implementation.

---

## Problem Statement

Most workplaces rely on ad-hoc music sources (personal phones, random playlists)
that create issues with:
- explicit content
- inconsistent volume and control
- licensing ambiguity
- lack of administrative oversight

WSR proposes a **centralized, managed music system** tailored for shared spaces.

---

## What’s in This Repo

This is a **design-first** project.

- Product requirements and scope
- Data models and schema drafts
- System architecture notes
- API and service boundary planning

Detailed documentation lives in `wsr_docs/`.

---

## Repository Structure

WSR/
├── wsr_docs/
│ ├── requirements.md
│ ├── data_model.md
│ ├── architecture.md
│ └── roadmap.md
├── .vscode/
└── README.md


---

## Proposed Architecture (High-Level)

- Backend service (user, playlists, policy enforcement)
- Admin control plane
- Client applications (web / kiosk / device)
- External music provider integration (e.g., Spotify API)
- Policy and content filtering layer

This repo documents the **why and how**, not yet the code.

---

## Status

- Requirements: drafted
- Data modeling: drafted
- Architecture: drafted
- Implementation: not started

---

## Portfolio Intent

This project demonstrates:
- Product thinking beyond code
- System decomposition and boundaries
- Translating real-world problems into technical designs
- Planning before implementation

WSR is intentionally kept as a design artifact to show how I approach
building a system from first principles.