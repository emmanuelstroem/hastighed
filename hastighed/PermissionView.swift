import SwiftUI
import CoreLocation

struct PermissionView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Main Content
                    VStack(spacing: 40) {
                        // App Icon/Logo with modern design
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(.blue)
                        }
                        
                        // Title and Description
                        VStack(spacing: 20) {
                            Text("Location Access Required")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("This app needs access to your location to provide accurate speed limit information and street details for your current position.")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 40)
                                .lineSpacing(4)
                        }
                        
                        // Permission Button with modern design
                        Button(action: {
                            locationManager.requestLocationPermission()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Allow Location Access")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 40)
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Settings Button (if permission denied)
                        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                            Button(action: {
                                showingSettings = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Open Settings")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.horizontal, 40)
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
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
                
                Text("To use this app, please enable location access in Settings:")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
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
                        Text("Find this app and set to 'While Using'")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
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

// Custom button style for better interaction feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PermissionView(locationManager: LocationManager())
}
