import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["iframe"]

  connect() {
    // Controller is available for future enhancements like:
    // - Resizing the iframe
    // - Refreshing content
    // - Toggling fullscreen mode
  }

  refresh() {
    if (this.hasIframeTarget) {
      this.iframeTarget.src = this.iframeTarget.src
    }
  }

  fullscreen() {
    if (this.hasIframeTarget) {
      if (this.iframeTarget.requestFullscreen) {
        this.iframeTarget.requestFullscreen()
      }
    }
  }
}
