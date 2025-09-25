# Phase 0 Research: Manage GPKG Downloads in Settings

## Decisions and Resolutions

1. Resume Support
- Decision: Support resumable downloads when the remote server supports byte-range requests. When not supported, resume is modeled as a restart with clear user messaging.
- Rationale: The feature requires Pause/Resume; resumable is preferred to avoid repeated bandwidth; fallback ensures predictable behavior.
- Alternatives: Require resumable support for all sources (rejected due to source variability).

2. Partial Data on Cancel
- Decision: Remove all partial local files when a user cancels a download.
- Rationale: User explicitly requested cleanup on cancel; prevents wasted storage and confusion.
- Alternatives: Keep partial files for faster resume (rejected due to user requirement and clarity).

3. Post-Delete Listing Behavior
- Decision: Keep the dataset listed as available for re-download after deletion.
- Rationale: Users may want to manage space temporarily and re-download later.
- Alternatives: Remove from list (rejected due to discoverability and control loss).

4. Background Execution and Interruption
- Decision: If downloads are interrupted (background limits, app termination), items appear Paused on next launch; user can Resume.
- Rationale: Aligns with iOS background constraints and safety-first principle.
- Alternatives: Attempt background completion always (rejected due to reliability and policy constraints).

5. Concurrency and Queueing
- Decision: Limit to one active download at a time; queue additional downloads in FIFO order.
- Rationale: Simplicity and resource control; clearer UI; meets user acceptance scenario.
- Alternatives: Multiple parallel downloads (rejected for performance and clarity).

6. Integrity Validation
- Decision: Validate by expected total byte count; checksum/hash validation deferred as an enhancement.
- Rationale: Lightweight and sufficient for MVP; checksum availability uncertain.
- Alternatives: Mandatory checksums (rejected due to dependency on external sources).

7. Progress Display Format
- Decision: Display "downloadedByteCount / totalByteCount" and percentage; throttle UI updates to avoid jank.
- Rationale: Meets user requirement; respects performance budgets.
- Alternatives: Percentage-only (rejected; user requested bytes view).

8. Variable Naming Convention
- Decision: All variable identifiers use full words (no abbreviations). Examples: `datasetIdentifier`, `downloadStatus`, `downloadedByteCount`, `totalByteCount`, `remoteResourceAddress`.
- Rationale: User requirement for clarity and readability; aligns with code standards.

9. Network Policy for Large Downloads
- Decision: For expectedTotalByteCount > 50 megabytes, prefer WiFi. If current connectivity type is cellular, prompt the user for confirmation before starting or resuming the download.
- Rationale: Minimize data charges and improve reliability for large files.
- Alternatives: Always allow without prompt (rejected due to cost/risk); always block on cellular (rejected to preserve user choice).

11. Control Simplification (No Cancel)
- Decision: Remove Cancel; use a single control that toggles between Download and Pause. When resuming, display the Download icon, not Play.
- Rationale: Simpler and familiar pattern; reduces control count and visual noise.

12. Circular Progress Ring
- Decision: Show a circular progress ring around the Download/Pause button while downloading.
- Rationale: Matches common media UX patterns; compact and glanceable.

10. File System Persistence and Location
- Decision: Save downloaded files inside the app container on iPhone/iPad (prefer Application Support directory). Files persist across app updates and are only removed when the user deletes them (or on app uninstall).
- Rationale: Meets persistence requirement and platform guidelines; sandbox ensures privacy and stability.
- Alternatives: Temporary or cache directories (rejected due to eviction risk); iCloud Drive (rejected for offline-first and privacy scope).

## Open Risks
- Remote sources without byte-range will cause resume to restart; clearly communicate this limitation.
- Very large files (up to ~5 GB) may stress storage; preflight available capacity before starting.
- Connectivity may switch mid-download; upon transition to cellular with large files, pause and request confirmation before continuing.
 - Storage location quotas and backup policies: Application Support is not auto-evicted; consider excluding from backup if size grows significantly.


