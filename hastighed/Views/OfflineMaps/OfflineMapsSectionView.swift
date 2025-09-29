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
    @StateObject private var phoneSettingsService: PhoneSettingsService
    
    init(viewModel: OfflineMapsViewModel) {
        self.viewModel = viewModel
        self._phoneSettingsService = StateObject(wrappedValue: PhoneSettingsService(locationService: LocationService()))
    }

    var body: some View {
        NavigationStack {
            List {
                // Current Country Section
                if let currentDataset = phoneSettingsService.getRecommendedDataset() {
                    Section("Current Country") {
                        CountryRowView(
                            dataset: currentDataset,
                            viewModel: viewModel,
                            isCurrentCountry: true,
                            countryName: phoneSettingsService.currentCountryName
                        )
                    }
                }
                
                // Other Countries Section
                Section("Other Countries") {
                    ForEach(phoneSettingsService.getOtherDatasets(), id: \.datasetIdentifier) { dataset in
                        CountryRowView(
                            dataset: dataset,
                            viewModel: viewModel,
                            isCurrentCountry: false,
                            countryName: nil
                        )
                    }
                }
            }
            .navigationTitle("EU Countries")
        }
        .onAppear {
            viewModel.refreshAllStatuses()
            phoneSettingsService.startDetection()
        }
    }
}

/// A row view for displaying a country dataset
struct CountryRowView: View {
    let dataset: DatasetListing
    @ObservedObject var viewModel: OfflineMapsViewModel
    let isCurrentCountry: Bool
    let countryName: String?
    
    private var downloadItem: DownloadItem? {
        viewModel.status(for: dataset.datasetIdentifier)
    }
    
    private var localFileExists: Bool {
        viewModel.localFileExists(for: dataset.datasetIdentifier)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Country flag or icon
            Image(systemName: isCurrentCountry ? "location.circle.fill" : "globe")
                .foregroundColor(isCurrentCountry ? .blue : .secondary)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dataset.countryName)
                        .font(.headline)
                    if isCurrentCountry {
                        Text("(Current)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if let size = dataset.expectedTotalByteCount {
                    Text(humanReadableSize(size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Download status
            DownloadIconView(
                downloadStatus: downloadItem?.downloadStatus,
                progressFraction: downloadItem?.progressFraction ?? 0.0,
                localFileExists: localFileExists
            ) {
                if localFileExists {
                    viewModel.deleteLocalFile(for: dataset.datasetIdentifier)
                } else {
                    viewModel.toggleDownloadPause(for: dataset.datasetIdentifier)
                }
            }
        }
        .padding(.vertical, 4)
    }
}


private func humanReadableSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}