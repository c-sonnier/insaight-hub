import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
  static targets = ["input", "preview", "modal", "cropImage", "croppedData", "currentAvatar"]

  connect() {
    this.cropper = null
  }

  disconnect() {
    if (this.cropper) {
      this.cropper.destroy()
    }
  }

  selectFile() {
    this.inputTarget.click()
  }

  fileSelected(event) {
    const file = event.target.files[0]
    if (file && file.type.startsWith("image/")) {
      this.showCropModal(file)
    }
  }

  showCropModal(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      this.cropImageTarget.src = e.target.result
      this.modalTarget.showModal()

      // Initialize cropper after image is loaded
      this.cropImageTarget.onload = () => {
        if (this.cropper) {
          this.cropper.destroy()
        }

        this.cropper = new Cropper(this.cropImageTarget, {
          aspectRatio: 1,
          viewMode: 2,
          dragMode: "move",
          autoCropArea: 1,
          restore: false,
          guides: true,
          center: true,
          highlight: false,
          cropBoxMovable: true,
          cropBoxResizable: true,
          toggleDragModeOnDblclick: false,
        })
      }
    }
    reader.readAsDataURL(file)
  }

  cancelCrop() {
    this.modalTarget.close()
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
    this.inputTarget.value = ""
  }

  applyCrop() {
    if (!this.cropper) return

    const canvas = this.cropper.getCroppedCanvas({
      width: 400,
      height: 400,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: "high",
    })

    canvas.toBlob((blob) => {
      // Create a new File object from the blob
      const fileName = this.inputTarget.files[0].name
      const croppedFile = new File([blob], fileName, {
        type: "image/jpeg",
        lastModified: Date.now(),
      })

      // Create a DataTransfer to update the file input
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(croppedFile)
      this.inputTarget.files = dataTransfer.files

      // Update preview
      this.updatePreview(canvas.toDataURL())

      // Close modal
      this.modalTarget.close()
      if (this.cropper) {
        this.cropper.destroy()
        this.cropper = null
      }
    }, "image/jpeg", 0.9)
  }

  updatePreview(dataUrl) {
    if (this.hasPreviewTarget) {
      this.previewTarget.src = dataUrl
      this.previewTarget.classList.remove("hidden")
    }
    if (this.hasCurrentAvatarTarget) {
      this.currentAvatarTarget.src = dataUrl
    }
  }

  removeAvatar(event) {
    event.preventDefault()

    if (confirm("Are you sure you want to remove your avatar?")) {
      // Clear the file input
      this.inputTarget.value = ""

      // Create a hidden input to tell the server to remove the avatar
      const form = this.element.closest("form")
      let removeInput = form.querySelector('input[name="user[remove_avatar]"]')
      if (!removeInput) {
        removeInput = document.createElement("input")
        removeInput.type = "hidden"
        removeInput.name = "user[remove_avatar]"
        form.appendChild(removeInput)
      }
      removeInput.value = "1"

      // Update preview to show default avatar
      const defaultAvatarUrl = this.element.dataset.defaultAvatarUrl || "/assets/default_avatar.svg"
      if (this.hasPreviewTarget) {
        this.previewTarget.src = defaultAvatarUrl
      }
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.src = defaultAvatarUrl
      }
    }
  }
}
