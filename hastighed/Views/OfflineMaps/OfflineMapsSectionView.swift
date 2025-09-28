import SwiftUI

struct OfflineMapsSectionView: View {
    @ObservedObject var viewModel: OfflineMapsViewModel
    @State private var isPresentingEuSheet = false

    var body: some View {
        Section("Offline Maps") {
            Button(action: { isPresentingEuSheet = true }) {
                HStack {
                    Text("EU Offline Maps")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $isPresentingEuSheet) {
                EuCountriesSheetView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

#Preview {
    OfflineMapsSectionView(viewModel: OfflineMapsViewModel())
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
                if let size = dataset.expectedTotalByteCount {
                    Text(humanReadableSize(size)).font(.footnote).foregroundStyle(.secondary)
                }
                if item?.downloadStatus == .completed {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            Spacer()
            DownloadIconView(
                downloadStatus: item?.downloadStatus,
                progressFraction: item?.progressFraction ?? 0.0,
                localFileExists: viewModel.localFileExists(for: dataset.datasetIdentifier)
            ) {
                if item?.downloadStatus == .completed || viewModel.localFileExists(for: dataset.datasetIdentifier) {
                    viewModel.deleteLocalFile(for: dataset.datasetIdentifier)
                } else {
                    viewModel.toggleDownloadPause(for: dataset.datasetIdentifier)
                }
            }
        }
                }
            }
            .navigationTitle("EU Countries")
        }
        .onAppear {
            print("🔍 EuCountriesSheetView onAppear - this should definitely show up!")
            viewModel.refreshAllStatuses()
        }
    }
}


private func humanReadableSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}