//
//  UIViewControllerExtensions.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/30/22.
//

import UIKit

public extension UIViewController {

    func showAlert(title: String?, message: String, defaultActionHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default, handler: defaultActionHandler))
        present(alert, animated: true)
    }

    func showActivitySheet(activityItems: [Any]) {
        let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.dismiss(animated: true)
        }
        present(activity, animated: true)
    }
    
}
