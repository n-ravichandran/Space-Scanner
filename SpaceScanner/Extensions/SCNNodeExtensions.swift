//
//  SCNNodeExtensions.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/29/22.
//

import Foundation
import RoomPlan
import SceneKit

extension SCNNode {

    private static var nameIdentifier = "Space"

    func markAsSpaceNode() {
        name = "\(Self.nameIdentifier)_\(UUID().uuidString)"
    }

    var isSpaceNode: Bool {
        name?.starts(with: Self.nameIdentifier) ?? false
    }

    var type: NodeType? {
        NodeType(name: name)
    }

    enum NodeType: String, CaseIterable {
        case wall
        case door
        case opening
        case window
        case furniture
        case floor

        init?(name: String?) {
            guard let name = name?.lowercased() else { return nil }
            if let type = NodeType.allCases.first(where: { name.starts(with: $0.rawValue) }) {
                self = type
                return
            }

            let furnitureTypes = CapturedRoom.Object.Category.allCases.map(\.detail)
            if furnitureTypes.contains(where: { name.starts(with: $0) }) {
                self = .furniture
                return
            }
            return nil
        }
    }

}

