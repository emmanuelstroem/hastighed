## Purpose ##
This is an iOS only app.
It uses takes "precise" GPS location from device, and uses MapKit to find the street.

## Instructions
- Developed in SwiftUI using updated APIs for iOS 26.
- Do NOT use deprecated APIs. 
- Do NOT show summaries 
- Create Makefile to make build. It should compile the code and produce an executable
- App should function entirely OFFLINE

## Flow
- App should check and ask for user permissions at launch. If already granted, proceed to the HomeView
- Check country at startup, if {country_name}.osm.pbf exists, then use that to query for maxspeed
- If {country_name}.osm.pbf does NOT exist, ask the user to download it under settings 

## Functionality ##
- Store the precise street name to userDefaults
- Track this and update it as fast as the device can
- Use this coordinates / road name to query OpenStreetMap for MaxSpeed (Speed Limit)
- ONLY and ONLY make another request to API when the street/road name changes. This should help with rate limiting issues  
- Also update it in the userDefaults when it changes.
- Tracking should be extremely precise. This app's purpose is just about speed limits, speed cameras and construction
- Location and street name should be updated in realtime 

## Interface ##
- Should look like a vehicle instrument cluster.
- Should show GPS speed and overlay the speed on the road in a white circular background with a thick red outline.
- Should show the street/road name at the bottom of the view.
- Support Portrait and Landscape
- In Landscape, instrument cluster should be displayed horizontally, if possible shouuld look like CarPlay ultra here: https://www.apple.com/newsroom/2025/05/carplay-ultra-the-next-generation-of-carplay-begins-rolling-out-today/
- Speedometer should look like a dial with a number in teh center in Landscape mode.
- Speedometer should only be a number in Portrait mode.
- Follow Apple's Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/

## Files 
- Functionality should be divided into separate files.
- Example include: model, service, views, icon etc
- Create ISSUES.md file to maintain a list of issues and solutions
- Use a TODO.md file to keep a list of improvements to be made to the app.

## Phases
### Phase 1.
- GPS and permisisons on the device. 
- Retrieve the location using MapKit and show it on the interface

### Phase 2.
- Use the precise location to query OpenStreetMap and get speed limits
- Use GPS location to query the offline data 