# Feature Specification: Driving speed from location (automotive-optimized)

**Feature Branch**: `002-specify-read-driving`  
**Created**: 2025-09-19  
**Status**: Draft  
**Input**: User description: "/specify Read driving speed from CLLocation speed with a accuracy set to \".bestForNavigation\" and activityType set to \".automotiveNavigation\""

---

## User Scenarios & Testing (mandatory)

### Primary User Story
As a driver, I want the app to show my current vehicle speed accurately and responsively while I am in a car, so I can monitor how fast I am traveling in relation to speed limits.

### Acceptance Scenarios
1. **Given** the app has location permission and the user is traveling in a car around 50 km/h (31 mph), **When** the user opens the app or returns to the main screen, **Then** the speed is shown within 2 seconds and reflects the vehicle speed within ±5% (or ±2 km/h/±1 mph, whichever is greater) in the selected unit.
2. **Given** the vehicle comes to a stop, **When** speed remains below a low-speed threshold for a brief period, **Then** the displayed speed transitions to 0 and remains stable (no jitter) within 3 seconds of stopping.
3. **Given** location updates are temporarily unavailable or delayed (e.g., tunnels), **When** no fresh update is received for more than 3 seconds, **Then** the UI indicates the speed is stale (e.g., dimmed value or status) rather than showing misleading changes.
4. **Given** the user is walking or cycling (not driving), **When** detected speed remains persistently below a driving threshold, **Then** the app does not present a misleading “driving” speed and either shows 0 or an alternate state. [NEEDS CLARIFICATION: desired behavior outside automotive context]
5. **Given** the user prefers mph instead of km/h, **When** the app shows the speed, **Then** the speed is displayed in mph and changes unit consistently across the UI.

### Edge Cases
- Loss of permission or permission not granted at first launch → show clear guidance and do not present a numeric speed until permission is granted. [NEEDS CLARIFICATION: exact copy and flow]
- Poor location accuracy → do not show a numeric speed; indicate low confidence until accuracy improves. [NEEDS CLARIFICATION: threshold]
- Background or screen-locked states → define whether speed should continue updating or pause. [NEEDS CLARIFICATION]
- Very low speeds due to traffic crawl → avoid oscillation between 0 and small numbers; treat as stopped below threshold after debounce.

---

## Requirements (mandatory)

### Functional Requirements
- **FR-001**: The system MUST obtain and respect user consent for location access before showing speed.
- **FR-002**: The system MUST derive current ground speed from device location updates using a mode optimized for in-vehicle navigation and high accuracy (automotive-optimized).
- **FR-003**: The system MUST present speed in the user’s preferred unit (km/h or mph) and apply the preference consistently.
- **FR-004**: The system MUST update the displayed speed at least once per second while the user is moving faster than a driving threshold.
- **FR-005**: The system MUST indicate when the displayed speed is stale if no fresh location update has been received within 3 seconds.
- **FR-006**: The system MUST treat speeds below a configurable low-speed threshold (default 3 km/h or 2 mph) as “stopped” after a short debounce (e.g., 2–3 seconds) to prevent jitter.
- **FR-007**: The system MUST suppress numeric speed when location confidence/accuracy is below an acceptable threshold and instead show a low-confidence state. [NEEDS CLARIFICATION: exact accuracy/confidence threshold]
- **FR-008**: The system MUST avoid visible oscillations at constant speed; short-term variance in the displayed value SHOULD be within ±2 km/h (±1 mph) or ±5%, whichever is greater.
- **FR-009**: The system MUST handle invalid, negative, or missing speed readings by ignoring them and maintaining the last valid value with a stale indicator if needed.
- **FR-010**: The system SHOULD minimize battery impact consistent with the automotive use-case. [NEEDS CLARIFICATION: background behavior requirements]

### Key Entities (if data involved)
- **Speed Reading**: A single measurement of current ground speed with timestamp and confidence. Attributes: value (numeric), unit (km/h or mph), timestamp, confidence/accuracy indicator, isStale flag.
- **Movement State**: Derived state indicating stopped vs. moving based on recent readings and thresholds.
- **User Preference: Units**: Choice between km/h and mph for display.

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

## Execution Status
*To be updated during planning/review*

- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] User scenarios defined
- [ ] Requirements generated
- [ ] Entities identified
- [ ] Review checklist passed

---


