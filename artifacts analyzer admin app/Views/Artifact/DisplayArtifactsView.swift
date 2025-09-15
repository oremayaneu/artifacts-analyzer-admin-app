import SwiftUI

struct DisplayArtifactsView: View {
    @Binding var path: [ArtifactPath]
    @ObservedObject var artifactViewModel: ArtifactViewModel
    
    var body: some View {
        Group {
            if (!artifactViewModel.isLoadingArtifacts && artifactViewModel.artifacts.count > 0){
                List(artifactViewModel.artifacts) { artifact in
                    Button(artifact.jpName) {
                        Task {
                            artifactViewModel.selectedArtifact = artifact
                            path.append(.displayArtifactDetailPath)
                        }
                    }.foregroundColor(.primary)
                }
            } else if artifactViewModel.isLoadingArtifacts {
                BlockingIndicator()
            } else {
                Text("No artifact")
            }
        }
        .navigationTitle("聖遺物一覧")
        .onAppear {
            Task {
                await artifactViewModel.fetchAllArtifacts()
            }
        }
    }
}
