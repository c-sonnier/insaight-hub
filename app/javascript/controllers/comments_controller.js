import { Controller } from "@hotwired/stimulus"

// Handles comment interactions: reply forms, edit forms, and UI toggles
export default class extends Controller {
  connect() {
    // Controller connected
  }

  showReplyForm(event) {
    event.preventDefault()
    event.stopPropagation()

    const commentId = event.currentTarget.dataset.commentId
    const replyForm = document.getElementById(`reply_form_${commentId}`)

    if (replyForm) {
      // Hide any other open reply forms
      document.querySelectorAll('[id^="reply_form_"]').forEach(form => {
        if (form.id !== `reply_form_${commentId}`) {
          form.classList.add('hidden')
          // Also hide the inner turbo-frame if present
          const innerFrame = form.querySelector('turbo-frame')
          if (innerFrame) innerFrame.classList.add('hidden')
        }
      })

      replyForm.classList.remove('hidden')
      // Also show the inner turbo-frame if present
      const innerFrame = replyForm.querySelector('turbo-frame')
      if (innerFrame) innerFrame.classList.remove('hidden')

      // Focus on the textarea after a short delay to ensure visibility
      setTimeout(() => {
        const textarea = replyForm.querySelector('textarea')
        if (textarea) {
          textarea.focus()
        }
      }, 10)
    }
  }

  hideReplyForm(event) {
    const commentId = event.currentTarget.dataset.commentId
    const replyForm = document.getElementById(`reply_form_${commentId}`)

    if (replyForm) {
      replyForm.classList.add('hidden')
      // Also hide the inner turbo-frame
      const innerFrame = replyForm.querySelector('turbo-frame')
      if (innerFrame) innerFrame.classList.add('hidden')
      // Clear the textarea
      const textarea = replyForm.querySelector('textarea')
      if (textarea) textarea.value = ''
    }
  }

  showEditForm(event) {
    event.preventDefault()
    event.stopPropagation()

    const commentId = event.currentTarget.dataset.commentId
    const editForm = document.getElementById(`edit_form_${commentId}`)

    if (editForm) {
      // Hide any other open edit forms
      document.querySelectorAll('[id^="edit_form_"]').forEach(form => {
        if (form.id !== `edit_form_${commentId}`) {
          form.classList.add('hidden')
          const innerFrame = form.querySelector('turbo-frame')
          if (innerFrame) innerFrame.classList.add('hidden')
        }
      })

      editForm.classList.remove('hidden')
      const innerFrame = editForm.querySelector('turbo-frame')
      if (innerFrame) innerFrame.classList.remove('hidden')

      setTimeout(() => {
        const textarea = editForm.querySelector('textarea')
        if (textarea) textarea.focus()
      }, 10)
    }
  }

  hideEditForm(event) {
    const commentId = event.currentTarget.dataset.commentId
    const editForm = document.getElementById(`edit_form_${commentId}`)

    if (editForm) {
      editForm.classList.add('hidden')
      const innerFrame = editForm.querySelector('turbo-frame')
      if (innerFrame) innerFrame.classList.add('hidden')
    }
  }
}

