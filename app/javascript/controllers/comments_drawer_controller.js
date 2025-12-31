import { Controller } from "@hotwired/stimulus"

// Handles the collapsible comments drawer panel
export default class extends Controller {
  static targets = ["drawer", "toggleButton"]

  connect() {
    // Check localStorage for saved state
    const savedState = localStorage.getItem('commentsDrawerOpen')
    if (savedState === 'true') {
      this.open()
    }
  }

  toggle() {
    const drawer = document.getElementById('comments-drawer')
    if (drawer) {
      if (drawer.classList.contains('hidden')) {
        this.open()
      } else {
        this.close()
      }
    }
  }

  open() {
    const drawer = document.getElementById('comments-drawer')
    if (drawer) {
      drawer.classList.remove('hidden')
      localStorage.setItem('commentsDrawerOpen', 'true')
    }
  }

  close() {
    const drawer = document.getElementById('comments-drawer')
    if (drawer) {
      drawer.classList.add('hidden')
      localStorage.setItem('commentsDrawerOpen', 'false')
    }
  }
}

