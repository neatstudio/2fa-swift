import AppKit
import SwiftUI
import TwoFACore

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let viewModel: AccountsViewModel

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        viewModel = AccountsViewModel(repository: AccountRepository.live())
        super.init()

        if let button = statusItem.button {
            button.title = "2fa"
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 440, height: 560)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarRootView(viewModel: viewModel)
        )
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            viewModel.load()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
