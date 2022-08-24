//
//  ScannerView.swift
//  GiftWrap
//
//  Created by Niranjan Ravichandran on 8/24/22.
//

import SwiftUI
import RoomPlan

struct ScannerView: View {

    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            HStack{
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }
                Spacer()
            }
            .padding()
            Spacer()
        }
        RoomView()
    }
}

struct RoomView: UIViewRepresentable {

    func makeUIView(context: UIViewRepresentableContext<RoomView>) -> RoomCaptureView {
        let roomCamptureView = RoomCaptureView(frame: UIScreen.main.bounds)
        roomCamptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        return roomCamptureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: UIViewRepresentableContext<RoomView>) {

    }

}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
