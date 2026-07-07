import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Preloads the next page of results when the sentinel element nears the
// viewport. The turbo_stream response appends cards and replaces this
// sentinel with the following page's sentinel (or an empty one at the end).
export default class extends Controller {
  static values = { url: String, margin: { type: String, default: "800px" } }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.load(entries),
      { rootMargin: this.marginValue }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer.disconnect()
  }

  async load(entries) {
    if (this.loading || !entries.some((entry) => entry.isIntersecting)) return

    this.loading = true
    this.observer.disconnect()

    const response = await fetch(this.urlValue, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    if (response.ok) {
      Turbo.renderStreamMessage(await response.text())
    } else {
      this.loading = false
      this.observer.observe(this.element)
    }
  }
}
