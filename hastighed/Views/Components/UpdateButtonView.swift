import SwiftUI

/// A SwiftUI view component for displaying an update button
public struct UpdateButtonView: View {
    
    // MARK: - Properties
    
    let isUpdateAvailable: Bool
    let isCheckingForUpdates: Bool
    let onUpdateTapped: () -> Void
    
    // MARK: - Initialization
    
    public init(
        isUpdateAvailable: Bool,
        isCheckingForUpdates: Bool = false,
        onUpdateTapped: @escaping () -> Void
    ) {
        self.isUpdateAvailable = isUpdateAvailable
        self.isCheckingForUpdates = isCheckingForUpdates
        self.onUpdateTapped = onUpdateTapped
    }
    
    // MARK: - Body
    
    public var body: some View {
        if isUpdateAvailable {
            Button(action: onUpdateTapped) {
                HStack(spacing: 4) {
                    if isCheckingForUpdates {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    
                    Text("Update")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                )
            }
            .disabled(isCheckingForUpdates)
            .accessibilityLabel("Update available")
            .accessibilityHint("Tap to download the latest version")
        }
    }
}

// MARK: - Preview

struct UpdateButtonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            UpdateButtonView(
                isUpdateAvailable: true,
                isCheckingForUpdates: false
            ) { }
            
            UpdateButtonView(
                isUpdateAvailable: true,
                isCheckingForUpdates: true
            ) { }
            
            UpdateButtonView(
                isUpdateAvailable: false,
                isCheckingForUpdates: false
            ) { }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

