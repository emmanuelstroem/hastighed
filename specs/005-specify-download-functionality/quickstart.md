# Quickstart Validation: Manage GPKG Downloads in Settings

1. Open the Settings view and navigate to Downloads.
2. Verify each dataset row shows country name and file size (if known).
3. Tap the Download button:
   - The button changes to Pause and a circular progress ring appears around it.
   - Text shows "downloadedByteCount / totalByteCount".
   - If expectedTotalByteCount > 50 MB and current connectivity is cellular, a confirmation dialog appears asking to continue over cellular; choose Continue to proceed or Cancel to abort.
4. Tap Pause:
   - Status changes to Paused.
   - The single control now shows the Download icon to resume.
5. Tap Resume:
   - Download continues from current progress.
6. There is no Cancel control; to stop, Pause and leave paused or Delete after completion.
7. After completion:
   - A green checkmark appears next to the country name.
   - Delete control is available; use it to remove the local file.
8. Confirm storage increases after Delete and the dataset remains available to download again.
9. Connectivity policy:
   - On WiFi, large downloads (> 50 MB) start without confirmation.
   - On cellular, large downloads prompt for confirmation before starting or resuming.
10. Persistence and location validation:
    - After completing a download, quit and relaunch the app; verify the file remains present and the item shows as Completed.
    - Confirm the file exists in the app’s Application Support directory path and persists across an app update (simulated by reinstall without data wipe where possible).

Accessibility:
- Verify VoiceOver announces progress changes and control labels.

Performance:
- Ensure UI remains responsive; progress updates are smooth and not excessive.


