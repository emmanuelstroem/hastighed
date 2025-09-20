# Data Model: Driving Speed & Permission

## Entities

### PermissionState
- status: one of {notDetermined, authorizedWhenInUse, authorizedAlways, denied, restricted}
- lastPromptDate: timestamp (optional)
- canOpenSettings: boolean

### SpeedReading
- value: number (km/h or mph per preference)
- unit: {kmh, mph}
- timestamp: ISO8601
- speedAccuracy: number (m/s) (optional)
- isStale: boolean
- confidence: {low, medium, high}

### MovementState
- isMoving: boolean
- stoppedSince: timestamp (optional)
- lowSpeedThreshold: number (km/h)
- debounceWindowSeconds: number

## Relationships
- PermissionState gates whether SpeedReading can be produced.
- MovementState is derived from recent SpeedReading instances.

## Validation Rules
- Ignore negative speed values and values with NaN/Inf.
- Mark reading as low-confidence if speedAccuracy > 1.5 m/s or missing.
- Convert m/s to desired display units consistently.

