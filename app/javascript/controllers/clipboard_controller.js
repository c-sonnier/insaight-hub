import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.textContent
    try {
      await navigator.clipboard.writeText(text)
      this.showSuccess()
    } catch (err) {
      console.error("Failed to copy:", err)
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
