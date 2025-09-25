import SwiftUI

struct OfflineMapsSectionView: View {
    @ObservedObject var viewModel: OfflineMapsViewModel
    @State private var isPresentingEuSheet = false

    var body: some View {
        Section("Offline Maps") {
            Button(action: { isPresentingEuSheet = true }) {
                HStack {
                    Text("EU")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $isPresentingEuSheet) {
                EuCountriesSheetView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            // ForEach(viewModel.datasetListings, id: \.datasetIdentifier) { dataset in
            //     let status = viewModel.status(for: dataset.datasetIdentifier)?.downloadStatus
            //     HStack(alignment: .center, spacing: 12) {
            //         HStack(spacing: 8) {
            //             Text(dataset.countryName)
            //             if status == .completed {
            //                 Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            //             }
            //         }
            //         Spacer()
            //         HStack(spacing: 10) {
            //             switch status {
            //             case .some(.downloading):
            //                 Button(action: { viewModel.pauseDownload(for: dataset.datasetIdentifier) }) { Image(systemName: "pause.circle.fill").font(.system(size: 22, weight: .semibold)) }
            //                     .accessibilityIdentifier("button.pause." + dataset.datasetIdentifier)
            //                 Button(role: .destructive, action: { viewModel.cancelDownload(for: dataset.datasetIdentifier) }) { Image(systemName: "xmark.circle.fill").font(.system(size: 22, weight: .semibold)) }
            //                     .accessibilityIdentifier("button.cancel." + dataset.datasetIdentifier)
            //             case .some(.paused):
            //                 Button(action: { viewModel.resumeDownload(for: dataset.datasetIdentifier) }) { Image(systemName: "play.circle.fill").font(.system(size: 22, weight: .semibold)) }
            //                     .accessibilityIdentifier("button.resume." + dataset.datasetIdentifier)
            //                 Button(role: .destructive, action: { viewModel.cancelDownload(for: dataset.datasetIdentifier) }) { Image(systemName: "xmark.circle.fill").font(.system(size: 22, weight: .semibold)) }
            //                     .accessibilityIdentifier("button.cancel." + dataset.datasetIdentifier)
            //             case .some(.completed):
            //                 Button(role: .destructive, action: { viewModel.deleteLocalFile(for: dataset.datasetIdentifier) }) { Image(systemName: "trash.circle.fill").font(.system(size: 22, weight: .semibold)) }
            //                     .accessibilityIdentifier("button.delete." + dataset.datasetIdentifier)
            //             default:
            //                 Button(action: { viewModel.startDownload(for: dataset.datasetIdentifier) }) {
            //                     Image(systemName: "arrow.down.circle.fill")
            //                         .font(.system(size: 22, weight: .semibold))
            //                 }
            //                 .accessibilityIdentifier("button.download." + dataset.datasetIdentifier)
            //             }
            //         }
            //         .buttonStyle(.plain)
            //     }
            // }
        }
    }
}

#Preview {
    OfflineMapsSectionView(viewModel: OfflineMapsViewModel(downloadService: DownloadService()))
}

struct EuCountriesSheetView: View {
    @ObservedObject var viewModel: OfflineMapsViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.datasetListings, id: \.datasetIdentifier) { dataset in
                    let item = viewModel.status(for: dataset.datasetIdentifier)
                    HStack(alignment: .center, spacing: 12) {
                        HStack(spacing: 8) {
                            Text(dataset.countryName)
                            if item?.downloadStatus == .completed {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            switch item?.downloadStatus {
                            case .some(.downloading):
                                ProgressToggleButton(isDownloading: true, progressFraction: item?.progressFraction ?? 0) {
                                    viewModel.toggleDownloadPause(for: dataset.datasetIdentifier)
                                }
                            case .some(.paused):
                                ProgressToggleButton(isDownloading: false, progressFraction: item?.progressFraction ?? 0) {
                                    viewModel.toggleDownloadPause(for: dataset.datasetIdentifier)
                                }
                            case .some(.completed):
                                Button(role: .destructive, action: { viewModel.deleteLocalFile(for: dataset.datasetIdentifier) }) { Image(systemName: "trash.circle.fill").font(.system(size: 22, weight: .semibold)) }
                            default:
                                ProgressToggleButton(isDownloading: false, progressFraction: item?.progressFraction ?? 0) {
                                    viewModel.toggleDownloadPause(for: dataset.datasetIdentifier)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("EU Countries")
        }
    }
}

private struct ProgressToggleButton: View {
    let isDownloading: Bool
    let progressFraction: Double
    let action: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 3)
                .frame(width: 32, height: 32)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progressFraction))))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 32, height: 32)
            Button(action: action) {
                Image(systemName: isDownloading ? "pause.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
    }
}


