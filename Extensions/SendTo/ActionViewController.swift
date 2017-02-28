/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import SnapKit

/// The ActionViewController is the initial viewcontroller that is presented (full screen) when the share extension
/// is activated. Depending on whether the user is logged in or not, this viewcontroller will present either the
/// InstructionsVC or the ClientPicker VC.

@objc(ActionViewController)
class ActionViewController: UIViewController, ClientPickerViewControllerDelegate, InstructionsViewControllerDelegate {
    private lazy var profile: Profile = { return BrowserProfile(localName: "profile", app: nil) }()
    private var sharedItem: ShareItem?

    override func viewDidLoad() {
        view.backgroundColor = UIColor.white

        super.viewDidLoad()
        profile.reopen()

        guard profile.hasAccount() else {
            let instructionsViewController = InstructionsViewController()
            instructionsViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: instructionsViewController)
            present(navigationController, animated: false, completion: nil)
            return
        }

        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
            guard let item = item, error == nil, item.isShareable else {
                let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.finish() })
                self.present(alert, animated: true, completion: nil)
                return
            }

            self.sharedItem = item
            let clientPickerViewController = ClientPickerViewController()
            clientPickerViewController.clientPickerDelegate = self
            clientPickerViewController.profile = self.profile
            let navigationController = UINavigationController(rootViewController: clientPickerViewController)
            self.present(navigationController, animated: false, completion: nil)
        })
    }

    func finish() {
        self.profile.shutdown()
        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }

    func clientPickerViewController(_ clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
        // TODO: hook up Send Tab via Sync.
        // profile?.clients.sendItem(self.sharedItem!, toClients: clients)
        if let item = sharedItem {
            self.profile.sendItems([item], toClients: clients)
        }
        finish()
    }
    
    func clientPickerViewControllerDidCancel(_ clientPickerViewController: ClientPickerViewController) {
        finish()
    }

    func instructionsViewControllerDidClose(_ instructionsViewController: InstructionsViewController) {
        finish()
    }
}
