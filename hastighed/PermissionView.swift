import SwiftUI
import CoreLocation

struct PermissionView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Title
            Text("Location Access Required")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text("This app needs access to your location to provide accurate speed limit information and street details.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            // Permission Button
            Button(action: {
                locationManager.requestLocationPermission()
            }) {
                Text("Allow Location Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Settings Button (if permission denied)
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Button(action: {
                    showingSettings = true
                }) {
                    Text("Open Settings")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Location Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("To use this app, please enable location access in your device settings:")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Open Settings app")
                    }
                    
                    HStack {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Tap Privacy & Security")
                    }
                    
                    HStack {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        Text("Tap Location Services")
                    }
                    
                    HStack {
                        Image(systemName: "4.circle.fill")
                            .foregroundColor(.blue)
                        Text("Find 'Hastighed' and set to 'While Using'")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PermissionView(locationManager: LocationManager())
}