import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filesContainer", "fileTemplate", "fileEntry", "destroyField"]

  connect() {
    this.fileIndex = this.fileEntryTargets.length
  }

  addFile() {
    const template = this.fileTemplateTarget.innerHTML
    const newEntry = template.replace(/NEW_INDEX/g, this.fileIndex++)
    this.filesContainerTarget.insertAdjacentHTML("beforeend", newEntry)
  }

  removeFile(event) {
    const entry = event.target.closest("[data-report-form-target='fileEntry']")
    const destroyField = entry.querySelector("[data-report-form-target='destroyField']")

    if (destroyField && destroyField.name.includes("[id]")) {
      // Existing record - mark for destruction
      destroyField.value = "true"
      entry.style.display = "none"
    } else {
      // New record - just remove from DOM
      entry.remove()
    }
  }
}
