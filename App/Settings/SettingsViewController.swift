//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI
import PromiseKit
import Loaf

class SettingsViewController: UITableViewController {
    var sessionService: SessionService?
    var authenticationUIService: AuthenticationUIService?

    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var darkModeLabel: UILabel!
    @IBOutlet weak var systemSwitch: UISwitch!
    @IBOutlet weak var showThumbnailsSwitch: UISwitch!
    @IBOutlet weak var safariReaderModeSwitch: UISwitch!
    @IBOutlet weak var openInDefaultBrowserSwitch: UISwitch!
    @IBOutlet weak var openInDefaultBrowserLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13, *) {
            systemSwitch.isEnabled = true
        } else {
            systemSwitch.isEnabled = false
        }
        setupTheming()
        systemSwitch.isOn = UserDefaults.standard.systemThemeEnabled
        darkModeSwitch.isEnabled = !systemSwitch.isOn
        darkModeLabel.isEnabled = !systemSwitch.isOn
        darkModeSwitch.isOn = UserDefaults.standard.darkModeEnabled
        safariReaderModeSwitch.isOn = UserDefaults.standard.safariReaderModeEnabled
        showThumbnailsSwitch.isOn = UserDefaults.standard.showThumbnails
        updateOpenInDefaultBrowser()
        updateUsername()
        updateVersion()
        notificationToken = NotificationCenter.default
            .observe(name: Notification.Name.refreshRequired,
                     object: nil, queue: .main) { _ in self.updateUsername() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }

    private func updateUsername() {
        if sessionService?.authenticationState == .authenticated {
            usernameLabel.text = sessionService?.username
        } else {
            usernameLabel.text = "Not logged in"
        }
    }

    private func updateVersion() {
        if let appVersion = appVersion() {
            self.versionLabel.text = "Version \(appVersion)"
        }
    }

    private func updateOpenInDefaultBrowser() {
        openInDefaultBrowserSwitch.isOn = UserDefaults.standard.openInDefaultBrowser
        safariReaderModeSwitch.isEnabled = !UserDefaults.standard.openInDefaultBrowser
        openInDefaultBrowserLabel.isEnabled = !UserDefaults.standard.openInDefaultBrowser
    }

    @IBAction private func systemThemeValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setSystemTheme(sender.isOn)
        ThemeSwitcher.switchTheme()
        darkModeSwitch.isEnabled = !sender.isOn
        darkModeLabel.isEnabled = !sender.isOn
     }

    @IBAction private func darkModeValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setDarkMode(sender.isOn)
        AppThemeProvider.shared.currentTheme = sender.isOn ? .dark : .light
    }

    @IBAction func showThumbnailsValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setShowThumbnails(sender.isOn)
        NotificationCenter.default.post(name: Notification.Name.refreshRequired, object: nil)
    }

    @IBAction func safariReaderModelValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setSafariReaderMode(sender.isOn)
    }

    @IBAction func openInDefaultBrowserValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setOpenInDefaultBrowser(sender.isOn)
        updateOpenInDefaultBrowser()
    }

    @IBAction private func didPressDone(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension SettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 1):
            showWebsite()
        case (0, 2):
            sendFeedbackEmail()
        case (0, 3):
            showWhatsNew()
        case (1, 0):
            login()
        default: break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func showWebsite() {
        let url = URL(string: "https://github.com/weiran/hackers")!
        openURL(url: url) {
            if let safariViewController = SFSafariViewController.instance(for: url) {
                present(safariViewController, animated: true)
            }
        }
    }

    private func showWhatsNew() {
        if let viewController = OnboardingService.onboardingViewController(forceShow: true) {
            present(viewController, animated: true)
        }
    }

    private func sendFeedbackEmail() {
        if MFMailComposeViewController.canSendMail() {
            let appVersion = self.appVersion() ?? ""
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["weiran@zhang.me.uk"])
            mail.setSubject("Feedback for Hackers \(appVersion)")
            mail.setMessageBody("", isHTML: true)
            present(mail, animated: true)
        }
    }

    private func appVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private func login() {
        authenticationUIService?.showAuthentication()
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.groupedTableViewBackgroundColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
