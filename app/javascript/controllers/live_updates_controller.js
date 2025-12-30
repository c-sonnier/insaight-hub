import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["list", "toast"]

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create("InsightItemsChannel", {
      received: (data) => this.handleMessage(data)
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  handleMessage(data) {
    if (data.type === "new_insight") {
      this.showToast(data.insight_item)
      if (this.hasListTarget) {
        this.prependInsight(data.insight_item)
      }
    }
  }

  showToast(insight) {
    const toast = document.createElement("div")
    toast.className = "toast toast-end z-50"
    toast.innerHTML = `
      <div class="alert alert-info">
        <span>New insight published: <a href="/insight_items/${insight.slug}" class="link link-hover font-bold">${this.escapeHtml(insight.title)}</a></span>
        <button class="btn btn-ghost btn-xs" onclick="this.closest('.toast').remove()">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    `
    document.body.appendChild(toast)
    setTimeout(() => toast.remove(), 5000)
  }

  prependInsight(insight) {
    const card = document.createElement("div")
    card.className = "card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow animate-pulse"
    card.innerHTML = `
      <div class="card-body">
        <h2 class="card-title">
          <a href="/insight_items/${insight.slug}" class="link link-hover">${this.escapeHtml(insight.title)}</a>
        </h2>
        <p class="text-base-content/70 line-clamp-2">${this.escapeHtml(insight.description || '')}</p>
        <div class="flex flex-wrap gap-2 mt-2">
          <span class="badge badge-outline">${this.escapeHtml(insight.audience.replace('_', ' '))}</span>
          ${(insight.tags || []).map(tag => `<span class="badge badge-ghost">${this.escapeHtml(tag)}</span>`).join('')}
        </div>
        <div class="card-actions justify-between items-center mt-4">
          <span class="text-sm text-base-content/60">by ${this.escapeHtml(insight.user_name)} &middot; just now</span>
          <a href="/insight_items/${insight.slug}" class="btn btn-primary btn-sm">View</a>
        </div>
      </div>
    `

    this.listTarget.prepend(card)

    // Remove animation after it plays
    setTimeout(() => card.classList.remove("animate-pulse"), 2000)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
