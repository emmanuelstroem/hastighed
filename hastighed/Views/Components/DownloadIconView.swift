import SwiftUI

/// A 4-state download icon component that shows appropriate icons based on download status
struct DownloadIconView: View {
    let downloadStatus: DownloadStatus?
    let progressFraction: Double
    let localFileExists: Bool
    let action: () -> Void
    
    init(
        downloadStatus: DownloadStatus? = nil,
        progressFraction: Double = 0.0,
        localFileExists: Bool = false,
        action: @escaping () -> Void
    ) {
        self.downloadStatus = downloadStatus
        self.progressFraction = progressFraction
        self.localFileExists = localFileExists
        self.action = action
    }
    
    var body: some View {
        switch downloadStatus {
        case .some(.downloading):
            ProgressView(value: progressFraction)
                .progressViewStyle(.circular)
        case .some(.paused):
            ProgressView(value: progressFraction)
                .progressViewStyle(.circular)
        case .some(.completed):
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .some(.failed):
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.red)
        case .some(.queued), .some(.canceled):
            Image(systemName: "icloud.and.arrow.down")
        case .none:
            Image(systemName: localFileExists ? "checkmark.circle.fill" : "icloud.and.arrow.down")
        }
    }
    
    // MARK: - State Logic
    
    private var shouldShowProgressRing: Bool {
        downloadStatus == .downloading || downloadStatus == .paused
    }
    
    
    private var iconName: String {
        switch downloadStatus {
        case .downloading:
            return "pause.circle.fill"
        case .completed:
            // When completed, always show delete icon
            return "trash.circle.fill"
        case .paused, .queued, .failed, .canceled, .none:
            // If no download status but file exists locally, show delete icon
            if localFileExists {
                return "trash.circle.fill"
            }
            return "arrow.down.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch downloadStatus {
        case .downloading:
            return .orange
        case .completed:
            // When completed, always show red delete icon
            return .red
        case .paused, .queued, .failed, .canceled, .none:
            // If no download status but file exists locally, show red delete icon
            if localFileExists {
                return .red
            }
            return .green
        }
    }
    
    private var progressColor: Color {
        .green
    }
    
    private var accessibilityLabel: String {
        switch downloadStatus {
        case .downloading:
            return "Pause download"
        case .paused:
            return "Resume download"
        case .queued:
            return "Start download"
        case .failed:
            return "Retry download"
        case .canceled:
            return "Start download"
        case .completed:
            return "Delete downloaded file"
        case .none:
            // If no download status but file exists locally, show delete action
            if localFileExists {
                return "Delete downloaded file"
            }
            return "Download file"
        }
    }
    
    private var accessibilityHint: String {
        switch downloadStatus {
        case .downloading:
            return "Tap to pause the download"
        case .paused:
            return "Tap to resume the download. Progress ring shows current progress."
        case .queued:
            return "Tap to start the download"
        case .failed:
            return "Tap to retry the download"
        case .canceled:
            return "Tap to start the download"
        case .completed:
            return "Tap to delete the downloaded file"
        case .none:
            // If no download status but file exists locally, show delete action
            if localFileExists {
                return "Tap to delete the downloaded file"
            }
            return "Tap to download the file"
        }
    }
}

// MARK: - Preview

#Preview("Download States") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .none, action: {})
            Text("None")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .queued, action: {})
            Text("Queued")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .downloading, progressFraction: 0.3, action: {})
            Text("Downloading (30%)")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .paused, progressFraction: 0.5, action: {})
            Text("Paused (50% - shows progress)")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .completed, action: {})
            Text("Completed (shows delete)")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .none, localFileExists: true, action: {})
            Text("File exists locally")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .failed, action: {})
            Text("Failed")
        }
        
        HStack(spacing: 20) {
            DownloadIconView(downloadStatus: .canceled, action: {})
            Text("Canceled")
        }
    }
    .padding()
}
