import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "toggleIcon"]
  static values = { collapsed: { type: Boolean, default: false } }

  connect() {
    // Restore state from localStorage
    const saved = localStorage.getItem("report-sidebar-collapsed")
    if (saved === "true") {
      this.collapsedValue = true
      this.updateUI()
    }
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    localStorage.setItem("report-sidebar-collapsed", this.collapsedValue)
    this.updateUI()
  }

  updateUI() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.toggle("hidden", this.collapsedValue)
    }
    if (this.hasToggleIconTarget) {
      // Rotate icon when collapsed
      this.toggleIconTarget.classList.toggle("rotate-180", this.collapsedValue)
    }
  }
}
