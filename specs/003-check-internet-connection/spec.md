# Feature Specification: Connectivity & Country Context for GPKG Downloads

**Feature Branch**: `003-check-internet-connection`  
**Created**: 2025-09-21  
**Status**: Draft  
**Input**: User description: "check internet connection and country the device is in. This is required to be able to handle downloads and selecting the right gpkg file to download."

## User Scenarios & Testing (mandatory)

### Primary User Story
As a driver using the app, I want the app to know whether I have an internet connection and which country I am currently in so that it can select and download the correct map package (GPKG) automatically, and continue working gracefully when I’m offline.

### Acceptance Scenarios
1. **Given** the app is in the foreground and the device has usable internet in Denmark, **When** a map package is required, **Then** the app identifies connectivity as online, determines the current country as Denmark (DK), selects the DK GPKG package from the catalog, and proceeds to download per user preferences (auto or with confirmation), showing clear progress and completion states.
2. **Given** the device has no usable internet, **When** a map package is required, **Then** the app shows a clear "No internet" status, defers the download, continues with any available cached data, and automatically resumes or prompts to resume once connectivity is restored.
3. **Given** the user declines precise location permissions, **When** country determination is needed to select a GPKG, **Then** the app offers a simple manual country selection flow and uses the chosen country for selection until changed.
4. **Given** the device’s SIM/locale country differs from the current physical location (roaming), **When** a country is needed, **Then** the app uses the current physical location country to select the GPKG, and informs the user if there is ambiguity or a change is about to occur. [NEEDS CLARIFICATION: Preferred signal priority for country – physical location vs device locale vs SIM?]
5. **Given** the device is connected to Wi‑Fi behind a captive portal or with restricted internet, **When** the app checks connectivity, **Then** it treats connectivity as not usable for downloads until reachability to the content host is confirmed, and communicates the state to the user.

### Edge Cases
- VPN or enterprise network masks country; user can manually override country and the app remembers the choice.
- Border proximity causes jitter across countries; the app avoids rapid switching using a stability window before changing the active country.
- Country is unsupported or has no corresponding GPKG; the app communicates the limitation and suggests the nearest available region or fallback behavior.
- Connectivity is extremely slow or intermittent; the app communicates delays, applies retry/backoff, and allows the user to cancel or defer.
- App is backgrounded or terminated during download; on return it resumes safely from the last known state.

## Requirements (mandatory)

### Functional Requirements
- **FR-001**: The system MUST determine whether the device has usable internet connectivity for downloading content.
- **FR-002**: The system MUST determine the device’s current country to select the correct GPKG package.
- **FR-003**: The system MUST select a GPKG package from a catalog based on the determined country and present relevant package metadata (e.g., name, size, version) prior to download when appropriate.
- **FR-004**: The system MUST clearly communicate connectivity status and country context to the user whenever these impact downloads or package selection.
- **FR-005**: The system MUST provide a manual country selection override when automatic detection is unavailable, ambiguous, or overridden by the user.
- **FR-006**: The system MUST handle offline conditions by deferring downloads and continuing with cached map data when available, attempting downloads later when connectivity becomes usable.
- **FR-007**: The system MUST avoid frequent country switching near borders by applying a stability window or user confirmation before changing the selected country for GPKG selection.
- **FR-008**: The system MUST respect user privacy and avoid retaining precise location data beyond what is necessary to determine the country context.
- **FR-009**: The system MUST verify reachability to the content host before starting a download to avoid captive portal or DNS sinkhole conditions.
- **FR-010**: The system MUST inform the user when the detected or selected country is unsupported and provide a clear next step (e.g., pick a different country or proceed without a package).
- **FR-011**: The system MUST provide observable download states (queued, downloading, paused, resumed, completed, failed) and associated messaging.
- **FR-012**: The system MUST record and expose the current country context to other features that depend on it (e.g., speed limits, regional rules), updating only when the stability window allows.

### Non-Functional Requirements
- **NFR-001**: Initial connectivity and country determination SHOULD complete within a target time after app foregrounding. [NEEDS CLARIFICATION: Target time budget, e.g., ≤2 seconds]
- **NFR-002**: The system SHOULD minimize data usage while checking connectivity and determining country. [NEEDS CLARIFICATION: Cellular vs Wi‑Fi policies]
- **NFR-003**: The system SHOULD achieve high reliability for correct country detection under normal conditions. [NEEDS CLARIFICATION: Reliability target]
- **NFR-004**: User-facing states and messages MUST be understandable at a glance, avoiding technical jargon.

### Key Entities (data involved)
- **Connectivity Status**: Indicates whether internet is usable for downloads; includes reason (offline, captive portal, DNS issues, host unreachable) and last-checked timestamp.
- **Country Context**: Active ISO country code, source (automatic via location, manual selection, device setting), timestamp, and confidence/ambiguity indicator.
- **Map Package Catalog**: Mapping of country codes to available GPKG packages with human-readable metadata (name, version, size, last updated).
- **Download Request**: Desired package identifier, user confirmation state (if required), current status (queued/downloading/completed/failed/paused), retry counters, and completion timestamp.

---

## Review & Acceptance Checklist

### Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] Written for non-technical stakeholders
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified

---

