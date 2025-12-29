import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  toggle() {
    if (!document.fullscreenElement) {
      this.containerTarget.requestFullscreen?.() ||
      this.containerTarget.webkitRequestFullscreen?.() ||
      this.containerTarget.msRequestFullscreen?.()
    } else {
      document.exitFullscreen?.() ||
      document.webkitExitFullscreen?.() ||
      document.msExitFullscreen?.()
    }
  }

  close() {
    if (document.fullscreenElement) {
      document.exitFullscreen?.() ||
      document.webkitExitFullscreen?.() ||
      document.msExitFullscreen?.()
    }
  }
}
