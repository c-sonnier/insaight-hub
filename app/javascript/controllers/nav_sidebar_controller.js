import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "toggleIcon", "label", "menuTitle"]
  static values = { collapsed: { type: Boolean, default: false } }

  connect() {
    // Restore state from localStorage
    const saved = localStorage.getItem("nav-sidebar-collapsed")
    if (saved === "true") {
      this.collapsedValue = true
    }
    this.updateUI()
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    localStorage.setItem("nav-sidebar-collapsed", this.collapsedValue)
    this.updateUI()
  }

  updateUI() {
    if (this.hasSidebarTarget) {
      if (this.collapsedValue) {
        this.sidebarTarget.classList.remove("w-64")
        this.sidebarTarget.classList.add("w-16")
      } else {
        this.sidebarTarget.classList.remove("w-16")
        this.sidebarTarget.classList.add("w-64")
      }
    }

    // Hide/show all labels
    this.labelTargets.forEach(label => {
      label.classList.toggle("hidden", this.collapsedValue)
    })

    // Hide/show menu titles (like "Admin")
    this.menuTitleTargets.forEach(title => {
      title.classList.toggle("hidden", this.collapsedValue)
    })

    // Rotate toggle icon
    if (this.hasToggleIconTarget) {
      this.toggleIconTarget.classList.toggle("rotate-180", this.collapsedValue)
    }
  }
}
