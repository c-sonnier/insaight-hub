import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rawView", "previewView", "toggleBtn", "toggleLabel", "codeIcon", "eyeIcon"]

  connect() {
    this.isPreview = false
  }

  toggleMarkdown() {
    this.isPreview = !this.isPreview

    if (this.isPreview) {
      // Show preview, hide raw
      this.rawViewTarget.classList.add("hidden")
      this.previewViewTarget.classList.remove("hidden")
      this.toggleLabelTarget.textContent = "Raw"
      this.eyeIconTarget.classList.add("hidden")
      this.codeIconTarget.classList.remove("hidden")
    } else {
      // Show raw, hide preview
      this.rawViewTarget.classList.remove("hidden")
      this.previewViewTarget.classList.add("hidden")
      this.toggleLabelTarget.textContent = "Preview"
      this.eyeIconTarget.classList.remove("hidden")
      this.codeIconTarget.classList.add("hidden")
    }
  }
}
