import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { current: String }
  static targets = ["item"]

  connect() {
    // Load saved theme or use user preference
    const savedTheme = localStorage.getItem("theme") || this.currentValue || "light"
    this.applyTheme(savedTheme)
    this.updateActiveState(savedTheme)
  }

  change(event) {
    event.preventDefault()
    const theme = event.currentTarget.dataset.setTheme
    if (theme) {
      this.applyTheme(theme)
      this.saveTheme(theme)
      this.updateActiveState(theme)
      // Close dropdown by removing focus
      document.activeElement.blur()
    }
  }

  applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme)
  }

  saveTheme(theme) {
    localStorage.setItem("theme", theme)
  }

  updateActiveState(activeTheme) {
    this.itemTargets.forEach((item) => {
      const theme = item.dataset.setTheme
      const checkmark = item.querySelector("[data-checkmark]")
      if (checkmark) {
        if (theme === activeTheme) {
          checkmark.classList.remove("invisible")
          checkmark.classList.add("visible")
        } else {
          checkmark.classList.remove("visible")
          checkmark.classList.add("invisible")
        }
      }
    })
  }
}
