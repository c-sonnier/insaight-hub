import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.textContent
    try {
      // Try modern Clipboard API first (requires secure context)
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(text)
        this.showSuccess()
      } else {
        // Fallback to execCommand for non-secure contexts (e.g., HTTP in Docker)
        this.fallbackCopyTextToClipboard(text)
      }
    } catch (err) {
      // If Clipboard API fails, try fallback
      try {
        this.fallbackCopyTextToClipboard(text)
      } catch (fallbackErr) {
        console.error("Failed to copy:", fallbackErr)
      }
    }
  }

  fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()

    try {
      const successful = document.execCommand("copy")
      if (successful) {
        this.showSuccess()
      } else {
        throw new Error("execCommand copy failed")
      }
    } finally {
      document.body.removeChild(textArea)
    }
  }

  showSuccess() {
    const originalHTML = this.buttonTarget.innerHTML
    this.buttonTarget.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
    `
    setTimeout(() => {
      this.buttonTarget.innerHTML = originalHTML
    }, 2000)
  }
}
