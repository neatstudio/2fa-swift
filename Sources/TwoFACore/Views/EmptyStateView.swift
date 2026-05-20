import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(title == "No accounts yet" ? "Add Account" : "Show All") {
                action()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
