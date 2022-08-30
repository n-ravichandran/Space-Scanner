//
//  CaptureRoomExtensions.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/29/22.
//

import Foundation
import RoomPlan

extension CapturedRoom {

    var isValidScan: Bool {
        !walls.isEmpty && !doors.isEmpty && !objects.isEmpty && !windows.isEmpty && !openings.isEmpty
    }

}

extension CapturedRoom.Object.Category: CaseIterable {

    public static var allCases: [CapturedRoom.Object.Category] {
        [
            .storage,
            .refrigerator,
            .stove,
            .bed,
            .sink,
            .washerDryer,
            .toilet,
            .bathtub,
            .oven,
            .dishwasher,
            .table,
            .sofa,
            .chair,
            .fireplace,
            .television,
            .stairs,
        ]
    }

    public var detail: String {
        "\(self)"
    }

}
