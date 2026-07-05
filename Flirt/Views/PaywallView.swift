import StoreKit
import SwiftUI

struct PaywallView: View {
    @StateObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var purchasingId: String?
    let onUpgraded: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    ForEach(store.products, id: \.id) { product in
                        planCard(product)
                    }
                    if store.products.isEmpty {
                        ProgressView().padding(.top, 40)
                    }
                    if let error = store.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    Button("Restore purchases") {
                        Task { await store.restorePurchases() }
                    }
                    .font(.footnote)
                    disclosure
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await store.loadProducts() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Go beyond the beta")
                .font(.title2.bold())
            Text("Flirt is unlimited during the beta. Subscribing supports development and locks in your plan for launch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func planCard(_ product: Product) -> some View {
        let isOwned = store.purchasedProductIds.contains(product.id)
        let isPurchasing = purchasingId == product.id

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(product.displayName)
                    .font(.headline)
                Spacer()
                Text("\(product.displayPrice)/mo")
                    .font(.headline)
            }
            Text(product.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                purchase(product)
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text(isOwned ? "Current plan ✓" : "Subscribe")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isOwned || isPurchasing)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var disclosure: some View {
        Text("Auto-renews monthly until cancelled in Settings → Apple ID → Subscriptions. Local StoreKit testing — no real charges during development.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private func purchase(_ product: Product) {
        purchasingId = product.id
        Task {
            defer { purchasingId = nil }
            if await store.purchase(product) {
                onUpgraded()
                dismiss()
            }
        }
    }
}
