//
//  HomeView.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/24/22.
//

import ARKit
import SwiftUI

struct HomeView: View {

    @State var showRoomCaptureView = false
    @State var showPreview = false
    @State var isImageAnimating = false

    var isRoomCaptureSupported: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    var infoText: String {
        isRoomCaptureSupported
        ? "Get started with scanning your space."
        : "Device not supported. Space scanning requires a LiDAR enabled device."
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image(systemName: "viewfinder.circle")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .font(.largeTitle)
                    .scaleEffect(isImageAnimating ? 0.8 : 1.1)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 0.8).repeatForever()) {
                            isImageAnimating = true
                        }
                    }
                Text(infoText)
                    .padding()
                    .multilineTextAlignment(.center)
                Button {
                    withAnimation { showRoomCaptureView.toggle() }
                } label: {
                    Text("Begin Scan")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isRoomCaptureSupported)
                .opacity(isRoomCaptureSupported ? 1 : 0.5)

                Spacer()
                
                Button {
                    withAnimation { showPreview.toggle() }
                } label: {
                    Text("View Scanned Space")
                }
            }
            .padding()
            .fullScreenCover(isPresented: $showRoomCaptureView) {
                Scanner()
            }
            .fullScreenCover(isPresented: $showPreview) {
                PreviewView()
            }
            .toolbarBackground(.hidden, for: .automatic)
        }

    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
