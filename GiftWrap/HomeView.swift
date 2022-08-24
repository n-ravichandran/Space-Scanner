//
//  HomeView.swift
//  GiftWrap
//
//  Created by Niranjan Ravichandran on 8/24/22.
//

import SwiftUI

struct HomeView: View {

    @State var showRoomCaptureView = false

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "viewfinder.circle")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .font(.largeTitle)
            Text("Get started with scanning your space.")
                .padding()
            Spacer()
            Button {
                withAnimation { showRoomCaptureView.toggle() }
            } label: {
                Text("Begin Scan")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .fullScreenCover(isPresented: $showRoomCaptureView) {
            ScannerView()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
